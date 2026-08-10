import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/share_flow.dart';
import '../../services/settings_service.dart';
import '../../services/template_service.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import '../../widgets/member_card.dart';
import '../dialogs/confirm_dialogs.dart';
import '../payment/payment_dialog.dart';
import '../pt/pt_screen.dart';
import '../student/student_detail_screen.dart';

/// TAB 1 - HOME: search, live-count chips, PT section, member cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _filter = 'All';
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final counts = state.chipCounts();

    return SafeArea(
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final visible = _visibleStudents(state);
          return Column(
            children: [
              // ---- App bar: logo mark + title ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 1.1),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Members',
                        style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
                    const Spacer(),
                    Text(
                      state.students.length.toString(),
                      style: wt(Theme.of(context).textTheme.titleLarge,
                          weight: 800, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              // ---- Search ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile or ID...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.greyIcon),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.greyIcon),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                  ),
                ),
              ),
              // ---- Pill chips with live counts ----
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final e in [
                      ('All', state.students.length, AppColors.greyIcon),
                      ('Active', counts['Active'] ?? 0, AppColors.active),
                      ('Inactive', counts['Inactive'] ?? 0, AppColors.inactive),
                      ('Expired', counts['Expired'] ?? 0, AppColors.expired),
                      ('Due', counts['Due'] ?? 0, AppColors.nearExpiry),
                      ('Blocked', counts['Blocked'] ?? 0, AppColors.blocked),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CountChip(
                          label: e.$1,
                          count: e.$2,
                          selected: _filter == e.$1,
                          color: e.$3,
                          onTap: () => setState(() => _filter = e.$1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: state.students.isEmpty
                    ? const EmptyState(
                        message: 'No members yet - tap + to add',
                        icon: Icons.people_outline,
                      )
                    : visible.isEmpty
                        ? const EmptyState(
                            message: 'No members match',
                            icon: Icons.search_off,
                          )
                        : _MemberList(
                            students: visible,
                            onPresent: _markPresent,
                            onShare: _shareIdCard,
                            onCall: _call,
                            onRenew: _renew,
                            onToggleBlock: _toggleBlock,
                            onDelete: _delete,
                            onReminder: _sendReminder,
                            onOpenPt: _openPt,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- data -----------------------------------------------------------------

  List<Student> _visibleStudents(AppState state) {
    var list = state.students.where((s) {
      if (_query.isNotEmpty) {
        final hay = '${s.name} ${s.mobile} ${s.altMobile} ${s.jdNo}'.toLowerCase();
        if (!hay.contains(_query)) return false;
      }
      if (_filter == 'All') return true;
      final st = state.statusFor(s);
      switch (_filter) {
        case 'Active':
          return !s.isBlocked &&
              st.status != MemberStatus.expired &&
              (Dates.daysBetween(DateTime.now(), Dates.parse(s.effectiveLastVisit()))) <= 7;
        case 'Inactive':
          return !s.isBlocked &&
              Dates.daysBetween(DateTime.now(), Dates.parse(s.effectiveLastVisit())) > 7;
        case 'Expired':
          return st.status == MemberStatus.expired;
        case 'Due':
          return st.engineDue > 0 || st.admissionFeeDue > 0;
        case 'Blocked':
          return s.isBlocked;
      }
      return true;
    }).toList();

    // Sort: EXPIRED (most overdue first) -> 1,2 days -> <=1 week -> later.
    list.sort((a, b) {
      final sa = state.statusFor(a);
      final sb = state.statusFor(b);
      int group(StudentStatus s) {
        if (s.status == MemberStatus.expired) return 0;
        if (s.paidTill != null && s.daysLeft <= 7) return 1;
        return 2;
      }

      final ga = group(sa);
      final gb = group(sb);
      if (ga != gb) return ga.compareTo(gb);
      if (ga == 0) return sb.daysOverdue.compareTo(sa.daysOverdue); // most overdue first
      return sa.daysLeft.compareTo(sb.daysLeft); // soonest first
    });
    return list;
  }

  // ---- actions ---------------------------------------------------------------

  Future<bool> _markPresent(Student s) async {
    final ok = await AppState.instance.markPresent(s);
    if (!ok && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Already marked present today')),
      );
    }
    return ok;
  }

  Future<void> _shareIdCard(Student s) async {
    await ShareFlow.shareIdCard(context, s);
  }

  Future<void> _call(Student s) async {
    await WhatsAppService.call(s.mobile);
  }

  Future<void> _renew(Student s) async {
    await PaymentDialog.show(context, student: s, renew: true);
  }

  Future<void> _toggleBlock(Student s) async {
    final ok = await confirmDialog(
      context,
      title: s.isBlocked ? 'Unblock ${s.name}?' : 'Block ${s.name}?',
      message: s.isBlocked
          ? 'The member will be able to use the studio again.'
          : 'Blocked members are hidden from lists and marked with 🚫.',
      confirmLabel: s.isBlocked ? 'Unblock' : 'Block',
    );
    if (!ok || !context.mounted) return;
    await AppState.instance.updateStudent(s..isBlocked = !s.isBlocked);
  }

  Future<void> _delete(Student s) async {
    final ok = await typeNameDeleteDialog(context, s);
    if (!ok || !mounted) return;
    final undo = await AppState.instance.deleteStudent(s);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${s.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => AppState.instance.undoDelete(undo),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _sendReminder(Student s) async {
    final state = AppState.instance;
    final st = state.statusFor(s);
    final template = await SettingsService.instance.templateText(TemplateKeys.feesDue);
    final values = TemplateService.valuesFor(
      student: s,
      studio: state.studio.name,
      address: state.studio.address,
      cyclePrice: st.cyclePrice,
      planName: state.planNameOf(s),
      courseName: state.primaryCourseLine(s),
      paidTill: st.paidTill != null ? Dates.fmt(st.paidTill!) : null,
      due: st.totalDue > 0 ? st.totalDue : st.cyclePrice,
      today: state.today,
    );
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.openChat(s.mobile, text);
    if (!ok && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('No WhatsApp on this number')),
      );
    }
  }

  void _openPt() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PtScreen()));
  }
}

/// The member list with section headers.
class _MemberList extends StatelessWidget {
  final List<Student> students;
  final Future<bool> Function(Student) onPresent;
  final void Function(Student) onShare;
  final void Function(Student) onCall;
  final void Function(Student) onRenew;
  final void Function(Student) onToggleBlock;
  final void Function(Student) onDelete;
  final void Function(Student) onReminder;
  final VoidCallback onOpenPt;

  const _MemberList({
    required this.students,
    required this.onPresent,
    required this.onShare,
    required this.onCall,
    required this.onRenew,
    required this.onToggleBlock,
    required this.onDelete,
    required this.onReminder,
    required this.onOpenPt,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final sections = <String, List<Student>>{
      'EXPIRED': [],
      'ENDING WITHIN 7 DAYS': [],
      'ACTIVE': [],
    };
    for (final s in students) {
      final st = state.statusFor(s);
      if (st.status == MemberStatus.expired) {
        sections['EXPIRED']!.add(s);
      } else if (st.paidTill != null && st.daysLeft <= 7) {
        sections['ENDING WITHIN 7 DAYS']!.add(s);
      } else {
        sections['ACTIVE']!.add(s);
      }
    }

    final items = <Widget>[];
    var entrance = 0;
    final ptCount = state.students.where((s) => s.ptEnabled).length;

    // PT "Archived" style section (only when there are PT students).
    if (ptCount > 0) {
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: _PtSectionRow(count: ptCount, onTap: onOpenPt),
      ));
    }

    for (final sec in ['EXPIRED', 'ENDING WITHIN 7 DAYS', 'ACTIVE']) {
      final list = sections[sec]!;
      if (list.isEmpty) continue;
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: SectionLabel(sec),
      ));
      for (final s in list) {
        final st = state.statusFor(s);
        final idx = entrance++;
        final dup = state.students.where((x) => x.id != s.id && x.mobile.isNotEmpty && x.mobile == s.mobile).isNotEmpty;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _PulseCard(
            studentId: s.id!,
            child: MemberCard(
              entranceIndex: idx,
              student: s,
              status: st,
              courseLine: state.primaryCourseLine(s),
              planName: state.planNameOf(s),
              duplicateMobile: dup,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(student: s),
                ));
              },
              onMarkPresent: () => onPresent(s),
              onShare: () => onShare(s),
              onCall: () => onCall(s),
              onRenew: () => onRenew(s),
              onToggleBlock: () => onToggleBlock(s),
              onDelete: () => onDelete(s),
              onReminder: () => onReminder(s),
            ),
          ),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: items,
    );
  }
}

/// PT row styled like WhatsApp "Archived".
class _PtSectionRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PtSectionRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, size: 19, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Personal Training',
                  style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('$count',
                  style: wt(Theme.of(context).textTheme.labelMedium,
                      weight: 800, color: AppColors.gold)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.greyIcon),
          ],
        ),
      ),
    );
  }
}

/// Pulses a newly added member's card twice with a gold hairline glow.
class _PulseCard extends StatefulWidget {
  final int studentId;
  final Widget child;

  const _PulseCard({required this.studentId, required this.child});

  @override
  State<_PulseCard> createState() => _PulseCardState();
}

class _PulseCardState extends State<_PulseCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _maybePulse();
  }

  @override
  void didUpdateWidget(_PulseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId == widget.studentId) _maybePulse();
  }

  void _maybePulse() {
    final st = AppState.instance;
    if (st.pulseStudentId == widget.studentId) {
      st.clearPulse();
      _c.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) {
          _c.stop();
          _c.value = 1;
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final glow = 0.35 + (0.65 * (1 - _c.value));
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: _c.isAnimating ? glow : 0),
              width: 1.6,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

