import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../database/db_helper.dart';
import '../models/models.dart';
import '../services/backup_service.dart';
import '../services/backup_worker.dart';
import '../services/fee_engine.dart';
import '../services/photo_service.dart';
import '../services/settings_service.dart';
import '../utils/date_utils.dart';

/// One record kept to support Undo after a student delete.
class UndoInfo {
  final Student student;
  final List<StudentCourse> courses;
  final List<LedgerEntry> ledger;
  final List<AttendanceRecord> attendance;
  UndoInfo(this.student, this.courses, this.ledger, this.attendance);
}

/// Result of a payment record.
class PaymentResult {
  final String message;
  final StudentStatus? status;
  PaymentResult(this.message, [this.status]);
}

/// Live preview of a payment before saving.
class PaymentPreview {
  final String paidTill; // display string
  final int newDue;
  final int newAdvance;
  PaymentPreview(this.paidTill, this.newDue, this.newAdvance);
}

/// Central app state: data caches, fee engine wiring, mutations, backup.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // ---- cached data ---------------------------------------------------------
  List<Student> students = [];
  List<Course> courses = [];
  List<Batch> batches = [];
  List<Timing> timings = [];
  List<Plan> plans = [];
  List<StudentCourse> studentCourses = [];
  List<LedgerEntry> ledger = [];
  List<AttendanceRecord> attendance = [];

  final Map<int, List<LedgerEntry>> _ledgerCache = {};
  final Map<int, List<StudentCourse>> _coursesCache = {};
  final Map<int, List<AttendanceRecord>> _attendanceCache = {};
  final Map<int, StudentStatus> _statusCache = {};

  // ---- settings -------------------------------------------------------------
  StudioInfo studio = StudioInfo();
  List<WaTemplate> templates = [];
  bool dark = true;
  bool deviceLockOn = false;
  bool dailyBackupOn = true;
  bool wifiOnlyBackup = false;
  int admissionFeeAmount = 0;
  BackupMeta backupMeta = BackupMeta();

  bool loading = true;
  bool locked = true; // app lock state
  String today = Dates.todayStr();

  /// When set, Home pulses this student's card twice (gold glow) - new member.
  int? pulseStudentId;

  void requestPulse(int studentId) {
    pulseStudentId = studentId;
    notifyListeners();
  }

  void clearPulse() {
    pulseStudentId = null;
  }

  Timer? _backupDebounce;
  Timer? _midnight;

  // ===========================================================================
  // INIT
  // ===========================================================================
  Future<void> init() async {
    await _loadAll();
    await BackupWorker.init();
    _scheduleMidnight();
    loading = false;
    notifyListeners();
    // Auto-retry a pending backup shortly after start.
    if (backupMeta.pending) {
      Timer(const Duration(seconds: 20), () => _runBackup());
    }
  }

  Future<void> _loadAll() async {
    final d = await DbHelper.instance.db;
    students = (await d.query('students', orderBy: 'name COLLATE NOCASE'))
        .map(Student.fromMap)
        .toList();
    courses = (await d.query('courses', orderBy: 'name COLLATE NOCASE')).map(Course.fromMap).toList();
    batches = (await d.query('batches', orderBy: 'name COLLATE NOCASE')).map(Batch.fromMap).toList();
    timings = (await d.query('timings', orderBy: 'label COLLATE NOCASE')).map(Timing.fromMap).toList();
    plans = (await d.query('plans', orderBy: 'name COLLATE NOCASE')).map(Plan.fromMap).toList();
    studentCourses = (await d.query('studentCourses')).map(StudentCourse.fromMap).toList();
    attendance = (await d.query('attendance', orderBy: 'date DESC')).map(AttendanceRecord.fromMap).toList();
    ledger = (await d.query('ledger', orderBy: 'id')).map(LedgerEntry.fromMap).toList();

    _coursesCache.clear();
    for (final sc in studentCourses) {
      _coursesCache.putIfAbsent(sc.studentId, () => []).add(sc);
    }
    _ledgerCache.clear();
    for (final e in ledger) {
      _ledgerCache.putIfAbsent(e.studentId, () => []).add(e);
    }
    _attendanceCache.clear();
    for (final a in attendance) {
      _attendanceCache.putIfAbsent(a.studentId, () => []).add(a);
    }

    final s = SettingsService.instance;
    dark = await s.isDarkTheme();
    deviceLockOn = await s.getBool(SettingsKeys.deviceLockOn, true);
    dailyBackupOn = await s.getBool(SettingsKeys.dailyBackupOn, true);
    wifiOnlyBackup = await s.getBool(SettingsKeys.wifiOnlyBackup, false);
    admissionFeeAmount = await s.getInt(SettingsKeys.admissionFeeAmount, 0);
    studio = await s.studioInfo();
    templates = await s.templates();
    backupMeta = await s.backupMeta();

    refreshStatuses();
  }

  void refreshStatuses() {
    today = Dates.todayStr();
    _statusCache.clear();
    for (final st in students) {
      _statusCache[st.id!] = statusFor(st);
    }
    notifyListeners();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 5), () {
      refreshStatuses();
      _scheduleMidnight();
    });
  }

  // ===========================================================================
  // QUERIES
  // ===========================================================================
  List<StudentCourse> coursesOf(Student s) => _coursesCache[s.id] ?? [];
  List<LedgerEntry> ledgerOf(Student s) => _ledgerCache[s.id] ?? [];
  List<AttendanceRecord> attendanceOf(Student s) => _attendanceCache[s.id] ?? [];

  Course? courseById(int? id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  Batch? batchById(int? id) {
    for (final b in batches) {
      if (b.id == id) return b;
    }
    return null;
  }

  Timing? timingById(int? id) {
    for (final t in timings) {
      if (t.id == id) return t;
    }
    return null;
  }

  Plan? planById(int? id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  Student? studentById(int id) {
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Monthly cycle price = sum of fee snapshots of the student's courses.
  int cyclePriceOf(Student s) {
    var total = 0;
    for (final sc in coursesOf(s)) {
      total += sc.feeSnapshot;
    }
    return total;
  }

  StudentStatus statusFor(Student s) {
    return FeeEngine.computeStatus(
      cyclePrice: cyclePriceOf(s),
      admissionDate: s.admissionDate,
      today: today,
      ledger: ledgerOf(s),
      admissionFeeEnabled: s.admissionFeeEnabled,
      admissionFeePaid: s.admissionFeePaid,
      admissionFeeAmount: admissionFeeAmount,
      isBlocked: s.isBlocked,
    );
  }

  /// Primary course line for cards: "Course · Batch · Timing".
  String primaryCourseLine(Student s) {
    final scs = coursesOf(s);
    StudentCourse? primary;
    for (final sc in scs) {
      if (sc.isPrimary) {
        primary = sc;
        break;
      }
    }
    if (primary == null && scs.isNotEmpty) primary = scs.first;
    if (primary == null) return '';
    final parts = <String>[
      courseById(primary.courseId)?.name ?? '',
      batchById(primary.batchId)?.name ?? '',
      timingById(primary.timingId)?.label ?? '',
    ].where((e) => e.isNotEmpty).join(' · ');
    return parts;
  }

  String planNameOf(Student s) => planById(s.planId)?.name ?? '';

  /// Chip counts for Home.
  Map<String, int> chipCounts() {
    var active = 0, inactive = 0, expired = 0, due = 0, blocked = 0;
    for (final s in students) {
      final st = _statusCache[s.id];
      if (st == null) continue;
      if (s.isBlocked) {
        blocked++;
      } else {
        if (st.status == MemberStatus.expired) expired++;
        if (st.engineDue > 0 || st.admissionFeeDue > 0) due++;
        final lastVisit = Dates.parse(s.effectiveLastVisit());
        final todayD = Dates.parse(today);
        final idle = Dates.daysBetween(todayD, lastVisit);
        if (idle > 7) inactive++;
        if (st.status == MemberStatus.expired ||
            st.status == MemberStatus.nearExpiry ||
            st.status == MemberStatus.active ||
            st.status == MemberStatus.due) {
          if (idle <= 7) active++;
        }
      }
    }
    return {
      'Active': active,
      'Inactive': inactive,
      'Expired': expired,
      'Due': due,
      'Blocked': blocked,
    };
  }

  bool mobileTaken(String mobile) {
    for (final s in students) {
      if (s.mobile == mobile) return true;
    }
    return false;
  }

  // ===========================================================================
  // MUTATIONS - students
  // ===========================================================================
  Future<String> nextJdNo() async {
    var maxNum = 0;
    for (final s in students) {
      final m = RegExp(r'^JD-(\d+)$').firstMatch(s.jdNo);
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'JD-${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  /// Adds a student + course enrollments + initial ledger rows in one transaction.
  Future<Student> addStudent({
    required Student student,
    required List<StudentCourse> scs,
    required List<LedgerEntry> initialLedger,
  }) async {
    final d = await DbHelper.instance.db;
    final id = await d.transaction((txn) async {
      final sid = await txn.insert('students', student.toMap()..['id'] = null);
      for (final sc in scs) {
        await txn.insert('studentCourses', sc.toMap()
          ..['id'] = null
          ..['studentId'] = sid);
      }
      for (final e in initialLedger) {
        await txn.insert('ledger', e.toMap()
          ..['id'] = null
          ..['studentId'] = sid);
      }
      return sid;
    });
    student.id = id;
    await _reloadStudent(id);
    scheduleBackup();
    return student;
  }

  Future<void> updateStudent(Student s, {List<StudentCourse>? scs}) async {
    final d = await DbHelper.instance.db;
    await d.transaction((txn) async {
      await txn.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
      if (scs != null) {
        await txn.delete('studentCourses', where: 'studentId = ?', whereArgs: [s.id]);
        for (final sc in scs) {
          await txn.insert('studentCourses', sc.toMap()..['id'] = null);
        }
      }
    });
    await _reloadStudent(s.id!);
    scheduleBackup();
  }

  Future<void> _reloadStudent(int id) async {
    final d = await DbHelper.instance.db;
    final rows = await d.query('students', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      students.removeWhere((s) => s.id == id);
    } else {
      final updated = Student.fromMap(rows.first);
      final idx = students.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        students[idx] = updated;
      } else {
        students.add(updated);
      }
      final scRows = await d.query('studentCourses', where: 'studentId = ?', whereArgs: [id]);
      final lRows = await d.query('ledger', where: 'studentId = ?', whereArgs: [id], orderBy: 'id');
      final aRows = await d.query('attendance', where: 'studentId = ?', whereArgs: [id], orderBy: 'date');
      _coursesCache[id] = scRows.map(StudentCourse.fromMap).toList();
      _ledgerCache[id] = lRows.map(LedgerEntry.fromMap).toList();
      _attendanceCache[id] = aRows.map(AttendanceRecord.fromMap).toList();
    }
    refreshStatuses();
  }

  /// Deletes a student (cascade ledger + courses + attendance + photo file).
  /// Returns UndoInfo for the 6s Undo SnackBar.
  Future<UndoInfo> deleteStudent(Student s) async {
    final undo = UndoInfo(s, coursesOf(s), ledgerOf(s), attendanceOf(s));
    final d = await DbHelper.instance.db;
    await d.transaction((txn) async {
      await txn.delete('studentCourses', where: 'studentId = ?', whereArgs: [s.id]);
      await txn.delete('attendance', where: 'studentId = ?', whereArgs: [s.id]);
      await txn.delete('ledger', where: 'studentId = ?', whereArgs: [s.id]);
      await txn.delete('students', where: 'id = ?', whereArgs: [s.id]);
    });
    students.removeWhere((x) => x.id == s.id);
    _coursesCache.remove(s.id);
    _ledgerCache.remove(s.id);
    _attendanceCache.remove(s.id);
    _statusCache.remove(s.id);
    if (s.photoPath.isNotEmpty) PhotoService.deleteFile(s.photoPath);
    refreshStatuses();
    scheduleBackup();
    return undo;
  }

  /// Re-inserts a deleted student and replays their ledger.
  Future<void> undoDelete(UndoInfo undo) async {
    final d = await DbHelper.instance.db;
    late int sid;
    await d.transaction((txn) async {
      sid = await txn.insert('students', undo.student.toMap()..['id'] = null);
      for (final sc in undo.courses) {
        await txn.insert('studentCourses', sc.toMap()..['id'] = null);
      }
      for (final e in undo.ledger) {
        await txn.insert('ledger', e.toMap()..['id'] = null);
      }
      for (final a in undo.attendance) {
        await txn.insert('attendance', a.toMap()..['id'] = null);
      }
    });
    await _reloadStudent(sid);
    scheduleBackup();
  }

  // ===========================================================================
  // MUTATIONS - attendance
  // ===========================================================================
  /// Marks a student present today. Insert-only log (duplicates skipped).
  Future<bool> markPresent(Student s, {int? courseId, String? date}) async {
    final day = date ?? today;
    final cid = courseId ?? (coursesOf(s).isNotEmpty ? coursesOf(s).first.courseId : 0);
    for (final a in attendanceOf(s)) {
      if (a.date == day && a.courseId == cid) return false; // already present
    }
    final rec = AttendanceRecord(studentId: s.id!, courseId: cid, date: day);
    final d = await DbHelper.instance.db;
    await d.insert('attendance', rec.toMap()..['id'] = null);
    _attendanceCache[s.id!] = [...attendanceOf(s), rec];
    attendance = [rec, ...attendance];
    s.lastVisitDate = day;
    s.updatedAt = day;
    await d.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    refreshStatuses();
    scheduleBackup();
    return true;
  }

  // ===========================================================================
  // MUTATIONS - payments
  // ===========================================================================
  /// Computes the live preview for the payment dialog.
  PaymentPreview previewPayment(
    Student s, {
    int months = 0,
    String discountType = '%',
    int discountValue = 0,
    int paid = 0,
    bool withAdmission = false,
    int admissionPaid = 0,
  }) {
    final st = statusFor(s);
    final cyclePrice = st.cyclePrice;
    var credit = st.credit;

    var membershipPaid = paid;
    if (months > 0 && cyclePrice > 0) {
      final base = cyclePrice * months;
      final disc = FeeEngine.applyDiscount(base, discountType, discountValue);
      final due = base - disc;
      final advUsed = credit > 0 ? (due > credit ? credit : due) : 0;
      credit -= advUsed;
      membershipPaid += advUsed;
    }
    if (withAdmission) membershipPaid += 0; // admission fee doesn't extend membership
    final newCovered = cyclePrice > 0 ? (st.membershipPaid + membershipPaid) ~/ cyclePrice : 0;
    final paidTill = cyclePrice > 0
        ? Dates.addMonths(Dates.parse(s.admissionDate), newCovered)
        : null;

    int newDue = 0;
    if (paidTill != null) {
      final overdue = Dates.monthsBetween(paidTill, Dates.parse(today));
      if (overdue > 0) newDue = overdue * cyclePrice;
    }
    if (withAdmission && !s.admissionFeePaid) {
      newDue += admissionFeeAmount - admissionPaid;
      if (newDue < 0) newDue = 0;
    }
    // Credit remaining after payment is stored as advance.
    newDue -= credit;
    if (newDue < 0) newDue = 0;

    return PaymentPreview(
      paidTill != null ? Dates.display(Dates.fmt(paidTill)) : '--',
      newDue,
      credit,
    );
  }

  /// Records a payment. Handles admission fee, plan months, discount,
  /// advance usage, overpay -> credit and the auto credit-consume loop.
  Future<PaymentResult> recordPayment(
    Student s, {
    int months = 0,
    String discountType = '%',
    int discountValue = 0,
    int paid = 0,
    String mode = 'Cash',
    String date = '',
    String note = '',
    bool withAdmission = false,
    int admissionPaid = 0,
  }) async {
    final day = date.isEmpty ? today : date;
    final st = statusFor(s);
    final cyclePrice = st.cyclePrice;
    var credit = st.credit;
    final entries = <LedgerEntry>[];

    if (withAdmission && !s.admissionFeePaid && admissionPaid > 0) {
      final due = admissionFeeAmount;
      final bal = admissionPaid - due;
      entries.add(LedgerEntry(
        studentId: s.id!,
        date: day,
        type: LedgerType.admissionFeePaid,
        dueAmount: due,
        paidAmount: admissionPaid,
        balanceOrCredit: bal,
        mode: mode,
        note: note,
      ));
      s.admissionFeePaid = true;
    }

    if (months > 0 && cyclePrice > 0) {
      final base = cyclePrice * months;
      final disc = FeeEngine.applyDiscount(base, discountType, discountValue);
      var due = base - disc;
      final advUsed = credit > 0 ? (due > credit ? credit : due) : 0;
      if (advUsed > 0) {
        entries.add(LedgerEntry(
          studentId: s.id!,
          date: day,
          type: LedgerType.autoCreditAdjust,
          monthLabel: _monthLabelFor(s, 0),
          dueAmount: advUsed,
          paidAmount: advUsed,
          balanceOrCredit: 0,
          mode: 'Advance',
          note: 'Advance used',
        ));
        credit -= advUsed;
        due -= advUsed;
      }
      final bal = paid - due;
      entries.add(LedgerEntry(
        studentId: s.id!,
        date: day,
        type: LedgerType.payment,
        monthLabel: _monthLabelFor(s, months),
        dueAmount: due,
        paidAmount: paid,
        balanceOrCredit: bal,
        mode: mode,
        note: note,
      ));
      if (bal > 0) credit += bal;
    } else if (paid > 0 && !withAdmission) {
      // Cash with no months selected - treat as advance.
      entries.add(LedgerEntry(
        studentId: s.id!,
        date: day,
        type: LedgerType.payment,
        monthLabel: _monthLabelFor(s, 0),
        dueAmount: 0,
        paidAmount: paid,
        balanceOrCredit: paid,
        mode: mode,
        note: note,
      ));
      credit += paid;
    }

    final d = await DbHelper.instance.db;
    await d.transaction((txn) async {
      for (final e in entries) {
        await txn.insert('ledger', e.toMap()..['id'] = null);
      }
      s.updatedAt = day;
      await txn.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    });
    await _reloadStudent(s.id!);

    // Auto credit-consume: when due exists and credit >= cycle price.
    var status = statusFor(s);
    while (status.engineDue > 0 && status.credit >= cyclePrice && cyclePrice > 0) {
      final adj = LedgerEntry(
        studentId: s.id!,
        date: today,
        type: LedgerType.autoCreditAdjust,
        monthLabel: _monthLabelFor(s, 0),
        dueAmount: cyclePrice,
        paidAmount: cyclePrice,
        balanceOrCredit: 0,
        mode: 'Advance',
        note: 'Auto credit adjustment',
      );
      await d.insert('ledger', adj.toMap()..['id'] = null);
      await _reloadStudent(s.id!);
      status = statusFor(s);
    }

    refreshStatuses();
    scheduleBackup();
    return PaymentResult(
      'Payment saved. ${status.credit > 0 ? "Advance ${Money.fmt(status.credit)}" : ''}',
      status,
    );
  }

  String _monthLabelFor(Student s, int months) {
    final covered = statusFor(s).monthsCovered;
    final target = FeeEngine.addMonths(Dates.parse(s.admissionDate), covered + months);
    return Dates.monthLabel(Dates.fmt(target));
  }

  /// Records a plan change (ledger type PLAN_CHANGE, informational).
  Future<void> recordPlanChange(Student s, int? fromPlanId, int toPlanId) async {
    final e = LedgerEntry(
      studentId: s.id!,
      date: today,
      type: LedgerType.planChange,
      dueAmount: 0,
      paidAmount: 0,
      balanceOrCredit: 0,
      mode: '',
      note: 'Plan changed: ${planById(fromPlanId)?.name ?? 'none'} -> ${planById(toPlanId)?.name ?? ''}',
    );
    final d = await DbHelper.instance.db;
    await d.insert('ledger', e.toMap()..['id'] = null);
    await _reloadStudent(s.id!);
    scheduleBackup();
  }

  // ===========================================================================
  // MUTATIONS - PT
  // ===========================================================================
  Future<void> savePt(Student s, {bool? enabled, int? sessions, int? price, String? timing}) async {
    if (enabled != null) s.ptEnabled = enabled;
    if (sessions != null) s.ptSessions = sessions;
    if (price != null) s.ptSessionPrice = price;
    if (timing != null) s.ptTiming = timing;
    s.updatedAt = today;
    final d = await DbHelper.instance.db;
    await d.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    await _reloadStudent(s.id!);
    scheduleBackup();
  }

  /// Marks one PT session complete (+1, capped at total sessions).
  Future<bool> markPtSession(Student s) async {
    if (s.ptSessionsDone >= s.ptSessions) return false;
    s.ptSessionsDone += 1;
    s.updatedAt = today;
    final d = await DbHelper.instance.db;
    await d.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    await _reloadStudent(s.id!);
    scheduleBackup();
    return true;
  }

  /// Records a PT payment (ledger type PT_PAYMENT).
  Future<void> recordPtPayment(Student s, int paid, String mode) async {
    final e = LedgerEntry(
      studentId: s.id!,
      date: today,
      type: LedgerType.ptPayment,
      dueAmount: paid,
      paidAmount: paid,
      balanceOrCredit: 0,
      mode: mode,
      note: 'Personal training',
    );
    final d = await DbHelper.instance.db;
    await d.insert('ledger', e.toMap()..['id'] = null);
    s.ptPaid += paid;
    s.updatedAt = today;
    await d.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    await _reloadStudent(s.id!);
    scheduleBackup();
  }

  // ===========================================================================
  // MUTATIONS - catalog (courses / batches / timings / plans)
  // ===========================================================================
  Future<Course> addCourse(String name, int fee, String description) async {
    final c = Course(name: name, fee: fee, description: description);
    final d = await DbHelper.instance.db;
    c.id = await d.insert('courses', c.toMap()..['id'] = null);
    courses = [...courses, c];
    refreshStatuses();
    scheduleBackup();
    return c;
  }

  Future<void> updateCourse(Course c) async {
    final d = await DbHelper.instance.db;
    await d.update('courses', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    final idx = courses.indexWhere((x) => x.id == c.id);
    if (idx >= 0) courses[idx] = c;
    scheduleBackup();
  }

  /// Returns an error message when deletion is blocked (course assigned).
  Future<String?> deleteCourse(Course c) async {
    final inUse = studentCourses.any((sc) => sc.courseId == c.id);
    if (inUse) return 'This course is assigned to students';
    final d = await DbHelper.instance.db;
    await d.delete('courses', where: 'id = ?', whereArgs: [c.id]);
    courses.removeWhere((x) => x.id == c.id);
    batches.removeWhere((x) => x.courseId == c.id);
    timings.removeWhere((t) => !batches.any((b) => b.id == t.batchId));
    scheduleBackup();
    return null;
  }

  Future<Batch> addBatch(int courseId, String name, String daysInfo) async {
    final b = Batch(courseId: courseId, name: name, daysInfo: daysInfo);
    final d = await DbHelper.instance.db;
    b.id = await d.insert('batches', b.toMap()..['id'] = null);
    batches = [...batches, b];
    scheduleBackup();
    return b;
  }

  Future<void> updateBatch(Batch b) async {
    final d = await DbHelper.instance.db;
    await d.update('batches', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
    final idx = batches.indexWhere((x) => x.id == b.id);
    if (idx >= 0) batches[idx] = b;
    scheduleBackup();
  }

  Future<String?> deleteBatch(Batch b) async {
    final inUse = studentCourses.any((sc) => sc.batchId == b.id);
    if (inUse) return 'This batch is assigned to students';
    final d = await DbHelper.instance.db;
    await d.delete('batches', where: 'id = ?', whereArgs: [b.id]);
    batches.removeWhere((x) => x.id == b.id);
    timings.removeWhere((t) => t.batchId == b.id);
    scheduleBackup();
    return null;
  }

  Future<Timing> addTiming(int batchId, String label, String start, String end) async {
    final t = Timing(batchId: batchId, label: label, startTime: start, endTime: end);
    final d = await DbHelper.instance.db;
    t.id = await d.insert('timings', t.toMap()..['id'] = null);
    timings = [...timings, t];
    scheduleBackup();
    return t;
  }

  Future<void> updateTiming(Timing t) async {
    final d = await DbHelper.instance.db;
    await d.update('timings', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    final idx = timings.indexWhere((x) => x.id == t.id);
    if (idx >= 0) timings[idx] = t;
    scheduleBackup();
  }

  Future<String?> deleteTiming(Timing t) async {
    final inUse = studentCourses.any((sc) => sc.timingId == t.id);
    if (inUse) return 'This timing is assigned to students';
    final d = await DbHelper.instance.db;
    await d.delete('timings', where: 'id = ?', whereArgs: [t.id]);
    timings.removeWhere((x) => x.id == t.id);
    scheduleBackup();
    return null;
  }

  Future<Plan> addPlan(String name, int months, String discountType, int discountValue) async {
    final p = Plan(name: name, months: months, discountType: discountType, discountValue: discountValue);
    final d = await DbHelper.instance.db;
    p.id = await d.insert('plans', p.toMap()..['id'] = null);
    plans = [...plans, p];
    scheduleBackup();
    return p;
  }

  Future<void> updatePlan(Plan p) async {
    final d = await DbHelper.instance.db;
    await d.update('plans', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    final idx = plans.indexWhere((x) => x.id == p.id);
    if (idx >= 0) plans[idx] = p;
    scheduleBackup();
  }

  Future<String?> deletePlan(Plan p) async {
    final inUse = students.any((s) => s.planId == p.id);
    if (inUse) return 'This plan is used by students';
    final d = await DbHelper.instance.db;
    await d.delete('plans', where: 'id = ?', whereArgs: [p.id]);
    plans.removeWhere((x) => x.id == p.id);
    scheduleBackup();
    return null;
  }

  // ===========================================================================
  // MUTATIONS - settings
  // ===========================================================================
  Future<void> setTheme(bool darkMode) async {
    dark = darkMode;
    await SettingsService.instance.setTheme(darkMode);
    notifyListeners();
  }

  Future<void> setDeviceLock(bool on) async {
    deviceLockOn = on;
    await SettingsService.instance.setBool(SettingsKeys.deviceLockOn, on);
    notifyListeners();
  }

  Future<void> setDailyBackup(bool on) async {
    dailyBackupOn = on;
    await SettingsService.instance.setBool(SettingsKeys.dailyBackupOn, on);
    if (on) {
      await BackupWorker.register();
    } else {
      await BackupWorker.unregister();
    }
    notifyListeners();
  }

  Future<void> setWifiOnly(bool on) async {
    wifiOnlyBackup = on;
    await SettingsService.instance.setBool(SettingsKeys.wifiOnlyBackup, on);
    notifyListeners();
  }

  Future<void> setAdmissionFeeAmount(int amount) async {
    admissionFeeAmount = amount;
    await SettingsService.instance.set(SettingsKeys.admissionFeeAmount, amount.toString());
    refreshStatuses();
    scheduleBackup();
  }

  Future<void> saveStudioInfo(StudioInfo info) async {
    studio = info;
    await SettingsService.instance.saveStudioInfo(info);
    notifyListeners();
    scheduleBackup();
  }

  Future<void> saveTemplates(List<WaTemplate> list) async {
    templates = list;
    await SettingsService.instance.saveTemplates(list);
    notifyListeners();
    scheduleBackup();
  }

  // ===========================================================================
  // BACKUP
  // ===========================================================================
  /// Debounced (15s) backup after every change.
  void scheduleBackup() {
    _backupDebounce?.cancel();
    _backupDebounce = Timer(const Duration(seconds: 15), () => _runBackup());
  }

  Future<BackupResult> _runBackup() async {
    if (backupMeta.accountEmail == null) return BackupResult(false, 'Not signed in');
    final res = await BackupService.instance.backupNow();
    backupMeta = await SettingsService.instance.backupMeta();
    notifyListeners();
    return res;
  }

  Future<BackupResult> backupNow({bool showErrors = true}) async {
    if (backupMeta.accountEmail == null) {
      return BackupResult(false, 'Not signed in - sign in with Google first');
    }
    final res = await BackupService.instance.backupNow();
    backupMeta = await SettingsService.instance.backupMeta();
    notifyListeners();
    return res;
  }

  /// Re-reads backup meta (after sign-in / sign-out) and refreshes the UI.
  Future<void> reloadBackupMeta() async {
    backupMeta = await SettingsService.instance.backupMeta();
    notifyListeners();
  }

  /// Restore: takes a safety snapshot, wipes, imports. Returns RestoreResult.
  Future<RestoreResult> restoreFromBackup(Map<String, Object?> backup) async {
    final data = backup['data'] as Map<String, Object?>?;
    if (data == null) return RestoreResult(false, 'Backup file is invalid');
    try {
      await _writeSnapshot(await BackupService.instance.exportDb());
      await _import(data);
      return RestoreResult(true, 'Restored successfully - you can Undo', backup);
    } catch (e) {
      return RestoreResult(false, 'Restore failed: $e');
    }
  }

  /// Undo a restore (re-imports the pre-restore snapshot).
  Future<RestoreResult> undoRestore() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/${AppInfo.snapshotFileName}');
      if (!f.existsSync()) return RestoreResult(false, 'No snapshot to undo to');
      final snapshot = jsonDecode(await f.readAsString()) as Map<String, Object?>;
      await _import(snapshot);
      f.deleteSync();
      return RestoreResult(true, 'Previous data restored');
    } catch (e) {
      return RestoreResult(false, 'Undo failed: $e');
    }
  }

  Future<void> _writeSnapshot(Map<String, Object?> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/${AppInfo.snapshotFileName}');
    await f.writeAsString(jsonEncode(data));
  }

  /// Clears the pending snapshot file (after a successful undo or explicit clear).
  Future<void> clearSnapshot() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/${AppInfo.snapshotFileName}');
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  Future<void> _import(Map<String, Object?> data) async {
    final d = await DbHelper.instance.db;
    await d.transaction((txn) async {
      await txn.delete('students');
      await txn.delete('courses');
      await txn.delete('batches');
      await txn.delete('timings');
      await txn.delete('plans');
      await txn.delete('studentCourses');
      await txn.delete('attendance');
      await txn.delete('ledger');
      await txn.delete('settings');
      const tables = [
        'students', 'courses', 'batches', 'timings', 'plans',
        'studentCourses', 'attendance', 'ledger', 'settings',
      ];
      for (final t in tables) {
        final rows = (data[t] as List?)?.cast<Map<String, Object?>>() ?? [];
        for (final row in rows) {
          await txn.insert(t, row);
        }
      }
    });
    await _loadAll();
  }

  @override
  void dispose() {
    _backupDebounce?.cancel();
    _midnight?.cancel();
    super.dispose();
  }
}

/// Attendance statistics for one student (computed, never stored).
class AttendanceStats {
  final int total;
  final int expected;
  final int currentStreak;
  final int longestStreak;
  final String firstVisit;
  final String lastVisit;
  final List<String> missed;
  final Map<String, List<String>> perMonth; // '2026-08' -> present dates
  final Map<int, List<String>> perCourse; // courseId -> present dates

  AttendanceStats({
    required this.total,
    required this.expected,
    required this.currentStreak,
    required this.longestStreak,
    required this.firstVisit,
    required this.lastVisit,
    required this.missed,
    required this.perMonth,
    required this.perCourse,
  });

  double get rate => expected == 0 ? 0 : total / expected;

  static AttendanceStats compute(Student s, List<AttendanceRecord> records, String today) {
    final from = s.admissionDate;
    final to = today;
    final days = Dates.eachDay(from, to);
    final present = <String>{}; // date -> present (any course)
    final perMonth = <String, List<String>>{};
    final perCourse = <int, List<String>>{};
    for (final r in records) {
      present.add(r.date);
      perMonth.putIfAbsent(Dates.monthKey(r.date), () => []).add(r.date);
      if (r.courseId != 0) {
        perCourse.putIfAbsent(r.courseId, () => []).add(r.date);
      }
    }
    final missed = days.where((d) => !present.contains(d)).toList();

    // Streaks over consecutive calendar days.
    var current = 0;
    var longest = 0;
    var run = 0;
    var prev = DateTime(0);
    final presentSorted = present.toList()..sort();
    for (final d in presentSorted) {
      final cur = Dates.parse(d);
      if (run > 0 && Dates.daysBetween(prev, cur) == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      prev = cur;
    }
    // Current streak = run ending today (or yesterday).
    final lastPresent = presentSorted.isNotEmpty ? Dates.parse(presentSorted.last) : null;
    if (lastPresent != null) {
      final todayD = Dates.parse(today);
      final gap = Dates.daysBetween(lastPresent, todayD);
      if (gap <= 1) {
        // count backwards from last present
        var cur = lastPresent;
        var count = 0;
        final set = present;
        while (set.contains(Dates.fmt(cur))) {
          count++;
          cur = cur.subtract(const Duration(days: 1));
        }
        current = count;
      }
    }

    return AttendanceStats(
      total: present.length,
      expected: days.length,
      currentStreak: current,
      longestStreak: longest,
      firstVisit: presentSorted.isNotEmpty ? presentSorted.first : '',
      lastVisit: presentSorted.isNotEmpty ? presentSorted.last : s.lastVisitDate,
      missed: missed,
      perMonth: perMonth,
      perCourse: perCourse,
    );
  }
}
