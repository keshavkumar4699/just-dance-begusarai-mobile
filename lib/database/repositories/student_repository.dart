import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/student.dart';
import '../../models/ledger_entry.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper;

  StudentRepository({
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Inserts a new student inside an SQLite transaction.
  /// Automatically creates initial admission fee ledger entry if enabled.
  Future<Student> insertStudent(Student student, {double initialPaid = 0.0, String paymentMode = 'Cash'}) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final jdNo = student.jdNo.isEmpty || student.jdNo == 'AUTO'
          ? await _generateJdNoInTxn(txn)
          : student.jdNo;

      final studentMap = student.toMap();
      studentMap['jdNo'] = jdNo;
      studentMap.remove('id');

      final studentId = await txn.insert('students', studentMap);
      final createdStudent = Student.fromMap({...studentMap, 'id': studentId});

      // Record admission fee ledger entry if admission fee is enabled
      if (createdStudent.admissionFeeEnabled) {
        final admissionFeeEntry = LedgerEntry(
          studentId: studentId,
          date: createdStudent.admissionDate,
          type: 'ADMISSION_FEE_PAID',
          monthLabel: 'Admission',
          dueAmount: 500.0,
          paidAmount: initialPaid > 500.0 ? 500.0 : initialPaid,
          balanceOrCredit: initialPaid >= 500.0 ? 0.0 : (500.0 - initialPaid),
          mode: paymentMode,
          note: 'Admission fee recorded during registration',
        );
        await txn.insert('ledger', admissionFeeEntry.toMap());
      }

      return createdStudent;
    });
  }

  /// Updates an existing student record
  Future<int> updateStudent(Student student) async {
    final db = await _dbHelper.database;
    final updatedMap = student.toMap();
    updatedMap['updatedAt'] = DateTime.now().toIso8601String();

    return await db.update(
      'students',
      updatedMap,
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  /// Deletes student and all associated ledger records in a single transaction
  Future<void> deleteStudent(int studentId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('ledger', where: 'studentId = ?', whereArgs: [studentId]);
      await txn.delete('students', where: 'id = ?', whereArgs: [studentId]);
    });
  }

  /// Fetches student by ID
  Future<Student?> getStudentById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('students', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  /// Fetches all students
  Future<List<Student>> getAllStudents() async {
    final db = await _dbHelper.database;
    final maps = await db.query('students', orderBy: 'id DESC');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  /// Searches students by query (name, mobile, altMobile, jdNo)
  Future<List<Student>> searchStudents(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllStudents();

    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT * FROM students 
      WHERE LOWER(name) LIKE ? 
         OR mobile LIKE ? 
         OR altMobile LIKE ? 
         OR LOWER(jdNo) LIKE ?
      ORDER BY id DESC
    ''', ['%$clean%', '%$clean%', '%$clean%', '%$clean%']);

    return maps.map((m) => Student.fromMap(m)).toList();
  }

  /// Records member check-in (sets lastVisitDate = today)
  Future<void> recordCheckIn(int studentId, {DateTime? visitDate}) async {
    final db = await _dbHelper.database;
    final now = (visitDate ?? DateTime.now()).toIso8601String();
    await db.update(
      'students',
      {'lastVisitDate': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  /// Toggles blocked status
  Future<void> toggleBlockStatus(int studentId, bool isBlocked) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'students',
      {'isBlocked': isBlocked ? 1 : 0, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<String> _generateJdNoInTxn(Transaction txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) as count FROM students');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return 'JD-${(count + 1).toString().padLeft(3, '0')}';
  }
}
