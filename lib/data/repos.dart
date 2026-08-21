/// Just Dance — repositories: thin async wrappers over sqflite tables.
library;

import 'package:sqflite/sqflite.dart' hide Batch;

import 'db.dart';
import 'models.dart';

class Repos {
  Repos._();
  static final Repos instance = Repos._();
  Future<Database> get _db async => AppDb.instance.db;

  // ---------- Settings (key/value) ----------
  Future<String?> getSetting(String key) async {
    final d = await _db;
    final r = await d.query('settings', where: 'key=?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await _db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- Students ----------
  Future<List<Student>> allStudents() async =>
      (await (await _db).query('students', orderBy: 'name COLLATE NOCASE'))
          .map(Student.fromMap)
          .toList();

  Future<int> insertStudent(Student s) async =>
      (await _db).insert('students', s.toMap());

  Future<void> updateStudent(Student s) async =>
      (await _db).update('students', s.toMap(), where: 'id=?', whereArgs: [s.id]);

  Future<void> deleteStudent(int id) async {
    final d = await _db;
    await d.delete('students', where: 'id=?', whereArgs: [id]);
    await d.delete('studentCourses', where: 'studentId=?', whereArgs: [id]);
    await d.delete('ledger', where: 'studentId=?', whereArgs: [id]);
    await d.delete('attendance', where: 'studentId=?', whereArgs: [id]);
  }

  /// Updates just the photo path of one student (used during restore).
  Future<void> updateStudentPhoto(int id, String path) async =>
      (await _db).update('students', {'photoPath': path},
          where: 'id=?', whereArgs: [id]);

  // ---------- Catalog ----------
  Future<List<Course>> allCourses() async =>
      (await (await _db).query('courses', orderBy: 'name COLLATE NOCASE'))
          .map(Course.fromMap)
          .toList();
  Future<int> insertCourse(Course c) async => (await _db).insert('courses', c.toMap());
  Future<void> updateCourse(Course c) async =>
      (await _db).update('courses', c.toMap(), where: 'id=?', whereArgs: [c.id]);
  Future<void> deleteCourse(int id) async {
    final d = await _db;
    await d.delete('courses', where: 'id=?', whereArgs: [id]);
    await d.delete('courseInterests', where: 'courseId=?', whereArgs: [id]);
  }

  // ---------- Course Interests ----------
  Future<List<CourseInterest>> allCourseInterests() async =>
      (await (await _db).query('courseInterests', orderBy: 'name COLLATE NOCASE'))
          .map(CourseInterest.fromMap)
          .toList();
  Future<int> insertCourseInterest(CourseInterest ci) async =>
      (await _db).insert('courseInterests', ci.toMap());
  Future<void> deleteCourseInterest(int id) async =>
      (await _db).delete('courseInterests', where: 'id=?', whereArgs: [id]);

  Future<List<Plan>> allPlans() async =>
      (await (await _db).query('plans', orderBy: 'months')).map(Plan.fromMap).toList();
  Future<int> insertPlan(Plan p0) async => (await _db).insert('plans', p0.toMap());
  Future<void> updatePlan(Plan p0) async =>
      (await _db).update('plans', p0.toMap(), where: 'id=?', whereArgs: [p0.id]);
  Future<void> deletePlan(int id) async =>
      (await _db).delete('plans', where: 'id=?', whereArgs: [id]);

  // ---------- Student courses ----------
  Future<List<StudentCourse>> allStudentCourses() async =>
      (await (await _db).query('studentCourses')).map(StudentCourse.fromMap).toList();
  Future<int> insertStudentCourse(StudentCourse sc) async =>
      (await _db).insert('studentCourses', sc.toMap());
  Future<void> deleteStudentCoursesFor(int studentId) async =>
      (await _db).delete('studentCourses', where: 'studentId=?', whereArgs: [studentId]);

  // ---------- Attendance (insert-only log) ----------
  Future<List<AttendanceRow>> allAttendance() async =>
      (await (await _db).query('attendance', orderBy: 'date DESC, markedAt DESC'))
          .map(AttendanceRow.fromMap)
          .toList();
  Future<int> insertAttendance(AttendanceRow a) async =>
      (await _db).insert('attendance', a.toMap());
  Future<void> deleteAttendance(int id) async =>
      (await _db).delete('attendance', where: 'id=?', whereArgs: [id]);

  // ---------- Ledger (immutable) ----------
  Future<List<LedgerEntry>> allLedger() async =>
      (await (await _db).query('ledger', orderBy: 'date ASC, id ASC'))
          .map(LedgerEntry.fromMap)
          .toList();
  Future<int> insertLedger(LedgerEntry e) async => (await _db).insert('ledger', e.toMap());

  // ---------- Backup/restore helpers ----------
  Future<Map<String, List<Map<String, Object?>>>> dumpAll() async {
    final d = await _db;
    Future<List<Map<String, Object?>>> q(String t) => d.query(t);
    return {
      'students': await q('students'),
      'courses': await q('courses'),
      'courseInterests': await q('courseInterests'),
      'plans': await q('plans'),
      'studentCourses': await q('studentCourses'),
      'attendance': await q('attendance'),
      'ledger': await q('ledger'),
      'settings': await q('settings'),
    };
  }

  Future<void> replaceAll(Map<String, List<Map<String, Object?>>> data) async {
    final d = await _db;
    await d.transaction((txn) async {
      for (final t in [
        'students', 'courses', 'courseInterests', 'plans',
        'studentCourses', 'attendance', 'ledger', 'settings'
      ]) {
        await txn.delete(t);
      }
      for (final t in [
        'courses', 'courseInterests', 'plans', 'students',
        'studentCourses', 'attendance', 'ledger', 'settings'
      ]) {
        for (final row in data[t] ?? const []) {
          await txn.insert(t, row);
        }
      }
    });
  }
}
