/// Just Dance — PAYMENT / RENEW dialog.
/// Realtime breakdown "Admission ₹X + n months ₹Y − Advance ₹Z − Discount ₹D
/// = Due ₹A", ₹/% discount toggle, live after-save preview, then a
/// confirmation sheet with WhatsApp reminder + PDF invoice.
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/fee_engine.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/invoice_pdf.dart';
import '../../services/share_service.dart';
import '../../services/whatsapp_service.dart';
import '../widgets/common.dart';

Future<void> showPaymentDialog(BuildContext context, AppStore store, Student s,
    {bool renew = false}) async {
  final paid = await showAppSheet<double>(
    context,
    PaymentDialog(store: store, studentId: s.id, renew: renew),
  );
  if (paid == null || !context.mounted) return;
  await showAppSheet(
    context,
    PaymentDoneSheet(store: store, studentId: s.id, paid: paid),
  );
}

class PaymentDialog extends StatefulWidget {
  final AppStore store;
  final int studentId;
  final bool renew;
  const PaymentDialog(
      {super.key, required this.store, required this.studentId, this.renew = false});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _discount;
  late final TextEditingController _note;
  bool _discountPercent = false;
  String _mode = kModeCash;
  late DateTime _date;
  int? _planId;
  bool _userEditedAmount = false;

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _discount = TextEditingController();
    _note = TextEditingController();
    _date = DateTime.now();
    _planId = s.planId ?? (store.plans.isEmpty ? null : store.plans.first.id);
    _applySuggestion();
  }

  @override
  void dispose() {
    _amount.dispose();
    _discount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _months => store.planById(_planId)?.months ?? 1;
  double get _price => store.cyclePriceOf(s.id);

  double get _discountValue {
    final raw = double.tryParse(_discount.text.trim()) ?? 0;
    if (raw <= 0) return 0;
    final gross = _grossPayable;
    final d = _discountPercent ? gross * raw / 100 : raw;
    return d.clamp(0.0, gross);
  }

  double get _grossPayable {
    final st = store.statusOf(s);
    if (widget.renew) {
      // Admission (if pending) + n months - advance already in hand.
      return (st.admissionDue + _months * _price - st.advance)
          .clamp(0.0, double.infinity);
    }
    return st.due; // settle whatever is due today
  }

  double get _suggested =>
      (_grossPayable - _discountValue).clamp(0.0, double.infinity);

  void _applySuggestion() {
    if (_userEditedAmount) return;
    final v = _suggested;
    _amount.text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
  }

  /// Simulated after-save preview.
  FeeStatus _preview() {
    final state = store.feeStateOf(s);
    final paid = double.tryParse(_amount.text.trim()) ?? 0;
    final admissionRemaining = s.admissionFeeEnabled
        ? (store.admissionFeeAmount - state.admissionFeePaidAmount)
            .clamp(0.0, double.infinity)
        : 0.0;
    FeeEngine.applyPayment(
      state: state,
      amount: paid,
      cyclePrice: _price,
      admissionFeeRemaining: admissionRemaining,
      discount: _discountValue,
    );
    return FeeEngine.status(
      state: state,
      cyclePrice: _price,
      admissionFeeAmount: store.admissionFeeAmount,
      admissionFeeEnabled: s.admissionFeeEnabled,
      admissionDate: s.admissionDate,
      today: _date,
    );
  }

  String? get _amountError =>
      validateAmount(_amount.text, required: _discountValue <= 0);

  String? get _discountError => validateDiscount(_discount.text,
      isPercent: _discountPercent, due: _grossPayable);

  Future<void> _save() async {
    if (_amountError != null || _discountError != null) {
      setState(() {}); // surface inline errors
      return;
    }
    final paid = double.tryParse(_amount.text.trim()) ?? 0;
    await store.addPayment(
      s: s,
      amount: paid,
      discount: _discountValue,
      mode: _mode,
      note: _note.text.trim(),
      date: _date,
    );
    if (widget.renew && _planId != null && _planId != s.planId) {
      await store.changePlan(s, _planId!);
    }
    if (!mounted) return;
    Navigator.pop(context, paid);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final st = store.statusOf(s);
    final preview = _preview();

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
            Text(widget.renew ? 'Renew ${s.name}' : 'Payment — ${s.name}',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),

            // Live breakdown strip
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.hairline),
              ),
              child: Text(
                'Admission ${fmtMoney(st.admissionDue)}  +  $_months ${plural(_months)} ${fmtMoney(_months * _price)}  −  Advance ${fmtMoney(st.advance)}  −  Discount ${fmtMoney(_discountValue)}  =  Due ${fmtMoney(_suggested)}',
                style: TextStyle(
                    color: c.text, fontSize: 12.5, height: 1.5),
              ),
            ),

            if (widget.renew) ...[
              const FieldLabel('Plan'),
              AppDropdown<int>(
                value: _planId,
                hint: 'Select plan',
                items: [
                  for (final p in store.plans)
                    DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} · ${p.months} ${plural(p.months)}'))
                ],
                onChanged: (v) => setState(() {
                  _planId = v;
                  _userEditedAmount = false;
                  _applySuggestion();
                }),
              ),
            ],

            const FieldLabel('Discount'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {
                      _userEditedAmount = false;
                      _applySuggestion();
                    }),
                    decoration: InputDecoration(
                      hintText: '0',
                      errorText: _discountError,
                      prefixText: _discountPercent ? '' : '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  constraints:
                      const BoxConstraints(minWidth: 52, minHeight: 44),
                  isSelected: [!_discountPercent, _discountPercent],
                  onPressed: (i) => setState(() {
                    _discountPercent = i == 1;
                    _userEditedAmount = false;
                    _applySuggestion();
                  }),
                  children: const [
                    Text('₹', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('%', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),

            const FieldLabel('Paid amount'),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _userEditedAmount = true),
              decoration: InputDecoration(
                  hintText: '0', prefixText: '₹ ', errorText: _amountError),
            ),

            const FieldLabel('Mode'),
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

            const FieldLabel('Date'),
            DateField(
              value: _date,
              hint: 'Pick date',
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onPicked: (d) => setState(() => _date = d),
            ),

            const FieldLabel('Note (optional)'),
            TextField(
                controller: _note,
                decoration:
                    const InputDecoration(hintText: 'e.g. paid by father')),

            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (preview.hasDue ? c.nearExpiry : c.active)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (preview.hasDue ? c.nearExpiry : c.active)
                        .withValues(alpha: 0.3)),
              ),
              child: Text(
                preview.hasDue
                    ? 'After save: ${fmtMoney(preview.due)} due · paid till ${fmtDate(preview.paidTill, forceYear: true)}'
                    : preview.advance > 0
                        ? 'After save: PAID till ${fmtDate(preview.paidTill, forceYear: true)} · ${fmtMoney(preview.advance)} advance'
                        : 'After save: PAID till ${fmtDate(preview.paidTill, forceYear: true)}',
                style: TextStyle(
                    color: preview.hasDue ? c.nearExpiry : c.active,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5),
              ),
            ),

            const SizedBox(height: 16),
            GoldButton(
              widget.renew ? 'Save Renewal' : 'Save Payment',
              icon: Icons.check,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown right after a payment is saved: WhatsApp reminder + PDF invoice.
class PaymentDoneSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  final double paid;
  const PaymentDoneSheet(
      {super.key, required this.store, required this.studentId, required this.paid});

  @override
  State<PaymentDoneSheet> createState() => _PaymentDoneSheetState();
}

