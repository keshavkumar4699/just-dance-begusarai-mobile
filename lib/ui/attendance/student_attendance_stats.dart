/// Just Dance — per-student attendance stats: totals, rate, streaks,
/// first/last visit, missed days, GitHub-style month grids, per-course split.
library;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

class StudentAttendanceStats extends StatelessWidget {
  final AppStore store;
  final int studentId;
  const StudentAttendanceStats(
      {super.key, required this.store, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = store.students.firstWhere((e) => e.id == studentId);
    final rows = store.attendanceOf(studentId);
    final days = rows.map((e) => dateOnly(e.date)).toSet().toList()..sort();

    final total = days.length;
    final expected = daysBetween(s.admissionDate, DateTime.now()) + 1;
    final rate = expected <= 0 ? 0.0 : (total / expected).clamp(0.0, 1.0);
    final (current, longest) = _streaks(days.toSet());
    final missed = _missedDays(s, days.toSet());

    return Scaffold(
      appBar: AppBar(title: Text('${s.name} — Attendance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // headline stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.hairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(context, 'Total', '$total'),
                _stat(context, 'Rate', '${(rate * 100).toStringAsFixed(0)}%',
                    color: rate >= 0.75
                        ? c.active
                        : rate >= 0.4
                            ? c.nearExpiry
                            : c.expired),
                _stat(context, 'Streak', '$current 🔥'),
                _stat(context, 'Best', '$longest'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.hairline),
            ),
            child: Column(
              children: [
                _kv(c, 'Last visit',
                    days.isEmpty ? 'Never' : fmtDate(days.last, forceYear: true)),
                _kv(c, 'First visit',
                    days.isEmpty ? '—' : fmtDate(days.first, forceYear: true)),
                _kv(c, 'Missed days', '${missed.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Last 3 months'),
          const SizedBox(height: 8),
          for (var m = 2; m >= 0; m--) _monthGrid(c, days.toSet(), m),
          const SizedBox(height: 16),
          const SectionLabel('Per course'),
          const SizedBox(height: 8),
          _perCourse(c, rows),
          const SizedBox(height: 16),
          if (missed.isNotEmpty) ...[
            SectionLabel('Missed days (${missed.length})'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in missed.take(30))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.expired.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(fmtDate(d),
                        style: TextStyle(color: c.expired, fontSize: 11.5)),
                  ),
                if (missed.length > 30)
                  Text('+${missed.length - 30} more',
                      style: TextStyle(color: c.textMuted, fontSize: 11.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  (int, int) _streaks(Set<DateTime> days) {
    if (days.isEmpty) return (0, 0);
    // Longest streak
    final sorted = days.toList()..sort();
    var longest = 1, run = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    // Current streak: consecutive days ending today or yesterday.
    var current = 0;
    var cursor = dateOnly(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return (current, longest);
  }

  List<DateTime> _missedDays(Student s, Set<DateTime> present) {
    final missed = <DateTime>[];
    var cursor = dateOnly(s.admissionDate);
    final today = dateOnly(DateTime.now());
    while (!cursor.isAfter(today)) {
      if (!present.contains(cursor)) missed.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return missed.reversed.toList(); // most recent first
  }

  Widget _stat(BuildContext context, String k, String v, {Color? color}) =>
      Column(
        children: [
          Text(k.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        ],
      );

  Widget _kv(AppColors c, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(k,
                    style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            Text(v,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  /// GitHub-style mini month grid: one dot per day, gold = present.
  Widget _monthGrid(AppColors c, Set<DateTime> present, int monthsAgo) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - monthsAgo, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = month.weekday % 7; // Sunday-first grid
    final cells = firstWeekday + daysInMonth;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(monthLabel(month),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4),
            itemCount: cells,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox.shrink();
              final day = i - firstWeekday + 1;
              final d = DateTime(month.year, month.month, day);
              final isFuture = d.isAfter(dateOnly(now));
              final wasPresent = present.contains(d);
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wasPresent
                      ? c.gold
                      : isFuture
                          ? Colors.transparent
                          : c.surface2,
                  border: isFuture
                      ? Border.all(color: c.hairline, width: 0.5)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _perCourse(AppColors c, List<AttendanceRow> rows) {
    final counts = <int, int>{};
    for (final r in rows) {
      counts[r.courseId] = (counts[r.courseId] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return Text('No attendance yet',
          style: TextStyle(color: c.textMuted, fontSize: 13));
    }
    final total = rows.length;
    return Column(
      children: [
        for (final e in counts.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                      store.courseById(e.key)?.name ?? 'General',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : e.value / total,
                      minHeight: 6,
                      backgroundColor: c.surface2,
                      valueColor: AlwaysStoppedAnimation(c.gold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.value}',
                    style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}
