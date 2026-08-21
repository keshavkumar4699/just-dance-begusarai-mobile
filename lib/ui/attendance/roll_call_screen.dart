/// Just Dance — ROLL CALL: mark a whole batch present in seconds.
/// Batch picker -> roster with one-tap toggles, Mark-all/Clear-all,
/// live present/absent counts, and one-tap WhatsApp reminders for
/// absentees. Marks today only (history stays on the Attendance tab).
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/whatsapp_service.dart';
import '../widgets/common.dart';

class RollCallScreen extends StatefulWidget {
  final AppStore store;
  const RollCallScreen({super.key, required this.store});

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen> {
  String _filterKey = 'all'; // 'all' or '<courseId>_<batchId>'

  AppStore get store => widget.store;

  List<Student> get _roster {
    if (_filterKey == 'all') {
      return store.students.where((s) => !s.isBlocked).toList();
    }
    final parts = _filterKey.split('_');
    if (parts.length != 2) {
      return store.students.where((s) => !s.isBlocked).toList();
    }
    final cid = int.tryParse(parts[0]) ?? 0;
    final bid = int.tryParse(parts[1]) ?? 0;

    final studentIds = store.studentCourses
        .where((sc) => sc.courseId == cid && sc.batchId == bid)
        .map((sc) => sc.studentId)
        .toSet();

    return store.students
        .where((s) => studentIds.contains(s.id) && !s.isBlocked)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final roster = _roster..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final present = roster.where((s) => store.isPresentToday(s)).toList();
    final absent = roster.where((s) => !store.isPresentToday(s)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roll Call'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Today',
                  style: TextStyle(color: c.gold, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: AppDropdown<String>(
              value: _filterKey,
              hint: 'All students',
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All students')),
                for (final course in store.courses) ...[
                  DropdownMenuItem(
                      value: '${course.id}_$kBatchWeekend',
                      child: Text('${course.name} — Weekend (Sat–Sun, 2h)',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: '${course.id}_$kBatchWeekdays',
                      child: Text('${course.name} — Weekdays (Mon–Fri, 1h)',
                          overflow: TextOverflow.ellipsis)),
                ],
              ],
              onChanged: (v) => setState(() => _filterKey = v ?? 'all'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
            child: Row(
              children: [
                Expanded(
                  child: _countChip(c, '${present.length} present', c.active,
                      icon: Icons.check_circle_outline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _countChip(c, '${absent.length} not present',
                      absent.isEmpty ? c.active : c.expired,
                      icon: Icons.person_off_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: GoldButton('Mark all present',
                      icon: Icons.done_all,
                      onTap: absent.isEmpty
                          ? null
                          : () async {
                              for (final s in absent) {
                                await store.markPresent(s);
                              }
                            }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GhostButton('Clear all',
                      icon: Icons.undo,
                      onTap: present.isEmpty
                          ? null
                          : () async {
                              for (final s in present) {
                                await store.unmarkPresent(s);
                              }
                            }),
                ),
              ],
            ),
          ),
          Expanded(
            child: roster.isEmpty
                ? EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No students here',
                    hint: _filterKey == 'all'
                        ? 'Add members first.'
                        : 'No students assigned to this course batch yet.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    children: [
                      for (final s in roster) _rosterRow(c, s),
                      if (absent.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SectionLabel('Not present — remind on WhatsApp'),
                        for (final s in absent) _absentRow(c, s),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(AppColors c, String text, Color color,
          {required IconData icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _rosterRow(AppColors c, Student s) {
    final here = store.isPresentToday(s);
    return Pressable(
      onTap: () async {
        if (here) {
          await store.unmarkPresent(s);
        } else {
          await store.markPresent(s);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: here ? c.active.withValues(alpha: 0.08) : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: here ? c.active.withValues(alpha: 0.35) : c.hairline),
        ),
        child: Row(
          children: [
            SquircleAvatar(photoPath: s.photoPath, name: s.name, size: 40, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${s.jdNo} · ${store.primaryCourseLine(s)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Motion.fast,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: here ? c.active : Colors.transparent,
                border: Border.all(
                    color: here ? c.active : c.textMuted, width: 1.6),
              ),
              child: here
                  ? const Icon(Icons.check, size: 17, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _absentRow(AppColors c, Student s) {
    final st = store.statusOf(s);
    final msg = st.hasDue
        ? WhatsAppService.instance
            .build(kTemplateFeesDue, store, s, due: fmtMoney(st.due))
        : 'Hi ${s.name.split(' ').first}! You missed today\'s session at ${store.studio.name}. See you soon! – ${store.studio.name}';
    return Pressable(
      onTap: () async {
        final ok = await WhatsAppService.instance.openChat(s.mobile, msg);
        if (!ok && mounted) {
          showSnack(context, 'No WhatsApp on this number',
              duration: kSnackWarn);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            WhatsAppIcon(size: 17, color: c.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Text('Remind',
                style: TextStyle(
                    color: c.gold, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
