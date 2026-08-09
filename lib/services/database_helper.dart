import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/ledger.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'studio_crow.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jdNo TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        fatherName TEXT,
        motherName TEXT,
        photoPath TEXT,
        permVillage TEXT, permPO TEXT, permDist TEXT, permPin TEXT,
        corrSame INTEGER DEFAULT 1,
        corrVillage TEXT, corrPO TEXT, corrDist TEXT, corrPin TEXT,
        aadhar TEXT, dob TEXT, gender TEXT, religion TEXT,
        nationality TEXT DEFAULT 'Indian', maritalStatus TEXT,
        hobbiesJson TEXT, servicesJson TEXT, timingId INTEGER,
        mobile TEXT NOT NULL, altMobile TEXT,
        admissionDate TEXT NOT NULL, plan TEXT NOT NULL,
        admissionFeeEnabled INTEGER DEFAULT 1,
        monthsCovered INTEGER DEFAULT 0,
        cycleBalance REAL DEFAULT 0, credit REAL DEFAULT 0,
        admissionFeePaid INTEGER DEFAULT 0,
        lastVisitDate TEXT, isBlocked INTEGER DEFAULT 0,
        ptEnabled INTEGER DEFAULT 0, ptSessions INTEGER DEFAULT 0,
        ptSessionsDone INTEGER DEFAULT 0, ptSessionPrice REAL DEFAULT 0,
        ptPaid REAL DEFAULT 0, ptTiming TEXT,
        createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        monthLabel TEXT,
        dueAmount REAL DEFAULT 0,
        paidAmount REAL DEFAULT 0,
        balanceOrCredit REAL DEFAULT 0,
        mode TEXT, note TEXT,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)
    ''');

    await db.execute('''
      CREATE TABLE timings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hours REAL NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_students_mobile ON students(mobile)');
    await db.execute('CREATE INDEX idx_students_jdNo ON students(jdNo)');
    await db.execute('CREATE INDEX idx_ledger_student ON ledger(studentId)');
    await db.execute('CREATE INDEX idx_ledger_date ON ledger(date)');

    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> _seedDefaults(Database db) async {
    final defaults = {
      'theme': 'dark',
      'biometricEnabled': '0',
      'dailyBackupOn': '1',
      'wifiOnlyBackup': '1',
      'admissionFeeAmount': '500',
      'studioInfo': '{"name":"StudioCrow","director":"Rahul Raja Sir","contact":"","address":""}',
      'plansJson': '{"Monthly":{"base":1000,"discount":0,"months":1},"Quarterly":{"base":3000,"discount":500,"months":3},"Half Yearly":{"base":6000,"discount":1000,"months":6},"Yearly":{"base":12000,"discount":2000,"months":12}}',
      'servicesJson': '["Bollywood","Hip Hop","Locking & Popping","Contemporary","Salsa","House Dance","Kathak","Odissi","Bharatanatyam","Folk Dance","Zumba Fitness","Yoga","Gymnastics","Stunt","Weight Training","Cardio","CrossFit","Karate","Taekwondo","Kickboxing","MMA","Power Yoga"]',
      'timingsJson': '[{"name":"Weekdays Mon–Fri","hours":1},{"name":"Weekend Sat–Sun","hours":2}]',
      'waTemplatesJson': '{"welcome":"Welcome {name} ji!","feeCollected":"Fees received","feesDue":"Fees due","sendIdCard":"ID card attached"}',
    };

    final batch = db.batch();
    defaults.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit();
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return db.insert('students', student.toMap());
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final maps = await db.query('students', orderBy: 'name ASC');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<int> nextJdNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(CAST(SUBSTR(jdNo, 4) AS INTEGER)) as max FROM students',
    );
    final maxNum = result.first['max'] as int? ?? 0;
    return maxNum + 1;
  }

  Future<int> insertLedger(Ledger ledger) async {
    final db = await database;
    return db.insert('ledger', ledger.toMap());
  }

  Future<void> wipeAll() async {
    final db = await database;
    await db.delete('ledger');
    await db.delete('students');
    await _seedDefaults(db);
  }
}