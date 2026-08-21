/// Just Dance — WhatsApp-style seamless backup.
///
/// One-time Google sign-in; 15s-debounced upload after every change + a daily
/// 4AM WorkManager task. A single latest file lives in the hidden Drive
/// appDataFolder; replace is SAFE (temp upload -> verify -> swap). Offline =>
/// pending flag + auto-retry; expired token => one-tap reconnect; full quota
/// => red banner + Retry; a killed mid-backup leaves temp files that the next
/// run cleans up. Restore shows meta + takes a safety snapshot with Undo.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import '../core/constants.dart';
import '../data/repos.dart';
import '../data/store.dart';
import 'photo_service.dart';

const _scope = 'https://www.googleapis.com/auth/drive.appdata';
const _api = 'https://www.googleapis.com/drive/v3/files';
const _upload = 'https://www.googleapis.com/upload/drive/v3/files';
const _taskName = 'sc_daily_backup';

/// Tables a full backup must contain (used to detect old/incomplete backups).
const _tables = [
  'students', 'courses', 'courseInterests', 'plans',
  'studentCourses', 'attendance', 'ledger', 'settings',
];

const _httpTimeout = Duration(seconds: 30);
const _signInTimeout = Duration(seconds: 20);
const _tokenTimeout = Duration(seconds: 25);

/// Maps Google sign-in failures to actionable messages (unit-testable).
String friendlyBackupError(String raw) {
  final r = raw.toLowerCase();
  if (r.contains('code: 10') || r.contains('developerserror')) {
    return 'OAuth client not configured — register the app SHA-1 in the '
        'Firebase console and re-download google-services.json';
  }
  if (r.contains('code: 12501') || r.contains('cancelled')) {
    return 'Sign-in was cancelled';
  }
  if (r.contains('403') || r.contains('access')) {
    return 'Access denied — enable the Google Drive API for this project '
        'in the Cloud Console';
  }
  if (r.contains('network') || r.contains('timeout')) {
    return 'Network error — check your internet and try again';
  }
  return raw;
}

/// WorkManager entry point (background isolate).
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      // workmanager registers all plugins on its background engine.
      await BackupService.instance.backupNow();
    } catch (_) {}
    return true;
  });
}

class BackupResult {
  final bool ok;
  final String? error; // 'nointernet' | 'reconnect' | 'quota' | 'cancelled' | 'error'
  const BackupResult(this.ok, [this.error]);
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  AppStore? _store;
  final _google = GoogleSignIn(scopes: const [_scope]);
  Timer? _debounce;
  bool _running = false;

  /// Foreground wiring: the store pings this after every mutation.
  void attach(AppStore store) {
    _store = store;
    store.onDataChanged = scheduleDebounced;
  }

