/// Just Dance — PT SCREEN (opened from Home, slide-up).
/// All personal-training students with the same IG-post cards; tapping a card
/// opens the PT edit sheet (timing, price, sessions, +1 done, live earnings).
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/invoice_pdf.dart';
import '../../services/share_service.dart';
import '../../services/whatsapp_service.dart';
import '../widgets/common.dart';
import '../widgets/member_card.dart';

class PtScreen extends StatelessWidget {
  final AppStore store;
  const PtScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pts =
            store.students.where((s) => s.ptEnabled && !s.isBlocked).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        int leftOf(Student s) => store.ptSessionsLeft(s);
        final buckets = [
          ('1 SESSION LEFT', (int n) => n <= 1),
          ('3 SESSIONS LEFT', (int n) => n >= 2 && n <= 3),
          ('7 SESSIONS LEFT', (int n) => n >= 4 && n <= 7),
          ('ACTIVE', (int n) => n >= 8),
        ];
        final children = <Widget>[];
        var stagger = 0;
        for (final (label, match) in buckets) {
          final group = pts.where((s) => match(leftOf(s))).toList();
          if (group.isEmpty) continue;
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SectionLabel('$label (${group.length})'),
          ));
          for (final s in group) {
            children.add(MemberCard(
              store: store,
              student: s,
              staggerIndex: stagger++,
            ));
          }
        }
        return Scaffold(
          appBar: AppBar(title: Text('Personal Training (${pts.length})')),
          body: pts.isEmpty
              ? const EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'No personal training students',
                  hint: 'Open a member and tap "Add to Personal Training".',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  children: children,
                ),
        );
      },
    );
  }
}

/// PT edit sheet: timing, charges, sessions, +1 done, live earnings, payment.
Future<void> showPtEditSheet(
    BuildContext context, AppStore store, Student s) async {
  await showAppSheet(
    context,
    PtEditSheet(store: store, studentId: s.id),
  );
}

class PtEditSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  const PtEditSheet({super.key, required this.store, required this.studentId});

  @override
  State<PtEditSheet> createState() => _PtEditSheetState();
}

class _PtEditSheetState extends State<PtEditSheet> {
  late final TextEditingController _timing;
  late final TextEditingController _price;
  late final TextEditingController _sessions;
  late final TextEditingController _payAmount;
  late String _ptDays;
  String _mode = kModeCash;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  @override
  void initState() {
    super.initState();
    _timing = TextEditingController(text: s.ptTiming);
    _price = TextEditingController(
        text: s.ptSessionPrice == 0 ? '' : s.ptSessionPrice.toStringAsFixed(0));
    _sessions = TextEditingController(
        text: s.ptSessions == 0 ? '' : s.ptSessions.toString());
    _payAmount = TextEditingController();
    _ptDays = s.ptDays.isNotEmpty ? s.ptDays : store.ptDefaultDays;
  }

  void _toggleDay(String day) {
    final days = _ptDays.isEmpty
        ? <String>[]
        : _ptDays.split(',').where((e) => e.isNotEmpty).toList();
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    setState(() => _ptDays = days.join(','));
  }

  @override
  void dispose() {
    _timing.dispose();
    _price.dispose();
    _sessions.dispose();
    _payAmount.dispose();
    super.dispose();
  }

  double get _priceVal => double.tryParse(_price.text.trim()) ?? 0;

  double get _balanceVal => s.ptPaid - s.ptSessionsDone * _priceVal;

  String get _balanceText {
    if (_priceVal <= 0) return 'Set a session price to see the balance.';
    final b = _balanceVal;
    final left = b > 0 ? (b / _priceVal).floor() : 0;
    if (b < _priceVal) {
      return 'Recharge needed — ${fmtMoney(_priceVal - b)}';
    }
    if (b < _priceVal * 2) {
      return 'Low balance — ${fmtMoney(b)} · $left session${left == 1 ? '' : 's'} left';
    }
    return 'Balance ${fmtMoney(b)} · $left session${left == 1 ? '' : 's'} left';
  }

