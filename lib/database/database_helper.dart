import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('just_dance_begusarai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Students Table
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        parentPhone TEXT,
        danceStyles TEXT NOT NULL,
        batchTiming TEXT NOT NULL,
        joiningDate TEXT NOT NULL,
        monthlyFee REAL NOT NULL,
        dueDay INTEGER NOT NULL DEFAULT 5,
        status TEXT NOT NULL DEFAULT 'Active',
        photoPath TEXT
      )
    ''');

    // 2. Ledger Table
    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        monthYear TEXT NOT NULL,
        amountDue REAL NOT NULL,
        amountPaid REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        paymentMode TEXT NOT NULL DEFAULT 'Cash',
        status TEXT NOT NULL DEFAULT 'Pending',
        transactionRef TEXT,
        notes TEXT,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // 3. Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Populate Seed Data for Phase 1 Demo
    await SeedData.insertDemoData(db);
  }

  // --- Student Operations ---
  Future<int> insertStudent(Student student) async {
    final db = await instance.database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getAllStudents({String? searchQuery, String? statusFilter}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += '(name LIKE ? OR phone LIKE ? OR danceStyles LIKE ?)';
      final query = '%${searchQuery.trim()}%';
      whereArgs.addAll([query, query, query]);
    }

    if (statusFilter != null && statusFilter != 'All') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(statusFilter);
    }

    final result = await db.query(
      'students',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Student.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await instance.database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Ledger Operations ---
  Future<int> insertLedgerEntry(LedgerEntry entry) async {
    final db = await instance.database;
    return await db.insert('ledger', entry.toMap());
  }

  Future<List<LedgerEntry>> getLedgerForStudent(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'ledger',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'id DESC',
    );
    return result.map((json) => LedgerEntry.fromMap(json)).toList();
  }

  Future<List<LedgerEntry>> getAllLedgerEntries() async {
    final db = await instance.database;
    final result = await db.query('ledger', orderBy: 'id DESC');
    return result.map((json) => LedgerEntry.fromMap(json)).toList();
  }

  // --- Settings Operations ---
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<int> setSetting(String key, String value) async {
    final db = await instance.database;
    return await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
