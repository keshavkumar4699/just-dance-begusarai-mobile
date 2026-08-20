/// Just Dance — AppStore: single source of truth (ChangeNotifier).
/// Caches every table, recomputes statuses on demand, persists mutations,
/// and pokes the backup engine (debounced) after every change.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../services/photo_service.dart';
import 'fee_engine.dart';
import 'models.dart';
import 'repos.dart';

/// Realtime member buckets (never stored).
enum MemberStatus { active, nearExpiry, expired, inactive, blocked }

class HomeFilter {
  final String key;
  const HomeFilter(this.key);
  static const all = HomeFilter('all');
  static const active = HomeFilter('active');
  static const inactive = HomeFilter('inactive');
  static const expired = HomeFilter('expired');
  static const due = HomeFilter('due');
  static const blocked = HomeFilter('blocked');
}

class AppStore extends ChangeNotifier {
  // ----- caches -----
  List<Student> students = [];
  List<Course> courses = [];
  List<Batch> batches = [];
  List<BatchTiming> timings = [];
  List<Plan> plans = [];
  List<StudentCourse> studentCourses = [];
  List<AttendanceRow> attendance = [];
  List<LedgerEntry> ledger = [];

  // ----- settings -----
  bool isDark = true;
  bool deviceLockOn = false;
  StudioInfo studio = StudioInfo();
  Map<String, String> templates = Map.of(kDefaultTemplates);
  double admissionFeeAmount = 0;
  String gstin = '';
  double gstRate = 0; // percent, 0 = GST off
  double ptDefaultSessionPrice = 0; // studio default ₹/session
  String ptDefaultDuration = ''; // e.g. "1 hour"
  String ptDefaultDays = ''; // e.g. "Mon,Wed,Fri"
  bool dailyBackupOn = true;
  bool wifiOnlyBackup = false;
  Map<String, Object?> backupMeta = {}; // {email,lastBackup,status,error}
  bool backupPending = false;

  bool loaded = false;
  int pulseStudentId = 0; // newly added card pulses on Home
  bool suppressLock = false; // in-app external flow (photo pick) — skip relock

  /// Wired by BackupService — called (debounced inside) after every mutation.
  void Function()? onDataChanged;

  Timer? _midnightTimer;

  Future<void> load() async {
    final r = Repos.instance;
    students = await r.allStudents();
    courses = await r.allCourses();
    batches = await r.allBatches();
    timings = await r.allTimings();
    plans = await r.allPlans();
    studentCourses = await r.allStudentCourses();
    attendance = await r.allAttendance();
    ledger = await r.allLedger();

    isDark = (await r.getSetting(kPrefTheme)) != 'light';
    deviceLockOn = (await r.getSetting(kPrefDeviceLock)) == '1';
    final studioJson = await r.getSetting(kPrefStudio);
    if (studioJson != null) {
      studio = StudioInfo.fromJson(jsonDecode(studioJson) as Map<String, Object?>);
    }
    final tJson = await r.getSetting(kPrefTemplates);
    if (tJson != null) {
      templates = {
        ...kDefaultTemplates,
        ...(jsonDecode(tJson) as Map).map((k, v) => MapEntry('$k', '$v'))
      };
    }
    admissionFeeAmount =
        double.tryParse(await r.getSetting(kPrefAdmissionFee) ?? '') ?? 0;
    gstin = await r.getSetting(kPrefGstin) ?? '';
    gstRate =
        double.tryParse(await r.getSetting(kPrefGstRate) ?? '') ?? 0;
    ptDefaultSessionPrice =
        double.tryParse(await r.getSetting(kPrefPtSessionPrice) ?? '') ?? 0;
    ptDefaultDuration = await r.getSetting(kPrefPtDuration) ?? '';
    ptDefaultDays = await r.getSetting(kPrefPtDays) ?? '';
    dailyBackupOn = (await r.getSetting(kPrefDailyBackup)) != '0';
    wifiOnlyBackup = (await r.getSetting(kPrefWifiOnly)) == '1';
    final meta = await r.getSetting(kPrefBackupMeta);
    if (meta != null) backupMeta = jsonDecode(meta) as Map<String, Object?>;
    backupPending = (await r.getSetting(kPrefBackupPending)) == '1';

    _scheduleMidnight();
    loaded = true;
    notifyListeners();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(next.difference(now) + const Duration(seconds: 2),
        () {
      recomputeAll(); // statuses roll over at midnight
      _scheduleMidnight();
    });
  }

