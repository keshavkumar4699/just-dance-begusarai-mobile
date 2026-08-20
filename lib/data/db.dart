/// Just Dance — SQLite open/migrations + low-level helpers.
library;

import 'package:sqflite/sqflite.dart' hide Batch;

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _name = 'studio_crow.db';
  static const _version = 3;

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/$_name',
      version: _version,
      onCreate: (d, v) async => _createAll(d),
      onUpgrade: (d, o, n) async => _upgrade(d, o, n),
    );
  }

  Future<void> _upgrade(Database d, int from, int to) async {
    if (from < 2) {
      await d.execute(
          "ALTER TABLE batches ADD COLUMN duration TEXT DEFAULT ''");
    }
    if (from < 3) {
      await d.execute(
          "ALTER TABLE students ADD COLUMN ptDays TEXT DEFAULT ''");
    }
  }

  Future<void> _createAll(Database d) async {
    await d.execute('''
CREATE TABLE students(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  jdNo TEXT NOT NULL,
  name TEXT NOT NULL,
  fatherName TEXT DEFAULT '',
  motherName TEXT DEFAULT '',
  photoPath TEXT DEFAULT '',
  permVillage TEXT DEFAULT '', permPO TEXT DEFAULT '', permDist TEXT DEFAULT '', permPin TEXT DEFAULT '',
  corrSame INTEGER DEFAULT 1,
  corrVillage TEXT DEFAULT '', corrPO TEXT DEFAULT '', corrDist TEXT DEFAULT '', corrPin TEXT DEFAULT '',
  aadhar TEXT DEFAULT '',
  dob TEXT,
  gender TEXT DEFAULT '',
  religion TEXT DEFAULT '',
  nationality TEXT DEFAULT 'Indian',
  maritalStatus TEXT DEFAULT '',
  mobile TEXT DEFAULT '',
  altMobile TEXT DEFAULT '',
  admissionDate TEXT NOT NULL,
  planId INTEGER,
  admissionFeeEnabled INTEGER DEFAULT 1,
  admissionFeePaid INTEGER DEFAULT 0,
  monthsCovered INTEGER DEFAULT 0,
  cycleBalance REAL DEFAULT 0,
  credit REAL DEFAULT 0,
  lastVisitDate TEXT,
  isBlocked INTEGER DEFAULT 0,
  ptEnabled INTEGER DEFAULT 0,
  ptSessions INTEGER DEFAULT 0,
  ptSessionsDone INTEGER DEFAULT 0,
  ptSessionPrice REAL DEFAULT 0,
  ptPaid REAL DEFAULT 0,
  ptTiming TEXT DEFAULT '',
  ptDays TEXT DEFAULT '',
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)''');
    await d.execute(
        'CREATE TABLE courses(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, fee REAL DEFAULT 0, description TEXT DEFAULT \'\', createdAt TEXT NOT NULL)');
    await d.execute(
        'CREATE TABLE batches(id INTEGER PRIMARY KEY AUTOINCREMENT, courseId INTEGER NOT NULL, name TEXT NOT NULL, daysInfo TEXT DEFAULT \'\', duration TEXT DEFAULT \'\')');
    await d.execute(
        'CREATE TABLE timings(id INTEGER PRIMARY KEY AUTOINCREMENT, batchId INTEGER NOT NULL, label TEXT NOT NULL, startTime TEXT DEFAULT \'\', endTime TEXT DEFAULT \'\')');
    await d.execute(
        'CREATE TABLE plans(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, months INTEGER DEFAULT 1, discountType TEXT DEFAULT \'\', discountValue REAL DEFAULT 0)');
    await d.execute(
        'CREATE TABLE studentCourses(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER NOT NULL, courseId INTEGER NOT NULL, batchId INTEGER DEFAULT 0, timingId INTEGER DEFAULT 0, isPrimary INTEGER DEFAULT 0)');
    await d.execute(
        'CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER NOT NULL, courseId INTEGER DEFAULT 0, date TEXT NOT NULL, markedAt TEXT NOT NULL)');
    await d.execute('''
CREATE TABLE ledger(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  studentId INTEGER NOT NULL,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  monthLabel TEXT DEFAULT '',
  dueAmount REAL DEFAULT 0,
  paidAmount REAL DEFAULT 0,
  balanceOrCredit REAL DEFAULT 0,
  mode TEXT DEFAULT '',
  note TEXT DEFAULT '',
  cyclePrice REAL DEFAULT 0,
  discount REAL DEFAULT 0
)''');
    await d.execute(
        'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
    await d.execute(
        'CREATE INDEX idx_ledger_student ON ledger(studentId)');
    await d.execute(
        'CREATE INDEX idx_attendance_student ON attendance(studentId)');
    await d.execute(
        'CREATE INDEX idx_attendance_date ON attendance(date)');
    await d.execute(
        'CREATE INDEX idx_sc_student ON studentCourses(studentId)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
