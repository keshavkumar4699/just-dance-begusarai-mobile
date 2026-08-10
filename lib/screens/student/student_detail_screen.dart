import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/photo_service.dart';
import '../../services/settings_service.dart';
import '../../services/template_service.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import '../../widgets/id_card_widget.dart';
import '../add/add_details_form.dart';
import '../dialogs/confirm_dialogs.dart';
import '../payment/payment_dialog.dart';
import '../pt/pt_edit_sheet.dart';

/// STUDENT DETAIL - ID card top, details grouped, ledger table, actions.
class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final int _studentId = widget.student.id!;
  Student get _student => AppState.instance.studentById(_studentId) ?? widget.student;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(_student.name,
            style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expired),
            onPressed: _delete,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final student = _student;
          final status = state.statusFor(student);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              // ---- ID card ----
              Center(
                child: IdCardWidget(
                  student: student,
                  studio: state.studio,
                  status: status,
                  courseLine: state.primaryCourseLine(student),
                  planName: state.planNameOf(student),
                ),
              ),
              const SizedBox(height: 18),
              // ---- Action buttons ----
              _actionGrid(student, status),
              const SizedBox(height: 18),
              // ---- Dues summary ----
              _duesCard(student, status),
              const SizedBox(height: 18),
              // ---- Attendance summary ----
              _attendanceCard(student),
              const SizedBox(height: 18),
              // ---- Details grouped ----
              _detailsCard(student),
              const SizedBox(height: 18),
              // ---- Payment history (realtime ledger) ----
              _ledgerCard(student),
              // ---- PT section ----
              _ptCard(student),
            ],
          );
        },
      ),
    );
  }

  // =============================================================================
  // ACTIONS
  // =============================================================================
  Widget _actionGrid(Student s, StudentStatus st) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn(Icons.add_card_outlined, 'Payment', () => _payment(s))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.autorenew, 'Renew', () => _renew(s))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.chat_bubble_outline, 'WhatsApp', () => _whatsapp(s))),
          ],
        ),
        const SizedBox(width: 0, height: 8),
        Row(
          children: [
            Expanded(child: _actionBtn(Icons.badge_outlined, 'Share ID', () => _shareId(s))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.call_outlined, 'Call', () => _call(s))),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                Icons.check_circle_outline,
                'Present',
                () => _present(s),
                accent: AppColors.active,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                s.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                s.isBlocked ? 'Unblock' : 'Block',
                () => _toggleBlock(s),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                s.ptEnabled ? Icons.fitness_center : Icons.fitness_center_outlined,
                s.ptEnabled ? 'Remove from PT' : 'Add to PT',
                () => _togglePt(s),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                Icons.edit_outlined,
                'Edit',
                _edit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color? accent}) {
    final scheme = Theme.of(context).colorScheme;
    final c = accent ?? AppColors.gold;
    return ScaleTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: scheme.outline.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: wt(Theme.of(context).textTheme.labelSmall,
                    weight: 600, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Future<void> _payment(Student s) => PaymentDialog.show(context, student: s);
  Future<void> _renew(Student s) => PaymentDialog.show(context, student: s, renew: true);

  Future<void> _whatsapp(Student s) async {
    final state = AppState.instance;
    final st = state.statusFor(s);
    final template = await SettingsService.instance.templateText(TemplateKeys.welcome);
    final values = TemplateService.valuesFor(
      student: s,
      studio: state.studio.name,
      address: state.studio.address,
      cyclePrice: st.cyclePrice,
      planName: state.planNameOf(s),
      courseName: state.primaryCourseLine(s),
      paidTill: st.paidTill != null ? Dates.fmt(st.paidTill!) : null,
      due: 0,
      today: state.today,
    );
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.openChat(s.mobile, text);
    if (!ok && mounted) _snack('No WhatsApp on this number');
  }

  Future<void> _shareId(Student s) async {
    final state = AppState.instance;
    final st = state.statusFor(s);
    final jpeg = await DocumentService.renderToJpeg(
      IdCardWidget(
        student: s,
        studio: state.studio,
        status: st,
        courseLine: state.primaryCourseLine(s),
        planName: state.planNameOf(s),
      ),
      size: const Size(360, 560),
    );
    if (jpeg == null) {
      _snack('Could not create ID card image');
      return;
    }
    final ok = await WhatsAppService.shareImageToWhatsApp(
      filePath: jpeg,
      mobile: s.mobile,
      text: '${s.name} - ID card',
    );
    if (!ok) await WhatsAppService.shareFile(jpeg, text: '${s.name} - ID card');
  }

  Future<void> _call(Student s) async {
    await WhatsAppService.call(s.mobile);
  }

  Future<void> _present(Student s) async {
    final ok = await AppState.instance.markPresent(s);
    if (!ok && mounted) {
      _snack('Already marked present today');
    } else if (mounted) {
      _snack('Marked present today');
    }
  }

  Future<void> _toggleBlock(Student s) async {
    final ok = await confirmDialog(
      context,
      title: s.isBlocked ? 'Unblock ${s.name}?' : 'Block ${s.name}?',
      message: s.isBlocked
          ? 'The member will be able to use the studio again.'
          : 'Blocked members are marked with 🚫 and hidden from most lists.',
      confirmLabel: s.isBlocked ? 'Unblock' : 'Block',
    );
    if (!ok || !mounted) return;
    await AppState.instance.updateStudent(s..isBlocked = !s.isBlocked);
  }

  Future<void> _togglePt(Student s) async {
    if (s.ptEnabled) {
      final ok = await confirmDialog(
        context,
        title: 'Remove ${s.name} from PT?',
        message: 'PT sessions and timing will be cleared.',
        confirmLabel: 'Remove',
      );
      if (!ok || !mounted) return;
      await AppState.instance.savePt(s, enabled: false, sessions: 0, price: 0, timing: '');
    } else {
      await _editPt(s);
    }
  }

  Future<void> _editPt(Student s) async {
    // PT edit sheet: timing, price, sessions.
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PtEditSheet(student: s),
    );
    if (result == true && mounted) _snack('PT saved');
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddDetailsForm(existing: _student),
    ));
  }

  Future<void> _delete() async {
    final s = _student;
    final ok = await typeNameDeleteDialog(context, s);
    if (!ok || !mounted) return;
    final undo = await AppState.instance.deleteStudent(s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${s.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => AppState.instance.undoDelete(undo),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =============================================================================
  // CARDS
  // =============================================================================
  Widget _duesCard(Student s, StudentStatus st) {
    return _card(
      'DUES SUMMARY',
      Column(
        children: [
          _kv('Monthly cycle', Money.fmt(st.cyclePrice)),
          _kv('Membership paid', Money.fmt(st.membershipPaid)),
          _kv('Months covered', '${st.monthsCovered}'),
          _kv('Paid till', st.paidTill != null ? Dates.display(Dates.fmt(st.paidTill!)) : '--'),
          _kv('Membership due', Money.fmt(st.engineDue), red: st.engineDue > 0),
          _kv('Admission fee due', Money.fmt(st.admissionFeeDue), red: st.admissionFeeDue > 0),
          _kv('Advance / credit', Money.fmt(st.credit), green: st.credit > 0),
          const Divider(height: 18),
          Row(
            children: [
              Text('TOTAL DUE',
                  style: wt(Theme.of(context).textTheme.labelSmall,
                      weight: 700, color: st.totalDue > 0 ? AppColors.expired : AppColors.active)),
              const Spacer(),
              Text(Money.fmt(st.totalDue),
                  style: wt(Theme.of(context).textTheme.titleMedium,
                      weight: 800, color: st.totalDue > 0 ? AppColors.expired : AppColors.active)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard(Student s) {
    final stats = AttendanceStats.compute(s, AppState.instance.attendanceOf(s), AppState.instance.today);
    final rate = (stats.rate * 100).round();
    final rateColor = rate >= 70 ? AppColors.active : (rate >= 40 ? AppColors.nearExpiry : AppColors.expired);
    return _card(
      'ATTENDANCE SUMMARY',
      Column(
        children: [
          _kv('Last visit', stats.lastVisit.isEmpty ? 'Never' : Dates.display(stats.lastVisit)),
          _kv('Total present', '${stats.total} of ${stats.expected} expected'),
          Row(
            children: [
              Text('Attendance rate',
                  style: wt(Theme.of(context).textTheme.bodySmall, weight: 500)),
              const Spacer(),
              Text('$rate%',
                  style: wt(Theme.of(context).textTheme.titleMedium,
                      weight: 800, color: rateColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(Student s) {
    final state = AppState.instance;
    return _card(
      'DETAILS',
      Column(
        children: [
          _kv('ID No', s.jdNo),
          _kv('Father\'s name', s.fatherName),
          _kv('Mother\'s name', s.motherName),
          _kv('Mobile', s.mobile),
          if (s.altMobile.isNotEmpty) _kv('Alt mobile', s.altMobile),
          _kv('DOB', s.dob.isEmpty ? '--' : Dates.display(s.dob)),
          _kv('Gender', s.gender),
          if (s.aadhar.isNotEmpty) _kv('Aadhar', s.aadhar),
          _kv('Religion', s.religion),
          _kv('Nationality', s.nationality),
          _kv('Marital status', s.maritalStatus),
          _kv('Admission date', Dates.display(s.admissionDate)),
          if (s.lastVisitDate.isNotEmpty) _kv('Last visit', Dates.display(s.lastVisitDate)),
          _kv('Primary course', state.primaryCourseLine(s).isEmpty ? '--' : state.primaryCourseLine(s)),
          _kv('Permanent address', [s.permVillage, s.permPO, s.permDist, s.permPin].where((e) => e.isNotEmpty).join(', ')),
          if (!s.corrSame)
            _kv('Correspondence', [s.corrVillage, s.corrPO, s.corrDist, s.corrPin].where((e) => e.isNotEmpty).join(', ')),
        ],
      ),
    );
  }

  Widget _ledgerCard(Student s) {
    final entries = AppState.instance.ledgerOf(s).reversed.toList();
    if (entries.isEmpty) {
      return _card('PAYMENT HISTORY', const EmptyState(
          message: 'No payments yet', icon: Icons.receipt_long_outlined));
    }
    return _card(
      'PAYMENT HISTORY',
      Column(
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(Dates.displayShort(e.date),
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 600, color: AppColors.greyIcon)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_typeLabel(e.type),
                            style: wt(Theme.of(context).textTheme.bodySmall, weight: 600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (e.note.isNotEmpty)
                          Text(e.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: wt(Theme.of(context).textTheme.labelSmall,
                                  weight: 500, color: AppColors.greyIcon)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Money.fmt(e.paidAmount),
                          style: wt(Theme.of(context).textTheme.bodySmall,
                              weight: 700,
                              color: e.paidAmount > 0
                                  ? AppColors.active
                                  : Theme.of(context).colorScheme.onSurface)),
                      Text(
                        e.balanceOrCredit > 0
                            ? 'Adv ${Money.fmt(e.balanceOrCredit)}'
                            : e.balanceOrCredit < 0
                                ? 'Baki ${Money.fmt(e.balanceOrCredit.abs())}'
                                : e.mode,
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 500,
                            color: e.balanceOrCredit > 0
                                ? AppColors.active
                                : e.balanceOrCredit < 0
                                    ? AppColors.expired
                                    : AppColors.greyIcon),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        LedgerType.payment => 'Payment',
        LedgerType.admissionFeePaid => 'Admission fee',
        LedgerType.autoCreditAdjust => 'Advance used',
        LedgerType.ptPayment => 'PT payment',
        LedgerType.planChange => 'Plan change',
        LedgerType.note => 'Note',
        _ => type,
      };

  Widget _ptCard(Student s) {
    if (!s.ptEnabled) return const SizedBox.shrink();
    final earnings = s.ptEarnings;
    return _card(
      'PERSONAL TRAINING',
      Column(
        children: [
          _kv('Sessions', '${s.ptSessionsDone} of ${s.ptSessions} done'),
          _kv('Timing', s.ptTiming.isEmpty ? '--' : s.ptTiming),
          _kv('Session price', Money.fmt(s.ptSessionPrice)),
          _kv('Paid', Money.fmt(s.ptPaid)),
          Row(
            children: [
              Text('Earnings',
                  style: wt(Theme.of(context).textTheme.bodySmall, weight: 500)),
              const Spacer(),
              Text(Money.fmt(earnings),
                  style: wt(Theme.of(context).textTheme.titleMedium,
                      weight: 800,
                      color: earnings >= 0 ? AppColors.active : AppColors.expired)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool red = false, bool green = false}) {
    Color? c;
    if (red) c = AppColors.expired;
    if (green) c = AppColors.active;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(k,
                style: wt(Theme.of(context).textTheme.bodySmall,
                    weight: 500, color: AppColors.greyIcon)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: wt(Theme.of(context).textTheme.bodySmall, weight: 600, color: c)),
          ),
        ],
      ),
    );
  }
}

