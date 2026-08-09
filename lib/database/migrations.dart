import 'package:sqflite/sqflite.dart';
import 'tables.dart';

/// Studio Crow Database Migration Handler
abstract class Migrations {
  static const int currentVersion = 1;

  static Future<void> onCreate(Database db, int version) async {
    await db.execute(Tables.createStudentsTable);
    await db.execute(Tables.createLedgerTable);
    await db.execute(Tables.createSettingsTable);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration handling for future database schema versions
    if (oldVersion < 2) {
      // Future version migration logic goes here
    }
  }
}
