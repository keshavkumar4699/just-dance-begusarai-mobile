import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';

/// TAB 2 - ATTENDANCE: today view, date filter, course filter,
/// per-student stats (tap a student row).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _date = Dates.todayStr();
  int? _courseFilter;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final isToday = _date == Dates.todayStr();

          final records = state.attendance
              .where((a) => a.date == _date && (_courseFilter == null || a.courseId == _courseFilter))
              .toList()
            ..sort((a, b) => a.markedAt.compareTo(b.markedAt));

          // Group by course.
          final byCourse = <int, List<AttendanceRecord>>{};
          for (final r in records) {
            byCourse.putIfAbsent(r.courseId, () => []).add(r);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Text('Attendance',
                        style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
                    const Spacer(),
                    Text('${records.length} today',
                        style: wt(Theme.of(context).textTheme.labelMedium,
                            weight: 700, color: AppColors.gold)),
                  ],
                ),
              ),
              // Date + course filters
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _dateChip(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _courseChip(),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                  child: Text('Present today',
                      style: wt(Theme.of(context).textTheme.labelSmall,
                          weight: 700, color: AppColors.active)),
                ),
              Expanded(
                child: byCourse.isEmpty
                    ? EmptyState(
                        message: isToday ? 'No one marked present today yet' : 'No attendance on this date',
                        icon: Icons.event_available_outlined,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          for (final entry in byCourse.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 6),
                              child: SectionLabel(state.courseById(entry.key)?.name ?? 'General'),
                            ),
                            for (final r in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _PresentRow(record: r),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dateChip() {
    final scheme = Theme.of(context).colorScheme;
    final isToday = _date == Dates.todayStr();
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: Dates.parse(_date),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          helpText: 'Filter by date',
        );
        if (picked != null) setState(() => _date = Dates.fmt(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 15, color: isToday ? AppColors.gold : AppColors.greyIcon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isToday ? 'Today (${Dates.displayShort(_date)})' : Dates.display(_date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: wt(Theme.of(context).textTheme.labelMedium,
                    weight: 600, color: isToday ? AppColors.gold : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseChip() {
    final state = AppState.instance;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _courseFilter,
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('All courses')),
            for (final c in state.courses) DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _courseFilter = v),
          style: wt(Theme.of(context).textTheme.labelMedium, weight: 600),
        ),
      ),
    );
  }
}

/// One attendance row: photo, name, course chip, time marked, actions.
class _PresentRow extends StatelessWidget {
  final AttendanceRecord record;

  const _PresentRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final s = state.studentById(record.studentId);
    if (s == null) return const SizedBox.shrink();
    final course = state.courseById(record.courseId);
    final time = record.markedAt.isEmpty
        ? ''
        : record.markedAt.length >= 16
            ? record.markedAt.substring(11, 16)
            : '';