  Future<void> _save() async {
    s.ptTiming = _timing.text.trim();
    s.ptDays = _ptDays;
    s.ptSessionPrice = _priceVal;
    s.ptSessions = int.tryParse(_sessions.text.trim()) ?? s.ptSessions;
    await store.updateStudent(s);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _markDone() async {
    s.ptTiming = _timing.text.trim();
    s.ptDays = _ptDays;
    s.ptSessionPrice = _priceVal;
    s.ptSessions = int.tryParse(_sessions.text.trim()) ?? s.ptSessions;
    s.ptSessionsDone += 1;
    await store.updateStudent(s);
    setState(() {});
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_payAmount.text.trim()) ?? 0;
    if (amount <= 0) {
      showSnack(context, 'Recharge amount must be more than ₹0',
          duration: kSnackWarn);
      return;
    }
    s.ptTiming = _timing.text.trim();
    s.ptDays = _ptDays;
    s.ptSessionPrice = _priceVal;
    s.ptSessions = int.tryParse(_sessions.text.trim()) ?? s.ptSessions;
    await store.updateStudent(s);
    await store.recordPtPayment(s, amount, _mode);
    _payAmount.clear();
    setState(() {});
    if (mounted) {
      await showAppSheet(
        context,
        PtRechargeDoneSheet(store: store, studentId: s.id, amount: amount),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.hairline,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Text('${s.name} — Personal Training',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                  color: _priceVal > 0 && _balanceVal < _priceVal * 2
                      ? c.nearExpiry
                      : c.active,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
              child: Text(
                  '$_balanceText  ·  ${s.ptSessionsDone}/${s.ptSessions} sessions'),
            ),
            const FieldLabel('Session timing'),
            TextField(
                controller: _timing,
                decoration: const InputDecoration(hintText: 'e.g. 7–8 AM')),
            const FieldLabel('Days'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _weekDays)
                  ChoiceChip(
                    label: Text(d),
                    selected: _ptDays.split(',').contains(d),
                    onSelected: (_) => _toggleDay(d),
                  ),
              ],
            ),
            const FieldLabel('Charge per session (₹)'),
            TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'e.g. 500')),
            const FieldLabel('Total sessions'),
            TextField(
                controller: _sessions,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'e.g. 12')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: GhostButton('Session Done',
                        icon: Icons.check_circle_outline, onTap: _markDone)),
                const SizedBox(width: 12),
                Expanded(child: GoldButton('Save', onTap: _save)),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: c.hairline),
            const SectionLabel('Recharge balance'),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _payAmount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Amount ₹'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      for (final m in const [kModeCash, kModeUpi])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m),
                            selected: _mode == m,
                            onSelected: (_) => setState(() => _mode = m),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GoldButton('Recharge',
                icon: Icons.currency_rupee, onTap: _recordPayment),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seamless PT <-> Course switching (amounts stay in their own model).

/// Course -> PT: fill the PT details (timing, days, price, optional recharge).
Future<void> showSwitchToPtSheet(
    BuildContext context, AppStore store, Student s) async {
  await showAppSheet(
    context,
    _SwitchToPtSheet(store: store, studentId: s.id),
  );
}

class _SwitchToPtSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  const _SwitchToPtSheet({required this.store, required this.studentId});

  @override
  State<_SwitchToPtSheet> createState() => _SwitchToPtSheetState();
}

class _SwitchToPtSheetState extends State<_SwitchToPtSheet> {
  late final TextEditingController _timing;
  late final TextEditingController _price;
  late final TextEditingController _recharge;
  late String _days;
  String _mode = kModeCash;
  bool _busy = false;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  @override
  void initState() {
    super.initState();
    _timing = TextEditingController(text: s.ptTiming);
    _price = TextEditingController(
        text: (s.ptSessionPrice > 0 ? s.ptSessionPrice : store.ptDefaultSessionPrice) == 0
            ? ''
            : (s.ptSessionPrice > 0 ? s.ptSessionPrice : store.ptDefaultSessionPrice)
                .toStringAsFixed(0));
    _recharge = TextEditingController();
    _days = s.ptDays.isNotEmpty ? s.ptDays : store.ptDefaultDays;
  }

  @override
  void dispose() {
    _timing.dispose();
    _price.dispose();
    _recharge.dispose();
    super.dispose();
  }

  double get _priceVal => double.tryParse(_price.text.trim()) ?? 0;

