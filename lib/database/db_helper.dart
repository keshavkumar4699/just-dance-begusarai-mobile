import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// SQLite wrapper for Studio Crow (offline-first, single file on device).
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'studio_crow.db'),
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database d, int version) async {
    await d.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jdNo TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        fatherName TEXT DEFAULT '',
        motherName TEXT DEFAULT '',
        photoPath TEXT DEFAULT '',
        permVillage TEXT DEFAULT '', permPO TEXT DEFAULT '', permDist TEXT DEFAULT '', permPin TEXT DEFAULT '',
        corrSame INTEGER DEFAULT 1,
        corrVillage TEXT DEFAULT '', corrPO TEXT DEFAULT '', corrDist TEXT DEFAULT '', corrPin TEXT DEFAULT '',
        aadhar TEXT DEFAULT '', dob TEXT DEFAULT '', gender TEXT DEFAULT '', religion TEXT DEFAULT '',
        nationality TEXT DEFAULT 'Indian', maritalStatus TEXT DEFAULT '',
        mobile TEXT DEFAULT '', altMobile TEXT DEFAULT '',
        admissionDate TEXT NOT NULL,
        planId INTEGER,
        admissionFeeEnabled INTEGER DEFAULT 1, admissionFeePaid INTEGER DEFAULT 0,
        monthsCovered INTEGER DEFAULT 0, cycleBalance INTEGER DEFAULT 0, credit INTEGER DEFAULT 0,
        lastVisitDate TEXT DEFAULT '',
        isBlocked INTEGER DEFAULT 0,
        ptEnabled INTEGER DEFAULT 0, ptSessions INTEGER DEFAULT 0, ptSessionsDone INTEGER DEFAULT 0,
        ptSessionPrice INTEGER DEFAULT 0, ptPaid INTEGER DEFAULT 0, ptTiming TEXT DEFAULT '',
        createdAt TEXT DEFAULT '', updatedAt TEXT DEFAULT ''
      )
    ''');
    await d.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, fee INTEGER DEFAULT 0, description TEXT DEFAULT '',
        createdAt TEXT DEFAULT ''
      )
    ''');
    await d.execute('''
      CREATE TABLE batches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL, name TEXT NOT NULL, daysInfo TEXT DEFAULT ''
      )
    ''');
    await d.execute('''
      CREATE TABLE timings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId INTEGER NOT NULL, label TEXT NOT NULL, startTime TEXT DEFAULT '', endTime TEXT DEFAULT ''
      )
    ''');
    await d.execute('''
      CREATE TABLE plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, months INTEGER DEFAULT 1, discountType TEXT DEFAULT '%', discountValue INTEGER DEFAULT 0
      )
    ''');
    await d.execute('''
      CREATE TABLE studentCourses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL, courseId INTEGER NOT NULL,
        batchId INTEGER DEFAULT 0, timingId INTEGER DEFAULT 0,
        isPrimary INTEGER DEFAULT 0, feeSnapshot INTEGER DEFAULT 0
      )
    ''');
    await d.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL, courseId INTEGER DEFAULT 0,
        date TEXT NOT NULL, markedAt TEXT DEFAULT ''
      )
    ''');
    await d.execute('''
      CREATE TABLE ledger(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL, date TEXT NOT NULL,
        type TEXT NOT NULL, monthLabel TEXT DEFAULT '',
        dueAmount INTEGER DEFAULT 0, paidAmount INTEGER DEFAULT 0, balanceOrCredit INTEGER DEFAULT 0,
        mode TEXT DEFAULT '', note TEXT DEFAULT ''
      )
    ''');
    await d.execute("CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)");
    await d.execute('CREATE INDEX idx_students_name ON students(name)');
    await d.execute('CREATE INDEX idx_attendance_date ON attendance(date)');
    await d.execute('CREATE INDEX idx_ledger_student ON ledger(studentId)');
  }

  /// Wipes everything (used by Restore flow after snapshot is taken).
  Future<void> wipeAll() async {
    final d = await db;
    await d.delete('students');
    await d.delete('courses');
    await d.delete('batches');
    await d.delete('timings');
    await d.delete('plans');
    await d.delete('studentCourses');
    await d.delete('attendance');
    await d.delete('ledger');
    await d.delete('settings');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// A transaction that spans multiple writes (used by add/restore flows).
typedef Tx = DatabaseExecutor;
