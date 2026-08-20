/// Just Dance — TAB 2: ATTENDANCE.
/// Full record (insert-only). Date + course filters, grouped-by-course view,
/// one-tap call/WhatsApp from the row, per-student stats page.
library;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/whatsapp_service.dart';
import '../widgets/common.dart';
import 'roll_call_screen.dart';
import 'student_attendance_stats.dart';

class AttendanceTab extends StatefulWidget {
  final AppStore store;
  const AttendanceTab({super.key, required this.store});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _date = DateTime.now();
  int _courseFilter = 0; // 0 = all

  AppStore get store => widget.store;

  bool get _isToday => dateOnly(_date) == dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rows = store.attendance
        .where((a) =>
            dateOnly(a.date) == dateOnly(_date) &&
            (_courseFilter == 0 || a.courseId == _courseFilter))
        .toList()
      ..sort((a, b) => b.markedAt.compareTo(a.markedAt));

    // Group by course (preserve course order by name).
    final groups = <int, List<AttendanceRow>>{};
    for (final r in rows) {
      groups.putIfAbsent(r.courseId, () => []).add(r);
    }
    final courseIds = groups.keys.toList()
      ..sort((a, b) => (store.courseById(a)?.name ?? '')
          .compareTo(store.courseById(b)?.name ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: GoldButton('Mark Roll Call',
                icon: Icons.fact_check_outlined,
                onTap: () => Navigator.push(
                    context, fadeSlideRoute(RollCallScreen(store: store)))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.hairline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 17, color: c.gold),
                          const SizedBox(width: 8),
                          Text(
                            _isToday
                                ? 'Today'
                                : fmtDate(_date, forceYear: true),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          const Spacer(),
                          Text('${rows.length} present',
                              style: TextStyle(
                                  color: c.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.hairline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _courseFilter,
                      dropdownColor: c.surface,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: c.textMuted, size: 18),
                      items: [
                        const DropdownMenuItem(
                            value: 0, child: Text('All courses')),
                        for (final course in store.courses)
                          DropdownMenuItem(
                              value: course.id,
                              child: Text(course.name,
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) =>
                          setState(() => _courseFilter = v ?? 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: _isToday
                        ? 'No one marked present yet'
                        : 'No attendance on this date',
                    hint:
                        'Mark a batch in one go with Roll Call, or use the slider on a member card.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      for (final cid in courseIds) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: SectionLabel(
                              '${store.courseById(cid)?.name ?? 'General'} (${groups[cid]!.length})'),
                        ),
                        for (var i = 0; i < groups[cid]!.length; i++)
                          _row(c, groups[cid]![i], i),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppColors c, AttendanceRow a, int index) {
    final s = store.students.where((e) => e.id == a.studentId).firstOrNull;
    if (s == null) return const SizedBox.shrink();
    final expected = daysBetween(s.admissionDate, DateTime.now()) + 1;
    final total = store.attendanceOf(s.id).length;
    final rate = expected <= 0 ? 0.0 : (total / expected).clamp(0.0, 1.0);
    final rateColor = rate >= 0.75
        ? c.active
        : rate >= 0.4
            ? c.nearExpiry
            : c.expired;

    return StaggerIn(
      index: index,
      child: Pressable(
        onTap: () => Navigator.push(
            context,
            fadeSlideRoute(
                StudentAttendanceStats(store: store, studentId: s.id))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.hairline),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SquircleAvatar(
                        photoPath: s.photoPath, name: s.name, size: 40, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text(
                            'marked ${TimeOfDay.fromDateTime(a.markedAt).format(context)}',
                            style: TextStyle(
                                color: c.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: () async {
                        final ok =
                            await WhatsAppService.instance.call(s.mobile);
                        if (!ok && mounted) {
                          showSnack(context, 'Could not open the dialer', duration: kSnackError);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.call_outlined,
                            size: 19, color: c.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: () async {
                        final msg = WhatsAppService.instance
                            .build(kTplFor(s), store, s);
                        final ok = await WhatsAppService.instance
                            .openChat(s.mobile, msg);
                        if (!ok && mounted) {
                          showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: WhatsAppIcon(size: 19, color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              // attendance-rate strip (color coded)
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: rate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: rateColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String kTplFor(Student s) =>
      store.statusOf(s).hasDue ? 'feesDue' : 'welcome';
}
