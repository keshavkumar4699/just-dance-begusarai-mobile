import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../database/db_helper.dart';
import '../models/models.dart';
import '../services/photo_service.dart';
import 'settings_service.dart';

/// Result of a backup / restore attempt.
class BackupResult {
  final bool ok;
  final String message;
  BackupResult(this.ok, this.message);
}

/// Result of a restore import.
class RestoreResult {
  final bool ok;
  final String message;
  final Map<String, Object?>? meta;
  RestoreResult(this.ok, this.message, [this.meta]);
}

/// Google Drive backup - appDataFolder (private to this app), single latest file.
///
/// SAFE REPLACE: uploads to a temp file, verifies, then deletes the old file
/// and renames the temp to the final name. Never blocks the UI.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _base = 'https://www.googleapis.com';
  static const _uploadBase = 'https://www.googleapis.com/upload/drive/v3';

  GoogleSignIn? _signIn;
  String? _lastToken;

  GoogleSignIn _getSignIn() => _signIn ??= GoogleSignIn(
        scopes: [AppInfo.driveScope],
        clientId: AppInfo.googleWebClientId.isEmpty ? null : AppInfo.googleWebClientId,
      );

  /// One-time Google sign-in. Returns the account or throws on failure.
  Future<GoogleSignInAccount> signIn() async {
    final g = _getSignIn();
    final account = await g.signIn();
    if (account == null) throw Exception('Sign in cancelled');
    await _saveAccount(account);
    return account;
  }

  Future<GoogleSignInAccount?> silentSignIn() async {
    final g = _getSignIn();
    return g.signInSilently();
  }

  Future<void> signOut() async {
    await _getSignIn().signOut();
    await SettingsService.instance.saveBackupMeta(BackupMeta());
  }

  /// Wi-Fi check that works from the workmanager isolate too.
  Future<bool> isWifiNative() => PhotoService.isOnWifi();

  /// Resolves a usable access token (tries direct token, then code exchange).
  Future<String> _token(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    var token = auth.accessToken;
    if (token == null || token.isEmpty) throw Exception('No access token');
    // On Android with a serverClientId the value may be an auth code; try it
    // directly first, and if the Drive API rejects it, exchange it.
    final ok = await _drivePing(token);
    if (ok) return token;
    if (AppInfo.googleWebClientId.isNotEmpty) {
      final exchanged = await _exchangeCode(token);
      if (exchanged != null) return exchanged;
    }
    return token; // caller will surface the API error
  }

  Future<bool> _drivePing(String token) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/drive/v3/about?fields=user'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _exchangeCode(String code) async {
    try {
      final r = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': AppInfo.googleWebClientId,
          'client_secret': AppInfo.googleWebClientSecret,
          'redirect_uri': '',
          'grant_type': 'authorization_code',
        },
      );
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, Object?>;
        return j['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveAccount(GoogleSignInAccount a) async {
    final meta = await SettingsService.instance.backupMeta();
    meta.accountEmail = a.email;
    meta.pending = false;
    await SettingsService.instance.saveBackupMeta(meta);
  }

  Future<String> _ensureToken() async {
    var account = await silentSignIn();
    account ??= await signIn();
    _lastToken = await _token(account);
    return _lastToken!;
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<Map<String, Object?>> _listFiles(String token) async {
    final uri = Uri.parse('$_base/drive/v3/files')
        .replace(queryParameters: {
      'spaces': AppInfo.driveAppFolder,
      'fields': 'files(id,name,size,createdTime)',
      'q': "'${AppInfo.driveAppFolder}' in parents",
      'pageSize': '100',
    });
    final r = await http.get(uri, headers: _headers(token));
    if (r.statusCode == 401) throw TokenExpiredException();
    if (r.statusCode != 200) throw HttpException('list failed ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, Object?>;
    return j;
  }

  Future<Map<String, Object?>> _createFile(String token, String name) async {
    final r = await http.post(
      Uri.parse('$_base/drive/v3/files'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'parents': [AppInfo.driveAppFolder]}),
    );
    if (r.statusCode == 401) throw TokenExpiredException();
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw HttpException('create failed ${r.statusCode}: ${r.body}');
    }
    return (jsonDecode(r.body) as Map).cast<String, Object?>();
  }

  Future<void> _uploadContent(String token, String fileId, List<int> bytes) async {
    final r = await http.put(
      Uri.parse('$_uploadBase/files/$fileId?uploadType=media'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: bytes,
    );
    if (r.statusCode == 401) throw TokenExpiredException();
    if (r.statusCode == 403 && r.body.contains('quota')) throw QuotaException();
    if (r.statusCode != 200) {
      if (r.body.contains('storageQuotaExceeded') || r.body.contains('quota')) throw QuotaException();
      throw HttpException('upload failed ${r.statusCode}: ${r.body}');
    }
  }

  Future<Map<String, Object?>> _renameFile(String token, String fileId, String newName) async {
    final r = await http.patch(
      Uri.parse('$_base/drive/v3/files/$fileId'),
      headers: _headers(token),
      body: jsonEncode({'name': newName}),
    );
    if (r.statusCode == 401) throw TokenExpiredException();
    if (r.statusCode != 200) throw HttpException('rename failed ${r.statusCode}');
    return (jsonDecode(r.body) as Map).cast<String, Object?>();
  }

  Future<void> _deleteFile(String token, String fileId) async {
    await http.delete(Uri.parse('$_base/drive/v3/files/$fileId'), headers: _headers(token));
  }

  Future<Map<String, Object?>> _getFile(String token, String fileId) async {
    final r = await http.get(
      Uri.parse('$_base/drive/v3/files/$fileId?alt=media'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode == 401) throw TokenExpiredException();
    if (r.statusCode != 200) throw HttpException('download failed ${r.statusCode}');
    return (jsonDecode(utf8.decode(r.bodyBytes)) as Map).cast<String, Object?>();
  }

  /// Exports the whole database as JSON.
  Future<Map<String, Object?>> exportDb() async {
    final d = await DbHelper.instance.db;
    final tables = [
      'students', 'courses', 'batches', 'timings', 'plans',
      'studentCourses', 'attendance', 'ledger', 'settings',
    ];
    final out = <String, Object?>{};
    for (final t in tables) {
      final rows = await d.query(t);
      out[t] = rows;
    }
    return out;
  }

  /// Performs a backup now. Respects Wi-Fi-only setting.
  Future<BackupResult> backupNow({bool force = false}) async {
    try {
      final wifiOnly = await SettingsService.instance.getBool(SettingsKeys.wifiOnlyBackup, false);
      if (!force && wifiOnly && !await PhotoService.isOnWifi()) {
        return BackupResult(false, 'Wi-Fi only backup - not on Wi-Fi');
      }

      final token = await _ensureToken();
      final data = await exportDb();
      final payload = utf8.encode(jsonEncode({
        'app': AppInfo.name,
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': data,
      }));

      final files = (await _listFiles(token))['files'] as List? ?? [];
      String? finalId;
      String? tempId;
      for (final f in files) {
        final m = f as Map<String, Object?>;
        if (m['name'] == AppInfo.backupFileName) finalId = m['id'] as String?;
        if (m['name'] == '${AppInfo.backupFileName}.temp') tempId = m['id'] as String?;
      }
      // Clean orphaned temp file from a killed backup.
      if (tempId != null) {
        try {
          await _deleteFile(token, tempId);
        } catch (_) {}
      }

      // SAFE REPLACE: upload temp -> verify -> delete old -> rename temp.
      final created = await _createFile(token, '${AppInfo.backupFileName}.temp');
      tempId = created['id'] as String;
      await _uploadContent(token, tempId, payload);
      // Verify: re-download and make sure it parses + matches content.
      final check = await _getFile(token, tempId);
      final expected = jsonDecode(utf8.decode(payload));
      if (jsonEncode(check) != jsonEncode(expected)) {
        throw HttpException('verify failed - file corrupted');
      }
      if (finalId != null) await _deleteFile(token, finalId);
      await _renameFile(token, tempId, AppInfo.backupFileName);

      final m = await SettingsService.instance.backupMeta();
      m.lastBackupAt = DateTime.now().toIso8601String();
      m.lastBackupSize = '${payload.length} bytes';
      m.pending = false;
      await SettingsService.instance.saveBackupMeta(m);
      return BackupResult(true, 'Backup complete');
    } on TokenExpiredException {
      return BackupResult(false, 'Google sign-in expired - reconnect from Profile');
    } on QuotaException {
      return BackupResult(false, 'Google Drive storage full');
    } catch (e) {
      final m = await SettingsService.instance.backupMeta();
      m.pending = true;
      await SettingsService.instance.saveBackupMeta(m);
      return BackupResult(false, 'Backup pending - no internet');
    }
  }

  /// Fetches the backup file meta + content for Restore preview.
  Future<RestoreResult> fetchBackupForRestore() async {
    try {
      final token = await _ensureToken();
      final files = (await _listFiles(token))['files'] as List? ?? [];
      String? id;
      for (final f in files) {
        final m = f as Map<String, Object?>;
        if (m['name'] == AppInfo.backupFileName) id = m['id'] as String?;
      }
      if (id == null) return RestoreResult(false, 'No backup found on Google Drive');
      final j = await _getFile(token, id);
      return RestoreResult(true, 'Backup found', j);
    } on TokenExpiredException {
      return RestoreResult(false, 'Google sign-in expired - reconnect from Profile');
    } catch (_) {
      return RestoreResult(false, 'No internet');
    }
  }
}

class TokenExpiredException implements Exception {}

class QuotaException implements Exception {}
