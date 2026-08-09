import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../database/repositories/student_repository.dart';
import '../database/repositories/ledger_repository.dart';
import '../database/repositories/settings_repository.dart';

class BackupService {
  static const String driveScope = 'https://www.googleapis.com/auth/drive.appdata';
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [driveScope]);

  // Google Account Status
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  static Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Export Local Database to JSON Payload
  static Future<Map<String, dynamic>> createBackupPayload() async {
    final studentRepo = StudentRepository();
    final ledgerRepo = LedgerRepository();
    final settingsRepo = SettingsRepository();

    final students = await studentRepo.getAllStudents();
    final ledger = await ledgerRepo.getAllLedgerEntries();
    final studioInfo = await settingsRepo.getStudioInfo();
    final plans = await settingsRepo.getPlans();
    final services = await settingsRepo.getServices();
    final timings = await settingsRepo.getTimings();
    final hobbies = await settingsRepo.getHobbies();
    final admissionFee = await settingsRepo.getAdmissionFeeAmount();

    return {
      'app': 'Studio Crow',
      'schemaVersion': DatabaseHelper.currentVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'studioInfo': studioInfo.toMap(),
      'plans': plans.map((p) => p.toMap()).toList(),
      'services': services.map((s) => s.toMap()).toList(),
      'timings': timings.map((t) => t.toMap()).toList(),
      'hobbies': hobbies,
      'admissionFeeAmount': admissionFee,
      'students': students.map((s) => s.toMap()).toList(),
      'ledger': ledger.map((l) => l.toMap()).toList(),
    };
  }

  // Upload Backup to Google Drive AppData
  static Future<bool> uploadBackupToDrive() async {
    final user = await getCurrentUser() ?? await signIn();
    if (user == null) return false;

    final authHeaders = await user.authHeaders;
    final payload = await createBackupPayload();
    final jsonStr = jsonEncode(payload);

    // Search existing backup in AppData
    final searchUri = Uri.parse('https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name="studiocrow_backup.json"');
    final searchResp = await http.get(searchUri, headers: authHeaders);

    String? existingFileId;
    if (searchResp.statusCode == 200) {
      final data = jsonDecode(searchResp.body);
      final files = data['files'] as List?;
      if (files != null && files.isNotEmpty) {
        existingFileId = files.first['id'] as String?;
      }
    }

    if (existingFileId != null) {
      // Update existing file
      final updateUri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media');
      final resp = await http.patch(updateUri, headers: {...authHeaders, 'Content-Type': 'application/json'}, body: jsonStr);
      return resp.statusCode == 200;
    } else {
      // Create new file in AppData folder
      final metadata = {
        'name': 'studiocrow_backup.json',
        'parents': ['appDataFolder'],
      };

      final createUri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
      const boundary = '-------314159265358979323846';
      final bodyBytes = utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode(metadata)}\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json\r\n\r\n'
        '$jsonStr\r\n'
        '--$boundary--',
      );

      final resp = await http.post(
        createUri,
        headers: {
          ...authHeaders,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: bodyBytes,
      );

      return resp.statusCode == 200;
    }
  }

  // Restore Backup from Google Drive AppData
  static Future<bool> restoreBackupFromDrive() async {
    final user = await getCurrentUser() ?? await signIn();
    if (user == null) return false;

    final authHeaders = await user.authHeaders;

    final searchUri = Uri.parse('https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name="studiocrow_backup.json"');
    final searchResp = await http.get(searchUri, headers: authHeaders);

    if (searchResp.statusCode != 200) return false;

    final searchData = jsonDecode(searchResp.body);
    final files = searchData['files'] as List?;
    if (files == null || files.isEmpty) return false;

    final fileId = files.first['id'] as String;
    final downloadUri = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
    final downloadResp = await http.get(downloadUri, headers: authHeaders);

    if (downloadResp.statusCode != 200) return false;

    final backupPayload = jsonDecode(downloadResp.body) as Map<String, dynamic>;
    final schemaVersion = backupPayload['schemaVersion'] as int? ?? 1;

    if (schemaVersion > DatabaseHelper.currentVersion) {
      throw Exception('Backup app version naya hai. App update karein.');
    }

    // Atomic Restore inside Transaction
    final db = await DatabaseHelper().database;
    await db.transaction((txn) async {
      await txn.delete('students');
      await txn.delete('ledger');

      final studentsData = backupPayload['students'] as List?;
      if (studentsData != null) {
        for (final sMap in studentsData) {
          await txn.insert('students', sMap as Map<String, dynamic>);
        }
      }

      final ledgerData = backupPayload['ledger'] as List?;
      if (ledgerData != null) {
        for (final lMap in ledgerData) {
          await txn.insert('ledger', lMap as Map<String, dynamic>);
        }
      }
    });

    return true;
  }
}