class _PaymentDoneSheetState extends State<PaymentDoneSheet> {
  bool _busy = false;

  AppStore get store => widget.store;
  Student get s => store.students.firstWhere((e) => e.id == widget.studentId);

  Future<void> _sendReminder() async {
    final msg = WhatsAppService.instance.build(
      kTemplateFeeCollected,
      store,
      s,
      amount: fmtMoney(widget.paid),
    );
    final ok = await WhatsAppService.instance.openChat(s.mobile, msg);
    if (!ok && mounted) showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
  }

  Future<void> _sendInvoice() async {
    if (_busy) return;
    setState(() => _busy = true);
    final st = store.statusOf(s);
    final plan = store.planById(s.planId);
    final entries = store.ledgerOf(s.id);
    final paidTotal = entries
        .where((e) =>
            e.type == kLedgerPayment || e.type == kLedgerAdmissionFee)
        .fold(0.0, (a, e) => a + e.paidAmount);
    final discount = entries.fold(0.0, (a, e) => a + e.discount);
    final months = plan?.months ?? 1;
    final planPrice = st.cyclePrice * months;
    try {
      final file = await InvoicePdf.instance.generateCourseInvoice(
        store: store,
        s: s,
        date: DateTime.now(),
        courseLine: store.primaryCourseLine(s),
        planName: plan?.name ?? '',
        monthsAllocated: months,
        validTill: st.paidTill,
        admissionFee:
            s.admissionFeeEnabled && s.admissionFeePaid ? store.admissionFeeAmount : 0,
        planPrice: planPrice,
        discount: discount,
        paid: paidTotal,
        balance: st.due,
      );
      var ok = await ShareService.instance.documentToWhatsApp(
          mobile: s.mobile,
          path: file.path,
          text: '${s.name}, here is your receipt (PDF). – ${store.studio.name}');
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
    final st = store.statusOf(s);
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
          Text('Payment saved!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              '${s.name} · ${fmtMoney(widget.paid)} · paid till ${fmtDate(st.paidTill, forceYear: true)}',
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

String plural(int months) => months == 1 ? 'month' : 'months';