    return ScaleTap(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudentAttendanceStats(studentId: s.id!),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Avatar(photoPath: s.photoPath, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: wt(Theme.of(context).textTheme.titleSmall, weight: 700)),
                  Row(
                    children: [
                      if (course != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(course.name,
                              style: wt(Theme.of(context).textTheme.labelSmall,
                                  weight: 700, color: AppColors.gold)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(time.isNotEmpty ? 'marked $time' : '',
                          style: wt(Theme.of(context).textTheme.labelSmall,
                              weight: 500, color: AppColors.greyIcon)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.greyIcon),
              onPressed: () => WhatsAppService.call(s.mobile),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.greyIcon),
              onPressed: () => WhatsAppService.openChat(s.mobile, ''),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-student attendance stats screen (tap a student row in Attendance).
class StudentAttendanceStats extends StatelessWidget {
  final int studentId;

  const StudentAttendanceStats({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final s = state.studentById(studentId);
    if (s == null) {
      return const Scaffold(body: EmptyState(message: 'Student not found', icon: Icons.person_off_outlined));
    }
    final stats = AttendanceStats.compute(s, state.attendanceOf(s), state.today);
    final rate = (stats.rate * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.name} - Attendance',
            style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('OVERVIEW'),
                const SizedBox(height: 10),
                _row('Total sessions attended', '${stats.total}', context: context),
                _row('Expected days', '${stats.expected}', context: context),
                Row(
                  children: [
                    Text('Attendance rate',
                        style: wt(Theme.of(context).textTheme.bodySmall, weight: 500)),
                    const Spacer(),
                    Text('$rate%',
                        style: wt(Theme.of(context).textTheme.titleMedium,
                            weight: 800,
                            color: rate >= 70
                                ? AppColors.active
                                : rate >= 40
                                    ? AppColors.nearExpiry
                                    : AppColors.expired)),
                  ],
                ),
                const SizedBox(height: 6),
                _row('Current streak', '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}', context: context),
                _row('Longest streak', '${stats.longestStreak} day${stats.longestStreak == 1 ? '' : 's'}', context: context),
                _row('Last visit', stats.lastVisit.isEmpty ? 'Never' : Dates.display(stats.lastVisit), context: context),
                _row('First visit', stats.firstVisit.isEmpty ? 'Never' : Dates.display(stats.firstVisit), context: context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Monthly grid (GitHub style)
          for (final month in _recentMonths(6)) ...[
            const SizedBox(height: 12),
            SectionLabel(month.$2),
            const SizedBox(height: 8),
            _MonthGrid(
              monthKey: month.$1,
              present: stats.perMonth[month.$1] ?? const [],
              fromAdmission: Dates.monthKey(s.admissionDate).compareTo(month.$1) <= 0,
            ),
          ],
          const SizedBox(height: 16),
          // Per-course attendance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('BY COURSE'),
                const SizedBox(height: 10),
                for (final entry in stats.perCourse.entries)
                  _row(
                    state.courseById(entry.key)?.name ?? 'Course ${entry.key}',
                    '${entry.value.length} days',
                    context: context,
                  ),
                if (stats.perCourse.isEmpty)
                  Text('No course-wise data',
                      style: wt(Theme.of(context).textTheme.bodySmall,
                          weight: 500, color: AppColors.greyIcon)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Missed days
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('MISSED DAYS (${stats.missed.length})'),
                const SizedBox(height: 10),
                if (stats.missed.isEmpty)
                  Text('Nothing missed - great!',
                      style: wt(Theme.of(context).textTheme.bodySmall,
                          weight: 500, color: AppColors.active))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in stats.missed.take(60))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.expired.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.expired.withValues(alpha: 0.4)),
                          ),
                          child: Text(Dates.displayShort(d),
                              style: wt(Theme.of(context).textTheme.labelSmall,
                                  weight: 600, color: AppColors.expired)),
                        ),
                      if (stats.missed.length > 60)
                        Text('+${stats.missed.length - 60} more',
                            style: wt(Theme.of(context).textTheme.labelSmall,
                                weight: 600, color: AppColors.greyIcon)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _recentMonths(int n) {
    final now = DateTime.now();
    final out = <(String, String)>[];
    for (var i = n - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      out.add((key, Dates.monthLabel('$key-01')));
    }
    return out;
  }

  Widget _row(String k, String v, {Color? color, required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: wt(Theme.of(context).textTheme.bodySmall, weight: 500)),
          ),
          Text(v,
              style: wt(Theme.of(context).textTheme.bodySmall,
                  weight: 700, color: color ?? Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

/// GitHub-style month dot grid.
class _MonthGrid extends StatelessWidget {
  final String monthKey;
  final List<String> present;
  final bool fromAdmission;

  const _MonthGrid({required this.monthKey, required this.present, required this.fromAdmission});

  @override
  Widget build(BuildContext context) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final days = DateTime(year, month + 1, 0).day;
    final set = present.toSet();

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var d = 1; d <= days; d++)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: set.contains('$monthKey-${d.toString().padLeft(2, '0')}')
                  ? AppColors.active
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}