  void scheduleDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 15), () => backupNow());
  }

  // ---------------- account ----------------

  /// Returns the signed-in account, or null when sign-in failed.
  /// [errorDetail] (when set) carries the Google error code so the UI can
  /// give plain-language guidance (missing OAuth client, SHA-1, Drive API…).
  Future<GoogleSignInAccount?> signInInteractive() async {
    try {
      final acc = await _google.signIn();
      if (acc != null) await _saveMeta(email: acc.email, status: 'ok');
      return acc;
    } catch (e) {
      final code = (e is Exception) ? e.toString() : '$e';
      await _saveMeta(status: 'signin_error', error: friendlyBackupError(code));
      return null;
    }
  }

  Future<GoogleSignInAccount?> _account({bool refresh = false}) async {
    if (!refresh && _google.currentUser != null) return _google.currentUser;
    try {
      final acc = await _google.signInSilently(suppressErrors: true).timeout(_signInTimeout);
      return acc ?? _google.currentUser;
    } on TimeoutException {
      return _google.currentUser;
    } catch (_) {
      return _google.currentUser;
    }
  }

  Future<String?> _token({bool refresh = false}) async {
    try {
      final acc = await _account(refresh: refresh);
      if (acc == null) return null;
      if (refresh) {
        await acc.clearAuthCache();
      }
      final auth = await acc.authentication.timeout(_tokenTimeout);
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _saveMeta(email: null, status: 'signedout');
  }

  String? get email => _google.currentUser?.email;

  // ---------------- daily 4AM schedule ----------------

  Future<void> initWorkManager() async {
    try {
      await Workmanager().initialize(backupCallbackDispatcher);
    } catch (_) {}
  }

  Future<void> scheduleDaily({required bool enabled, required bool wifiOnly}) async {
    try {
      if (!enabled) {
        await Workmanager().cancelByUniqueName(_taskName);
        return;
      }
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day, 4);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(hours: 24),
        initialDelay: next.difference(now),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType:
              wifiOnly ? NetworkType.unmetered : NetworkType.connected,
        ),
      );
    } catch (_) {}
  }

  // ---------------- connectivity ----------------

  /// Heuristic Wi-Fi check without extra packages.
  Future<bool> _onWifi() async {
    try {
      final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final i in ifs) {
        final n = i.name.toLowerCase();
        if ((n.contains('wlan') || n.contains('wifi')) &&
            i.addresses.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return true; // unknown — do not block
    }
  }

  // ---------------- backup ----------------

  Future<BackupResult> backupNow() async {
    if (_running) return const BackupResult(true);
    _running = true;
    try {
      final store = _store;
      final wifiOnly = store?.wifiOnlyBackup ??
          (await Repos.instance.getSetting(kPrefWifiOnly)) == '1';
      if (wifiOnly && !await _onWifi()) {
        await _pending('wifi');
        return const BackupResult(false, 'wifi');
      }

      var token = await _token();
      token ??= await _token(refresh: true);
      if (token == null) {
        final currentMeta = store?.backupMeta ??
            jsonDecode((await Repos.instance.getSetting(kPrefBackupMeta)) ?? '{}')
                as Map<String, Object?>;
        if (currentMeta['email'] != null) {
          // User was signed in; this is a transient network/refresh issue, not sign out
          await _pending('nointernet');
          return const BackupResult(false, 'nointernet');
        }
        await _pending('reconnect');
        return const BackupResult(false, 'reconnect');
      }
      var headers = {'Authorization': 'Bearer $token'};

      // Build payload
      final Map<String, Object?> payload;
      if (store != null) {
        payload = await store.exportBackup();
      } else {
        payload = await _buildPayloadFromDb();
      }
      final body = utf8.encode(jsonEncode(payload));

      // Clean temp leftovers from any killed mid-backup run with 401 retry
      try {
        await _cleanupTemps(headers);
      } on StateError catch (e) {
        if (e.message == 'reconnect') {
          // Token expired, refresh and retry
          final freshToken = await _token(refresh: true);
          if (freshToken != null) {
            token = freshToken;
            headers = {'Authorization': 'Bearer $token'};
            await _cleanupTemps(headers);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // SAFE REPLACE: upload temp -> verify -> delete old -> rename temp.
      final tmpName = 'studio_crow_backup.tmp';
      var tmpId = await _createFile(headers, tmpName, body);
      if (tmpId == null) {
        // Retry once with refreshed token
        final freshToken = await _token(refresh: true);
        if (freshToken != null) {
          headers = {'Authorization': 'Bearer $freshToken'};
          tmpId = await _createFile(headers, tmpName, body);
        }
        if (tmpId == null) return const BackupResult(false, 'error');
      }

      final meta = await _fileMeta(headers, tmpId);
      if (meta == null || meta.size != body.length) {
        await _delete(headers, tmpId);
        return const BackupResult(false, 'error');
      }

      final old = await _findByName(headers, kBackupFileName);
      if (old != null) await _delete(headers, old);

      final renamed = await _rename(headers, tmpId, kBackupFileName);
      if (!renamed) return const BackupResult(false, 'error');

      await _saveMeta(
        email: _google.currentUser?.email ?? (await _account())?.email,
        status: 'ok',
        lastBackup: DateTime.now().toIso8601String(),
        counts: payload['counts'] as Map<String, Object?>?,
      );
      await _setPendingFlag(false);
      return const BackupResult(true);
    } on SocketException {
      await _pending('nointernet');
      return const BackupResult(false, 'nointernet');
    } on http.ClientException {
      await _pending('nointernet');
      return const BackupResult(false, 'nointernet');
    } on QuotaException {
      await _pending('quota');
      return const BackupResult(false, 'quota');
    } on StateError catch (e) {
      final reason = e.message == 'reconnect' ? 'reconnect' : 'error';
      await _pending(reason);
      return BackupResult(false, reason);
    } catch (_) {
      await _pending('error');
      return const BackupResult(false, 'error');
    } finally {
      _running = false;
    }
  }

  Future<void> _pending(String reason) async {
    await _setPendingFlag(true);
    await _saveMeta(status: 'pending', error: reason);
  }

  /// Builds a v2 payload straight from the database (background isolate,
  /// where no AppStore is attached) — photos embedded as base64 JPEG.
  Future<Map<String, Object?>> _buildPayloadFromDb() async {
    final dump = await Repos.instance.dumpAll();
    final photos = <String, String>{};
    for (final row in dump['students'] ?? const <Map<String, Object?>>[]) {
      final path = row['photoPath'] as String? ?? '';
      if (path.isEmpty) continue;
      final b64 = await PhotoService.instance.readAsJpegBase64(path);
      if (b64 != null) photos['${row['id']}'] = b64;
    }
    final studioJson = await Repos.instance.getSetting(kPrefStudio);
    if (studioJson != null) {
      final info = jsonDecode(studioJson) as Map<String, Object?>;
      final path = info['photoPath'] as String? ?? '';
      if (path.isNotEmpty) {
        final b64 = await PhotoService.instance.readAsJpegBase64(path);
        if (b64 != null) photos['studio'] = b64;
      }
    }
    return {
      'app': kAppName,
      'version': 2,
      'createdAt': DateTime.now().toIso8601String(),
      'counts': {
        for (final e in dump.entries) e.key: e.value.length,
        'photos': photos.length,
      },
      'data': dump,
      'photos': photos,
    };
  }

  Future<void> _setPendingFlag(bool v) async {
    final store = _store;
    if (store != null) {
      await store.setBackupPending(v);
    } else {
      await Repos.instance.setSetting(kPrefBackupPending, v ? '1' : '0');
    }
  }

  Future<void> _saveMeta({
    String? email,
    String? status,
    String? lastBackup,
    String? error,
    Map<String, Object?>? counts,
  }) async {
    final store = _store;
    final current = store?.backupMeta ??
        jsonDecode(
                (await Repos.instance.getSetting(kPrefBackupMeta)) ?? '{}')
            as Map<String, Object?>;
    final next = {...current};
    if (email != null) next['email'] = email;
    if (status != null) next['status'] = status;
    if (lastBackup != null) next['lastBackup'] = lastBackup;
    if (counts != null) next['counts'] = counts;
    if (error != null) {
      next['error'] = error;
    } else if (status == 'ok') {
      next.remove('error');
    }
    if (store != null) {
      await store.saveBackupMeta(next);
    } else {
      await Repos.instance.setSetting(kPrefBackupMeta, jsonEncode(next));
    }
  }

  // ---------------- Drive REST ----------------

  /// Every Drive call gets a hard timeout so the UI can never hang forever.
  Future<http.Response> _timed(Future<http.Response> f) =>
      f.timeout(_httpTimeout);

  Future<void> _cleanupTemps(Map<String, String> headers) async {
    try {
      final r = await _timed(http.get(
        Uri.parse(
            "$_api?spaces=appDataFolder&q=name%20contains%20'.tmp'&fields=files(id)"),
        headers: headers,
      ));
      _throwForStatus(r);
      final files = jsonDecode(r.body)['files'] as List? ?? [];
      for (final f in files) {
        await _delete(headers, f['id'] as String);
      }
    } catch (_) {}
  }

  Future<String?> _findByName(Map<String, String> headers, String name) async {
    final r = await _timed(http.get(
      Uri.parse(
          "$_api?spaces=appDataFolder&q=name='$name'&fields=files(id,name,modifiedTime,size)"),
      headers: headers,
    ));
    _throwForStatus(r);
    final files = jsonDecode(r.body)['files'] as List? ?? [];
    if (files.isEmpty) return null;
    return files.first['id'] as String;
  }

  Future<({String id, int size})?> _fileMeta(
      Map<String, String> headers, String id) async {
    final r = await _timed(
        http.get(Uri.parse('$_api/$id?fields=id,size'), headers: headers));
    _throwForStatus(r);
    final m = jsonDecode(r.body) as Map<String, Object?>;
    final size = int.tryParse('${m['size'] ?? ''}') ?? -1;
    return (id: m['id'] as String, size: size);
  }

  Future<String?> _createFile(
      Map<String, String> headers, String name, List<int> body) async {
    const boundary = 'sc_boundary_42';
    final metaJson = jsonEncode({
      'name': name,
      'parents': ['appDataFolder']
    });
    final payload = <int>[
      ...utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metaJson\r\n'),
      ...utf8.encode('--$boundary\r\nContent-Type: application/json\r\n\r\n'),
      ...body,
      ...utf8.encode('\r\n--$boundary--'),
    ];
    final r = await _timed(http.post(
      Uri.parse('$_upload?uploadType=multipart&fields=id'),
      headers: {
        ...headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: payload,
    ));
    _throwForStatus(r);
    return jsonDecode(r.body)['id'] as String?;
  }

  Future<bool> _rename(
      Map<String, String> headers, String id, String name) async {
    final r = await _timed(http.patch(
      Uri.parse('$_api/$id'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    ));
    _throwForStatus(r);
    return r.statusCode == 200;
  }

  Future<void> _delete(Map<String, String> headers, String id) async {
    final r = await _timed(
        http.delete(Uri.parse('$_api/$id'), headers: headers));
    if (r.statusCode != 204 && r.statusCode != 200 && r.statusCode != 404) {
      _throwForStatus(r);
    }
  }

  void _throwForStatus(http.Response r) {
    if (r.statusCode == 401) throw StateError('reconnect');
    if (r.statusCode == 403 && r.body.contains('storageQuotaExceeded')) {
      throw QuotaException();
    }
    if (r.statusCode == 507) throw QuotaException();
    if (r.statusCode >= 400) {
      if (r.body.contains('storageQuotaExceeded')) throw QuotaException();
      throw StateError('drive_${r.statusCode}');
    }
  }

  // ---------------- restore ----------------

  /// Returns the backup payload (meta + data) or null when none exists.
  Future<Map<String, Object?>?> fetchBackup() async {
    var token = await _token();
    token ??= await _token(refresh: true);
    if (token == null) return null;
    var headers = {'Authorization': 'Bearer $token'};
    try {
      var id = await _findByName(headers, kBackupFileName);
      if (id == null) {
        // Retry with refreshed token in case of expired token
        final fresh = await _token(refresh: true);
        if (fresh != null) {
          headers = {'Authorization': 'Bearer $fresh'};
          id = await _findByName(headers, kBackupFileName);
        }
      }
      if (id == null) return null;
      final r = await _timed(
          http.get(Uri.parse('$_api/$id?alt=media'), headers: headers));
      _throwForStatus(r);
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
    } on StateError {
      return null;
    }
  }

  /// Tables missing from [payload]'s data (older backups), if any.
  List<String> missingTables(Map<String, Object?> payload) {
    final data = payload['data'];
    if (data is! Map) return List.of(_tables);
    return [
      for (final t in _tables)
        if (data[t] is! List) t
    ];
  }

  /// Applies [payload]; the pre-restore snapshot is kept for Undo.
  /// [mergeMissing] keeps the current rows for tables the (older) backup
  /// does not contain instead of wiping them. Restored photos are written
  /// back to the photos dir and their paths remapped.
  Future<void> applyRestore(
      AppStore store, Map<String, Object?> payload,
      {bool mergeMissing = false}) async {
    final data = (payload['data'] as Map).map((k, v) =>
        MapEntry('$k', (v as List).cast<Map<String, Object?>>()));
    if (mergeMissing) {
      final local = await Repos.instance.dumpAll();
      for (final t in _tables) {
        if (!data.containsKey(t)) data[t] = local[t] ?? const [];
      }
    }
    final photosRaw = payload['photos'];
    final photos = <String, String>{};
    if (photosRaw is Map) {
      for (final e in photosRaw.entries) {
        photos['${e.key}'] = '${e.value}';
      }
    }
    // Keep this device's own Google account state across the wipe.
    final meta = await Repos.instance.getSetting(kPrefBackupMeta);
    final pending = await Repos.instance.getSetting(kPrefBackupPending);
    final snapshot = await store.restoreFromBackup(data, photos: photos);
    if (meta != null) {
      await Repos.instance.setSetting(kPrefBackupMeta, meta);
    }
    if (pending != null) {
      await Repos.instance.setSetting(kPrefBackupPending, pending);
    }
    await store.load(); // re-read the preserved meta into memory
    await Repos.instance
        .setSetting(kPrefRestoreSnapshot, jsonEncode(snapshot));
  }

  Future<void> undoRestore(AppStore store) async {
    final raw = await Repos.instance.getSetting(kPrefRestoreSnapshot);
    if (raw == null) return;
    final snap = (jsonDecode(raw) as Map)
        .map((k, v) => MapEntry('$k', (v as List).cast<Map<String, Object?>>()));
    await store.restoreSnapshot(snap);
    await Repos.instance.setSetting(kPrefRestoreSnapshot, '');
  }
}

class QuotaException implements Exception {}
