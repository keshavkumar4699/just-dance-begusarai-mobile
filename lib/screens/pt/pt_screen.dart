import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/share_flow.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import '../../widgets/member_card.dart';
import 'pt_edit_sheet.dart';

/// PT SCREEN - all personal training students, IG-post cards + PT line.
/// Tap a card -> PT edit sheet (timing, charges, mark complete, live earnings).
class PtScreen extends StatefulWidget {
  const PtScreen({super.key});

  @override
  State<PtScreen> createState() => _PtScreenState();
}

class _PtScreenState extends State<PtScreen> {
  Future<void> _openEdit(Student s) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PtEditSheet(student: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Training',
            style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final pts = state.students.where((s) => s.ptEnabled).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          if (pts.isEmpty) {
            return const EmptyState(
              message: 'No PT students yet - add from Student Details',
              icon: Icons.fitness_center_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: pts.length,
            itemBuilder: (context, i) {
              final s = pts[i];
              final st = state.statusFor(s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MemberCard(
                  student: s,
                  status: st,
                  courseLine: state.primaryCourseLine(s),
                  planName: state.planNameOf(s),
                  entranceIndex: i,
                  contentLineOverride:
                      '${s.ptSessionsDone}/${s.ptSessions} sessions • ${s.ptTiming.isEmpty ? 'no timing' : s.ptTiming} • Due ${Money.fmt(s.ptSessionsDone * s.ptSessionPrice - s.ptPaid)}',
                  onTap: () => _openEdit(s),
                  onMarkPresent: () async {
                    final ok = await state.markPresent(s);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Already marked present today')),
                      );
                    }
                    return ok;
                  },
                  onShare: () => ShareFlow.shareIdCard(context, s),
                  onCall: () => _call(s),
                  onRenew: () {},
                  onToggleBlock: () {},
                  onDelete: () {},
                  onReminder: () => _openEdit(s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _call(Student s) async {
    await WhatsAppService.call(s.mobile);
  }
}
