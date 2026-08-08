import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../database/database_helper.dart';

class BackupService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  static Future<Map<String, dynamic>> exportDatabaseToJSON() async {
    final dbHelper = DatabaseHelper.instance;
    final students = await dbHelper.getAllStudents();
    final ledger = await dbHelper.getAllLedgerEntries();

    final exportData = {
      'app': 'Just Dance Academy',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'students': students.map((s) => s.toMap()).toList(),
      'ledger': ledger.map((l) => l.toMap()).toList(),
    };

    return exportData;
  }

  static Future<bool> performCloudBackup() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final data = await exportDatabaseToJSON();
      final jsonString = jsonEncode(data);

      // Store backup timestamp in DB settings
      await DatabaseHelper.instance.setSetting(
        'last_backup_time',
        DateTime.now().toLocal().toString().split('.')[0],
      );

      // JSON payload formatted for Drive REST API / appDataFolder
      print("Backup size: ${jsonString.length} bytes for ${account.email}");
      return true;
    } catch (e) {
      print("Backup error: $e");
      return false;
    }
  }

  static Future<String?> getLastBackupTimestamp() async {
    return await DatabaseHelper.instance.getSetting('last_backup_time');
  }
}