  int get _allocated =>
      _priceVal > 0 ? (double.tryParse(_recharge.text.trim()) ?? 0) ~/ _priceVal : 0;

  void _toggleDay(String d) {
    final days = _days.isEmpty
        ? <String>[]
        : _days.split(',').where((e) => e.isNotEmpty).toList();
    if (days.contains(d)) {
      days.remove(d);
    } else {
      days.add(d);
    }
    setState(() => _days = days.join(','));
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    s.ptEnabled = true;
    s.ptTiming = _timing.text.trim();
    s.ptDays = _days;
    s.ptSessionPrice = _priceVal;
    await store.updateStudent(s);
    final recharge = double.tryParse(_recharge.text.trim()) ?? 0;
    if (recharge > 0) {
      await store.recordPtPayment(s, recharge, _mode);
    }
    if (mounted) {
      Navigator.pop(context);
      showSnack(context,
          recharge > 0 ? 'Switched to PT — $recharge sessions' : 'Switched to PT',
          duration: kSnackSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch ${s.name} to Personal Training',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Fill the PT details — recharge to allocate sessions.',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            const FieldLabel('Session timing'),
            TextField(
                controller: _timing,
                decoration: const InputDecoration(hintText: 'e.g. 7–8 AM')),
            const FieldLabel('Days'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _weekDays)
                  ChoiceChip(
                    label: Text(d),
                    selected: _days.split(',').contains(d),
                    onSelected: (_) => _toggleDay(d),
                  ),
              ],
            ),
            const FieldLabel('Charge per session (₹)'),
            TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'e.g. 500')),
            const FieldLabel('Recharge amount (₹) — optional'),
            TextField(
                controller: _recharge,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'e.g. 5000')),
            if (_allocated > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '$_allocated session${_allocated == 1 ? '' : 's'} allocated',
                    style: TextStyle(
                        color: c.gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
            const FieldLabel('Recharge mode'),
            Row(
              children: [
                for (final m in const [kModeCash, kModeUpi])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            GoldButton('Switch to PT', icon: Icons.check,
                onTap: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}

/// PT -> Course: pick course/batch/timing/plan (all optional), PT turns off.
Future<void> showSwitchToCourseSheet(
    BuildContext context, AppStore store, Student s) async {
  await showAppSheet(
    context,
    _SwitchToCourseSheet(store: store, studentId: s.id),
  );
}

class _SwitchToCourseSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  const _SwitchToCourseSheet({required this.store, required this.studentId});

  @override
  State<_SwitchToCourseSheet> createState() => _SwitchToCourseSheetState();
}

class _SwitchToCourseSheetState extends State<_SwitchToCourseSheet> {
  int _courseId = 0;
  int _batchId = 0;
  final Set<int> _selectedInterests = {};
  int? _planId;
  bool _busy = false;

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_courseId != 0) {
      final sc = [
        StudentCourse(
            courseId: _courseId,
            batchId: _batchId,
            interests: _selectedInterests.join(','),
            isPrimary: true)
      ];
      s.ptEnabled = false;
      await store.updateStudent(s, sc: sc);
      if (_planId != null && _planId != s.planId) {
        await store.changePlan(s, _planId!);
      }
    } else {
      s.ptEnabled = false;
      await store.updateStudent(s);
    }
    if (mounted) {
      Navigator.pop(context);
      showSnack(context, 'Switched to course', duration: kSnackSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final availableInterests =
        _courseId != 0 ? store.interestsOf(_courseId) : <CourseInterest>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch ${s.name} to Course',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Course details are optional — leave empty to only stop PT.',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            const FieldLabel('Course'),
            AppDropdown<int>(
              value: _courseId == 0 ? null : _courseId,
              hint: 'No course',
              items: [
                for (final course in store.courses)
                  DropdownMenuItem(
                      value: course.id,
                      child: Text(
                          '${course.name} · ${fmtMoney(course.fee)}/mo',
                          overflow: TextOverflow.ellipsis))
              ],
              onChanged: (v) => setState(() {
                _courseId = v ?? 0;
                _batchId = 0;
                _selectedInterests.clear();
              }),
            ),
            if (_courseId != 0) ...[
              const FieldLabel('Batch'),
              AppDropdown<int>(
                value: (_batchId == kBatchWeekend || _batchId == kBatchWeekdays)
                    ? _batchId
                    : null,
                hint: 'Batch',
                items: const [
                  DropdownMenuItem(
                      value: kBatchWeekend,
                      child: Text('Weekend (Sat–Sun, 2 hours)')),
                  DropdownMenuItem(
                      value: kBatchWeekdays,
                      child: Text('Weekdays (Mon–Fri, 1 hour)')),
                ],
                onChanged: (v) => setState(() {
                  _batchId = v ?? 0;
                }),
              ),
              if (availableInterests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Interests',
                    style: TextStyle(color: c.textMuted, fontSize: 11.5)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final interest in availableInterests)
                      FilterChip(
                        label: Text(interest.name),
                        selected: _selectedInterests.contains(interest.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedInterests.add(interest.id);
                          } else {
                            _selectedInterests.remove(interest.id);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ],
            const FieldLabel('Plan'),
            AppDropdown<int>(
              value: _planId,
              hint: store.plans.isEmpty ? 'No plans' : 'No plan',
              items: [
                for (final p in store.plans)
                  DropdownMenuItem(
                      value: p.id,
                      child: Text(
                          '${p.name} · ${p.months}mo${p.discountValue > 0 ? ' · off ${p.discountType == 'percent' ? '${p.discountValue.toStringAsFixed(0)}%' : fmtMoney(p.discountValue)}' : ''}'))
              ],
              onChanged: (v) => setState(() => _planId = v),
            ),
            const SizedBox(height: 18),
            GoldButton('Switch to Course', icon: Icons.check,
                onTap: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}

/// Shown after a PT recharge: WhatsApp reminder + PT invoice (PDF).
class PtRechargeDoneSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  final double amount;
  const PtRechargeDoneSheet(
      {super.key, required this.store, required this.studentId, required this.amount});

  @override
  State<PtRechargeDoneSheet> createState() => _PtRechargeDoneSheetState();
}

class _PtRechargeDoneSheetState extends State<PtRechargeDoneSheet> {
  bool _busy = false;

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  Future<void> _sendReminder() async {
    final msg = WhatsAppService.instance.build(
      kTemplateFeeCollected,
      store,
      s,
      amount: fmtMoney(widget.amount),
    );
    final ok = await WhatsAppService.instance.openChat(s.mobile, msg);
    if (!ok && mounted) showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
  }

  Future<void> _sendInvoice() async {
    if (_busy) return;
    setState(() => _busy = true);
    final entries = store.ledgerOf(s.id);
    final paid = entries
        .where((e) => e.type == kLedgerPtPayment)
        .fold(0.0, (a, e) => a + e.paidAmount);
    final discount = entries.fold(0.0, (a, e) => a + e.discount);
    try {
      final file = await InvoicePdf.instance.generatePtInvoice(
        store: store,
        s: s,
        date: DateTime.now(),
        sessionsAllocated: InvoiceMath.sessionsAllocated(
            paid, s.ptSessionPrice),
        sessionPrice: s.ptSessionPrice,
        discount: discount,
        paid: paid,
        balance: store.ptRechargeNeed(s),
      );
      var ok = await ShareService.instance.documentToWhatsApp(
          mobile: s.mobile,
          path: file.path,
          text: '${s.name}, here is your PT receipt (PDF). – ${store.studio.name}');
      if (!ok) {
        await ShareService.instance
            .shareImage(file.path, text: 'Receipt – ${store.studio.name}');
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Could not create the invoice PDF', duration: kSnackError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final left = store.ptSessionsLeft(s);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: c.hairline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: c.gold, size: 36),
          ),
          const SizedBox(height: 10),
          Text('Recharge saved!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              '${s.name} · ${fmtMoney(widget.amount)} · $left session${left == 1 ? '' : 's'} left',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoldButton('Send Reminder',
                leading: const WhatsAppIcon(size: 18, color: Colors.black),
                onTap: _sendReminder),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: GhostButton(
                _busy ? 'Creating PDF…' : 'Send Invoice (PDF)',
                icon: Icons.receipt_long_outlined,
                onTap: _busy ? null : _sendInvoice,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done',
                style: TextStyle(
                    color: c.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