  /// Re-fold every student's ledger -> monthsCovered/credit (idempotent),
  /// running the auto credit-consume loop. Called at midnight/resume/restore.
  Future<void> recomputeAll() async {
    for (final s in students) {
      await _refoldStudent(s, persist: true);
    }
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    onDataChanged?.call();
  }

  // ================= derived helpers =================

  double cyclePriceOf(int studentId) {
    var sum = 0.0;
    for (final sc in studentCourses.where((e) => e.studentId == studentId)) {
      sum += courseById(sc.courseId)?.fee ?? 0;
    }
    return sum;
  }

  Course? courseById(int id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  Batch? batchById(int id) {
    for (final b in batches) {
      if (b.id == id) return b;
    }
    return null;
  }

  BatchTiming? timingById(int id) {
    for (final t in timings) {
      if (t.id == id) return t;
    }
    return null;
  }

  Plan? planById(int? id) {
    if (id == null) return null;
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<StudentCourse> coursesOf(int studentId) =>
      studentCourses.where((e) => e.studentId == studentId).toList();

  List<LedgerEntry> ledgerOf(int studentId) =>
      ledger.where((e) => e.studentId == studentId).toList();

  List<AttendanceRow> attendanceOf(int studentId) =>
      attendance.where((e) => e.studentId == studentId).toList();

  FeeState feeStateOf(Student s) => FeeState(
        monthsCovered: s.monthsCovered,
        credit: s.credit,
        admissionFeePaidAmount: ledgerOf(s.id)
            .where((e) => e.type == kLedgerAdmissionFee)
            .fold(0.0, (a, e) => a + e.paidAmount),
        ptPaid: s.ptPaid,
      );

  FeeStatus statusOf(Student s, {DateTime? today}) => FeeEngine.status(
        state: feeStateOf(s),
        cyclePrice: cyclePriceOf(s.id),
        admissionFeeAmount: admissionFeeAmount,
        admissionFeeEnabled: s.admissionFeeEnabled,
        admissionDate: s.admissionDate,
        today: today ?? DateTime.now(),
      );

  /// Single realtime bucket for a student (blocked > expired > inactive >
  /// nearExpiry > active). Use [statusOf] for money facts.
  MemberStatus memberStatus(Student s, {DateTime? today}) {
    if (s.isBlocked) return MemberStatus.blocked;
    final st = statusOf(s, today: today);
    if (st.expired) return MemberStatus.expired;
    final now = dateOnly(today ?? DateTime.now());
    final anchor = s.lastVisitDate != null ? dateOnly(s.lastVisitDate!) : dateOnly(s.admissionDate);
    if (now.difference(anchor).inDays > 7) return MemberStatus.inactive;
    if (st.daysLeft <= 7) return MemberStatus.nearExpiry;
    return MemberStatus.active;
  }

  // -------- PT (recharge model: money -> balance, sessions consume it) --------

  double ptBalanceOf(Student s) => PtEngine.balance(
      paid: s.ptPaid, sessionsDone: s.ptSessionsDone, sessionPrice: s.ptSessionPrice);

  int ptSessionsLeft(Student s) => PtEngine.sessionsAvailable(
      paid: s.ptPaid, sessionsDone: s.ptSessionsDone, sessionPrice: s.ptSessionPrice);

  /// Money to top up so the balance covers ~2 more sessions (reminder target).
  double ptRechargeNeed(Student s) => PtEngine.rechargeNeed(
      paid: s.ptPaid, sessionsDone: s.ptSessionsDone, sessionPrice: s.ptSessionPrice);

  bool ptLowOnBalance(Student s) =>
      s.ptSessionPrice > 0 && ptBalanceOf(s) < s.ptSessionPrice * 2;

  bool ptNeedsRecharge(Student s) =>
      s.ptSessionPrice > 0 && ptBalanceOf(s) < s.ptSessionPrice;

  String primaryCourseLine(Student s) {
    final list = coursesOf(s.id);
    if (list.isEmpty) return 'No course';
    StudentCourse sc = list.first;
    for (final e in list) {
      if (e.isPrimary) sc = e;
    }
    final c = courseById(sc.courseId);
    final b = batchById(sc.batchId);
    final t = timingById(sc.timingId);
    return [
      if (c != null) c.name,
      if (b != null) b.name,
      if (b != null && b.daysInfo.isNotEmpty) b.daysInfo,
      if (b != null && b.duration.isNotEmpty) b.duration,
      if (t != null) t.label,
    ].join(' · ');
  }

  bool isPresentToday(Student s) {
    final today = dateOnly(DateTime.now());
    return attendance.any(
        (a) => a.studentId == s.id && dateOnly(a.date) == today);
  }

  bool mobileExists(String mobile, {int? exceptId}) => students.any(
      (s) => s.id != exceptId && (s.mobile == mobile || s.altMobile == mobile));

  // ================= students =================

  Future<String> nextJdNo() async {
    var maxN = 0;
    for (final s in students) {
      final n = int.tryParse(s.jdNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (n > maxN) maxN = n;
    }
    var candidate = 'JD-${(maxN + 1).toString().padLeft(3, '0')}';
    while (students.any((s) => s.jdNo == candidate)) {
      maxN++;
      candidate = 'JD-${(maxN + 1).toString().padLeft(3, '0')}';
    }
    return candidate;
  }

  Future<Student> addStudent(Student s, List<StudentCourse> sc) async {
    s.jdNo = await nextJdNo();
    s.id = await Repos.instance.insertStudent(s);
    for (final e in sc) {
      e.studentId = s.id;
      e.id = await Repos.instance.insertStudentCourse(e);
    }
    students.add(s);
    studentCourses.addAll(sc);
    pulseStudentId = s.id;
    _changed();
    return s;
  }

  Future<void> updateStudent(Student s, {List<StudentCourse>? sc}) async {
    s.updatedAt = DateTime.now();
    await Repos.instance.updateStudent(s);
    if (sc != null) {
      await Repos.instance.deleteStudentCoursesFor(s.id);
      studentCourses.removeWhere((e) => e.studentId == s.id);
      for (final e in sc) {
        e.studentId = s.id;
        e.id = await Repos.instance.insertStudentCourse(e);
      }
      studentCourses.addAll(sc);
    }
    final i = students.indexWhere((e) => e.id == s.id);
    if (i >= 0) students[i] = s;
    _changed();
  }

  /// Deletes a student + cascades. Returns the snapshot for Undo; the caller
  /// must call [undoDelete] within the snackbar window, else [finalizeDelete].
  Future<DeletedStudent> deleteStudent(Student s) async {
    final snap = DeletedStudent(
      student: s,
      courses: coursesOf(s.id),
      ledger: ledgerOf(s.id),
      attendance: attendanceOf(s.id),
      photoPath: s.photoPath,
    );
    await Repos.instance.deleteStudent(s.id);
    students.removeWhere((e) => e.id == s.id);
    studentCourses.removeWhere((e) => e.studentId == s.id);
    ledger.removeWhere((e) => e.studentId == s.id);
    attendance.removeWhere((e) => e.studentId == s.id);
    _changed();
    return snap;
  }

  Future<void> undoDelete(DeletedStudent snap) async {
    final r = Repos.instance;
    await r.insertStudent(snap.student);
    for (final e in snap.courses) {
      await r.insertStudentCourse(e);
    }
    for (final e in snap.ledger) {
      await r.insertLedger(e);
    }
    for (final e in snap.attendance) {
      await r.insertAttendance(e);
    }
    students.add(snap.student);
    students.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    studentCourses.addAll(snap.courses);
    ledger.addAll(snap.ledger);
    attendance.addAll(snap.attendance);
    // Replay ledger -> identical fee numbers as before the delete.
    await _refoldStudent(snap.student, persist: true);
    _changed();
  }

  Future<void> finalizeDelete(DeletedStudent snap) async {
    if (snap.photoPath.isNotEmpty) {
      try {
        final f = File(snap.photoPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> setBlocked(Student s, bool blocked) async {
    s.isBlocked = blocked;
    await updateStudent(s);
  }

  // ================= fees / payments =================

  /// Re-fold ledger -> state, run auto credit-consume, persist. Returns the
  /// number of AUTO_CREDIT_ADJUST entries written.
  Future<int> _refoldStudent(Student s, {bool persist = false}) async {
    final entries = ledgerOf(s.id);
    final state = FeeEngine.replay(entries);
    final price = cyclePriceOf(s.id);
    var wrote = 0;
    final conversions = FeeEngine.autoConsume(state, price);
    for (var i = 0; i < conversions; i++) {
      final e = LedgerEntry(
        studentId: s.id,
        type: kLedgerAutoCredit,
        monthLabel: monthLabel(DateTime.now()),
        cyclePrice: price,
        note: 'Advance adjusted to fees',
        balanceOrCredit: -state.credit,
      );
      e.id = await Repos.instance.insertLedger(e);
      ledger.add(e);
      wrote++;
    }
    s.monthsCovered = state.monthsCovered;
    s.credit = state.credit;
    s.cycleBalance = state.cycleBalance(price);
    s.admissionFeePaid = admissionFeeAmount > 0 &&
        state.admissionFeePaidAmount >= admissionFeeAmount - 0.004;
    s.ptPaid = state.ptPaid;
    if (persist || wrote > 0) await Repos.instance.updateStudent(s);
    return wrote;
  }

  /// Records a payment (admission fee portion + plan portion + discount),
  /// writes ledger entries, refolds state. Returns the saved entries.
  Future<List<LedgerEntry>> addPayment({
    required Student s,
    required double amount, // actual money received
    required double discount, // extra value given free
    required String mode,
    String note = '',
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final state = feeStateOf(s);
    final price = cyclePriceOf(s.id);
    final admissionRemaining = s.admissionFeeEnabled
        ? (admissionFeeAmount - state.admissionFeePaidAmount)
            .clamp(0.0, double.infinity)
        : 0.0;
    final dueBefore = statusOf(s).due;

    final split = FeeEngine.applyPayment(
      state: state,
      amount: amount,
      cyclePrice: price,
      admissionFeeRemaining: admissionRemaining,
      discount: discount,
    );

    final saved = <LedgerEntry>[];
    final r = Repos.instance;

    if (split.toAdmission > 0) {
      final e = LedgerEntry(
        studentId: s.id,
        date: now,
        type: kLedgerAdmissionFee,
        monthLabel: monthLabel(now),
        dueAmount: dueBefore,
        paidAmount: split.toAdmission,
        mode: mode,
        note: 'Admission fee',
      );
      e.id = await r.insertLedger(e);
      saved.add(e);
      ledger.add(e);
    }
    if (split.toPlan > 0 || discount > 0) {
      // Simulate post-payment state for the "Baki/Advance" column.
      final after = FeeEngine.status(
        state: state,
        cyclePrice: price,
        admissionFeeAmount: admissionFeeAmount,
        admissionFeeEnabled: s.admissionFeeEnabled,
        admissionDate: s.admissionDate,
        today: now,
      );
      final bal = after.hasDue ? after.due : -after.advance;
      final e = LedgerEntry(
        studentId: s.id,
        date: now,
        type: kLedgerPayment,
        monthLabel: monthLabel(now),
        dueAmount: dueBefore - split.toAdmission,
        paidAmount: split.toPlan,
        discount: discount,
        balanceOrCredit: bal,
        mode: mode,
        note: note,
        cyclePrice: price,
      );
      e.id = await r.insertLedger(e);
      saved.add(e);
      ledger.add(e);
    }

    // Persist folded state back onto the student row.
    s.monthsCovered = state.monthsCovered;
    s.credit = state.credit;
    s.cycleBalance = state.cycleBalance(price);
    s.admissionFeePaid = admissionFeeAmount > 0 &&
        state.admissionFeePaidAmount >= admissionFeeAmount - 0.004;
    await _refoldStudent(s, persist: true);
    _changed();
    return saved;
  }

  Future<void> changePlan(Student s, int planId) async {
    final p = planById(planId);
    s.planId = planId;
    final e = LedgerEntry(
      studentId: s.id,
      type: kLedgerPlanChange,
      monthLabel: monthLabel(DateTime.now()),
      note: 'Plan changed to ${p?.name ?? '—'}',
    );
    e.id = await Repos.instance.insertLedger(e);
    ledger.add(e);
    await updateStudent(s);
  }

  // ================= attendance =================

  Future<bool> markPresent(Student s) async {
    if (isPresentToday(s)) return false;
    final primary = coursesOf(s.id);
    final row = AttendanceRow(
      studentId: s.id,
      courseId: primary.isEmpty ? 0 : primary.first.courseId,
      date: dateOnly(DateTime.now()),
      markedAt: DateTime.now(),
    );
    row.id = await Repos.instance.insertAttendance(row);
    attendance.insert(0, row);
    s.lastVisitDate = dateOnly(DateTime.now());
    await Repos.instance.updateStudent(s);
    _changed();
    return true;
  }

  /// Removes today's attendance row(s) for [s] (undo a wrong mark).
  Future<void> unmarkPresent(Student s) async {
    final today = dateOnly(DateTime.now());
    final rows = attendance
        .where((a) => a.studentId == s.id && dateOnly(a.date) == today)
        .toList();
    for (final r in rows) {
      await Repos.instance.deleteAttendance(r.id);
      attendance.remove(r);
    }
    _changed();
  }

  /// Students assigned to [batchId] (via their course enrolment).
  List<Student> studentsOfBatch(int batchId) {
    final ids = studentCourses
        .where((e) => e.batchId == batchId)
        .map((e) => e.studentId)
        .toSet();
    return students
        .where((s) => ids.contains(s.id) && !s.isBlocked)
        .toList();
  }

  // ================= personal training =================

  Future<void> recordPtPayment(Student s, double amount, String mode) async {
    final e = LedgerEntry(
      studentId: s.id,
      type: kLedgerPtPayment,
      monthLabel: monthLabel(DateTime.now()),
      dueAmount: ptRechargeNeed(s),
      paidAmount: amount,
      mode: mode,
      note: 'Personal training',
    );
    e.id = await Repos.instance.insertLedger(e);
    ledger.add(e);
    s.ptPaid += amount;
    await Repos.instance.updateStudent(s);
    _changed();
  }

  // ================= catalog =================

  bool courseInUse(int id) => studentCourses.any((e) => e.courseId == id);
  bool batchInUse(int id) => studentCourses.any((e) => e.batchId == id);
  bool timingInUse(int id) => studentCourses.any((e) => e.timingId == id);
  bool planInUse(int id) => students.any((e) => e.planId == id);

  Future<void> saveCourse(Course c) async {
    if (c.id == 0) {
      c.id = await Repos.instance.insertCourse(c);
      courses.add(c);
    } else {
      await Repos.instance.updateCourse(c);
      final i = courses.indexWhere((e) => e.id == c.id);
      if (i >= 0) courses[i] = c;
    }
    _changed();
  }

  Future<String?> deleteCourse(Course c) async {
    if (courseInUse(c.id)) return 'in use';
    await Repos.instance.deleteCourse(c.id);
    courses.removeWhere((e) => e.id == c.id);
    final orphanBatches = batches.where((b) => b.courseId == c.id).toList();
    for (final b in orphanBatches) {
      await Repos.instance.deleteBatch(b.id);
      final orphanTimings = timings.where((t) => t.batchId == b.id).toList();
      for (final t in orphanTimings) {
        await Repos.instance.deleteTiming(t.id);
      }
      timings.removeWhere((t) => t.batchId == b.id);
    }
    batches.removeWhere((b) => b.courseId == c.id);
    _changed();
    return null;
  }

  Future<void> saveBatch(Batch b) async {
    if (b.id == 0) {
      b.id = await Repos.instance.insertBatch(b);
      batches.add(b);
    } else {
      await Repos.instance.updateBatch(b);
      final i = batches.indexWhere((e) => e.id == b.id);
      if (i >= 0) batches[i] = b;
    }
    _changed();
  }

  Future<String?> deleteBatch(Batch b) async {
    if (batchInUse(b.id)) return 'in use';
    await Repos.instance.deleteBatch(b.id);
    batches.removeWhere((e) => e.id == b.id);
    final orphans = timings.where((t) => t.batchId == b.id).toList();
    for (final t in orphans) {
      await Repos.instance.deleteTiming(t.id);
    }
    timings.removeWhere((t) => t.batchId == b.id);
    _changed();
    return null;
  }

  Future<void> saveTiming(BatchTiming t) async {
    if (t.id == 0) {
      t.id = await Repos.instance.insertTiming(t);
      timings.add(t);
    } else {
      await Repos.instance.updateTiming(t);
      final i = timings.indexWhere((e) => e.id == t.id);
      if (i >= 0) timings[i] = t;
    }
    _changed();
  }

  Future<String?> deleteTiming(BatchTiming t) async {
    if (timingInUse(t.id)) return 'in use';
    await Repos.instance.deleteTiming(t.id);
    timings.removeWhere((e) => e.id == t.id);
    _changed();
    return null;
  }

  Future<void> savePlan(Plan p) async {
    if (p.id == 0) {
      p.id = await Repos.instance.insertPlan(p);
      plans.add(p);
    } else {
      await Repos.instance.updatePlan(p);
      final i = plans.indexWhere((e) => e.id == p.id);
      if (i >= 0) plans[i] = p;
    }
    _changed();
  }

  Future<String?> deletePlan(Plan p) async {
    if (planInUse(p.id)) return 'in use';
    await Repos.instance.deletePlan(p.id);
    plans.removeWhere((e) => e.id == p.id);
    _changed();
    return null;
  }

  // ================= settings =================

  Future<void> setTheme(bool dark) async {
    isDark = dark;
    await Repos.instance.setSetting(kPrefTheme, dark ? 'dark' : 'light');
    _changed();
  }

  Future<void> setDeviceLock(bool on) async {
    deviceLockOn = on;
    await Repos.instance.setSetting(kPrefDeviceLock, on ? '1' : '0');
    _changed();
  }

  Future<void> saveStudio(StudioInfo info) async {
    studio = info;
    await Repos.instance.setSetting(kPrefStudio, jsonEncode(info.toJson()));
    _changed();
  }

  Future<void> saveTemplates(Map<String, String> t) async {
    templates = {...kDefaultTemplates, ...t};
    await Repos.instance.setSetting(kPrefTemplates, jsonEncode(templates));
    _changed();
  }

  Future<void> setAdmissionFee(double v) async {
    admissionFeeAmount = v;
    await Repos.instance.setSetting(kPrefAdmissionFee, v.toString());
    await recomputeAll();
    _changed();
  }

  Future<void> setGstInfo({required String gstin, required double rate}) async {
    this.gstin = gstin.trim().toUpperCase();
    gstRate = rate;
    await Repos.instance.setSetting(kPrefGstin, this.gstin);
    await Repos.instance.setSetting(kPrefGstRate, rate.toString());
    _changed();
  }

  Future<void> setPtDefaults(
      {required double sessionPrice,
      required String duration,
      required String days}) async {
    ptDefaultSessionPrice = sessionPrice;
    ptDefaultDuration = duration.trim();
    ptDefaultDays = days.trim();
    await Repos.instance.setSetting(kPrefPtSessionPrice, sessionPrice.toString());
    await Repos.instance.setSetting(kPrefPtDuration, ptDefaultDuration);
    await Repos.instance.setSetting(kPrefPtDays, ptDefaultDays);
    _changed();
  }

  Future<void> setDailyBackup(bool on) async {
    dailyBackupOn = on;
    await Repos.instance.setSetting(kPrefDailyBackup, on ? '1' : '0');
    _changed();
  }

  Future<void> setWifiOnly(bool on) async {
    wifiOnlyBackup = on;
    await Repos.instance.setSetting(kPrefWifiOnly, on ? '1' : '0');
    _changed();
  }

  Future<void> saveBackupMeta(Map<String, Object?> meta) async {
    backupMeta = meta;
    await Repos.instance.setSetting(kPrefBackupMeta, jsonEncode(meta));
    notifyListeners();
  }

  Future<void> setBackupPending(bool pending) async {
    backupPending = pending;
    await Repos.instance.setSetting(kPrefBackupPending, pending ? '1' : '0');
    notifyListeners();
  }

  // ================= backup/restore data =================

  Future<Map<String, Object?>> exportBackup() async {
    final dump = await Repos.instance.dumpAll();
    // Embed every photo as a compact JPEG so restores bring images back too.
    final photos = <String, String>{};
    for (final s in students) {
      if (s.photoPath.isEmpty) continue;
      final b64 = await PhotoService.instance.readAsJpegBase64(s.photoPath);
      if (b64 != null) photos['${s.id}'] = b64;
    }
    if (studio.photoPath.isNotEmpty) {
      final b64 = await PhotoService.instance.readAsJpegBase64(studio.photoPath);
      if (b64 != null) photos['studio'] = b64;
    }
    return {
      'app': kAppName,
      'version': 2,
      'createdAt': DateTime.now().toIso8601String(),
      'counts': {
        for (final e in dump.entries) e.key: e.value.length,
        'photos': photos.length,
      },
      'data': dump,
      'photos': photos,
    };
  }

  /// Replaces the whole database with [data]; returns the previous dump so
  /// the caller can offer Undo. [photos] (base64) are written back to the
  /// photos dir and their paths remapped before caches reload.
  Future<Map<String, List<Map<String, Object?>>>> restoreFromBackup(
      Map<String, List<Map<String, Object?>>> data,
      {Map<String, String>? photos}) async {
    final snapshot = await Repos.instance.dumpAll();
    await Repos.instance.replaceAll(data);
    await _writeRestoredPhotos(data, photos);
    await load(); // reload caches + settings
    await recomputeAll();
    return snapshot;
  }

  Future<void> _writeRestoredPhotos(
      Map<String, List<Map<String, Object?>>> data,
      Map<String, String>? photos) async {
    if (photos == null || photos.isEmpty) return;
    final r = Repos.instance;
    final studioB64 = photos['studio'];
    if (studioB64 != null) {
      final path =
          await PhotoService.instance.writeFromBase64(studioB64, 'studio');
      if (path != null) {
        final studioJson = await r.getSetting(kPrefStudio);
        if (studioJson != null) {
          final info = StudioInfo.fromJson(
              jsonDecode(studioJson) as Map<String, Object?>);
          info.photoPath = path;
          await r.setSetting(kPrefStudio, jsonEncode(info.toJson()));
        }
      }
    }
    for (final row in data['students'] ?? const <Map<String, Object?>>[]) {
      final id = row['id'];
      final b64 = photos['$id'];
      if (id == null || b64 == null) continue;
      final path =
          await PhotoService.instance.writeFromBase64(b64, 'stu_restored');
      if (path != null) await r.updateStudentPhoto(id as int, path);
    }
  }

  Future<void> restoreSnapshot(Map<String, List<Map<String, Object?>>> snap) async {
    await Repos.instance.replaceAll(snap);
    await load();
    await recomputeAll();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}

class DeletedStudent {
  final Student student;
  final List<StudentCourse> courses;
  final List<LedgerEntry> ledger;
  final List<AttendanceRow> attendance;
  final String photoPath;
  const DeletedStudent({
    required this.student,
    required this.courses,
    required this.ledger,
    required this.attendance,
    required this.photoPath,
  });
}
