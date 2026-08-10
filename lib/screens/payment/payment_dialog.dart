import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/fee_engine.dart';
import '../../services/settings_service.dart';
import '../../services/template_service.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import '../dialogs/confirm_dialogs.dart';

/// Payment / Renew dialog with realtime breakdown + live preview.
///
/// Breakdown: Admission + {n} months - Advance - Discount = Due.
/// After save: optional one-tap "Fee Collected" WhatsApp message.
class PaymentDialog {
  static Future<void> show(
    BuildContext context, {
    required Student student,
    bool renew = false,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialogBody(student: student, renew: renew),
    );
  }
}

class _PaymentDialogBody extends StatefulWidget {
  final Student student;
  final bool renew;

  const _PaymentDialogBody({required this.student, required this.renew});

  @override
  State<_PaymentDialogBody> createState() => _PaymentDialogBodyState();
}

class _PaymentDialogBodyState extends State<_PaymentDialogBody> {
  late final AppState _state = AppState.instance;
  late StudentStatus _st;
  late final Plan? _plan;

  late int _months;
  late String _discountType;
  late int _discountValue;
  int _paid = 0;
  String _mode = 'Cash';
  late String _date;
  String _note = '';

  bool _withAdmission = false;
  int _admissionPaid = 0;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plan = _state.planById(widget.student.planId);
    _st = _state.statusFor(widget.student);
    _months = _plan?.months ?? 1;
    _discountType = _plan?.discountType ?? '%';
    _discountValue = _plan?.discountValue ?? 0;
    _date = _state.today;
  }

  // ---- computed -----------------------------------------------------------

  int get _base => _st.cyclePrice * _months;
  int get _discount => FeeEngine.applyDiscount(_base, _discountType, _discountValue);
  int get _cycleDue => _base - _discount;
  int get _advanceUsed {
    if (_st.credit <= 0) return 0;
    return _cycleDue > _st.credit ? _st.credit : _cycleDue;
  }

  int get _effectiveDue => _cycleDue - _advanceUsed;
  int get _admissionDue => _withAdmission && !widget.student.admissionFeePaid ? _state.admissionFeeAmount : 0;
  int get _totalDue => _effectiveDue + _admissionDue;
  int get _balance => _paid - _totalDue;


  // ---- save ---------------------------------------------------------------

  Future<void> _save() async {
    if (_saving) return;
    if (_paid < 0) {
      _snack('Amount cannot be negative');
      return;
    }
    if (_paid == 0 && _totalDue > 0 && !_withAdmission) {
      _snack('Enter the amount collected');
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final res = await _state.recordPayment(
      widget.student,
      months: _months,
      discountType: _discountType,
      discountValue: _discountValue,
      paid: _paid,
      mode: _mode,
      date: _date,
      note: _note,
      withAdmission: _withAdmission,
      admissionPaid: _admissionPaid,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    // Optional one-tap "Fee Collected" message.
    final navigator = Navigator.of(context);
    final sendMsg = await _askSendFeeCollected();
    navigator.pop();
    if (!mounted) return;
    _snack(res.message);
    if (sendMsg && mounted) {
      await _sendFeeCollected(res.status);
    }
  }

  Future<bool> _askSendFeeCollected() async {
    if (_paid <= 0) return false;
    return confirmDialog(
      context,
      title: 'Send confirmation?',
      message: 'Send the "Fee Collected" message to ${widget.student.name} on WhatsApp?',
      confirmLabel: 'Send',
    );
  }

  Future<void> _sendFeeCollected(StudentStatus? status) async {
    final s = widget.student;
    final paidTill = status?.paidTill;
    final template = await SettingsService.instance.templateText(TemplateKeys.feeCollected);
    final values = TemplateService.valuesFor(
      student: s,
      studio: _state.studio.name,
      address: _state.studio.address,
      cyclePrice: _st.cyclePrice,
      planName: _state.planNameOf(s),
      courseName: _state.primaryCourseLine(s),
      paidTill: paidTill != null ? Dates.fmt(paidTill) : null,
      due: 0,
      today: _state.today,
    )..['amount'] = Money.fmt(_paid);
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.openChat(s.mobile, text);
    if (!ok && mounted) {
      _snack('No WhatsApp on this number');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.renew ? 'Renew ${widget.student.name}' : 'Payment - ${widget.student.name}',
                          style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                      Text(widget.student.jdNo,
                          style: wt(Theme.of(context).textTheme.labelSmall,
                              weight: 700, color: AppColors.gold)),
                    ],
                  ),
                  const Spacer(),
                  ScaleTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 20, color: AppColors.greyIcon),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Months + plan chip
                    Row(
                      children: [
                        Expanded(
                          child: _monthsPicker(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _modePicker(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Discount row
                    Row(
                      children: [
                        Text('Discount',
                            style: wt(Theme.of(context).textTheme.labelMedium, weight: 600)),
                        const Spacer(),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: '₹', label: Text('₹')),
                            ButtonSegment(value: '%', label: Text('%')),
                          ],
                          selected: {_discountType},
                          onSelectionChanged: (s) => setState(() => _discountType = s.first),
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            selectedForegroundColor: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 88,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            initialValue: _discountValue == 0 ? '' : '$_discountValue',
                            onChanged: (v) => setState(() {
                              _discountValue = int.tryParse(v) ?? 0;
                              if (_discountType == '%' && _discountValue > 100) {
                                _discountValue = 100;
                              }
                            }),
                            decoration: const InputDecoration(isDense: true, hintText: '0'),
                          ),
                        ),
                      ],
                    ),
                    if (_discountType == '%' && _discountValue > 100)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Percent capped at 100%',
                            style: wt(Theme.of(context).textTheme.bodySmall,
                                weight: 500, color: AppColors.expired)),
                      ),
                    const SizedBox(height: 14),
                    // Admission fee option
                    if (!widget.student.admissionFeePaid && _state.admissionFeeAmount > 0)
                      Row(
                        children: [
                          Checkbox(
                            value: _withAdmission,
                            activeColor: AppColors.gold,
                            onChanged: (v) => setState(() => _withAdmission = v ?? false),
                          ),
                          Expanded(
                            child: Text('Admission fee ${Money.fmt(_state.admissionFeeAmount)}',
                                style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500)),
                          ),
                          if (_withAdmission)
                            SizedBox(
                              width: 100,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (v) =>
                                    setState(() => _admissionPaid = int.tryParse(v) ?? 0),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Paid ${Money.fmt(_state.admissionFeeAmount)}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    // Paid amount
                    _amountField('Amount paid', _paid, (v) => setState(() => _paid = v)),
                    const SizedBox(height: 6),
                    _amountField('Admission fee paid', _admissionPaid, (v) => setState(() => _admissionPaid = v),
                        hidden: !_withAdmission),
                    const SizedBox(height: 10),
                    // Date
                    Row(
                      children: [
                        Expanded(
                          child: _datePicker(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _note = v),
                            decoration: const InputDecoration(
                                isDense: true, hintText: 'Note (optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Live breakdown (realtime preview)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BREAKDOWN',
                              style: wt(Theme.of(context).textTheme.labelSmall,
                                  weight: 700, color: AppColors.greyIcon)),
                          const SizedBox(height: 8),
                          _breakdownRow('Admission', _admissionDue),
                          _breakdownRow('$_months month${_months == 1 ? '' : 's'} (${Money.fmt(_base)})',
                              _base - _discount),
                          if (_advanceUsed > 0)
                            _breakdownRow('Advance used', -_advanceUsed, negative: true),
                          if (_discount > 0) _breakdownRow('Discount', -_discount, negative: true),
                          const Divider(height: 18),
                          _breakdownRow('Due', _totalDue, bold: true),
                          _breakdownRow('Paid', _paid, bold: true, green: true),
                          _breakdownRow(_balance >= 0 ? 'Advance' : 'Baki', _balance.abs(),
                              bold: true, red: _balance < 0, green: _balance > 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Live preview line
                    _LivePreview(
                      student: widget.student,
                      months: _months,
                      discountType: _discountType,
                      discountValue: _discountValue,
                      paid: _paid,
                      withAdmission: _withAdmission,
                      admissionPaid: _admissionPaid,
                    ),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: SizedBox(
                width: double.infinity,
                child: ScaleTap(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _saving ? AppColors.gold.withValues(alpha: 0.5) : AppColors.gold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg),
                          )
                        : Text('Save Payment',
                            style: wt(Theme.of(context).textTheme.labelLarge,
                                weight: 800, color: AppColors.darkBg)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- small builders -------------------------------------------------------

  Widget _monthsPicker() {
    final months = [1, 2, 3, 4, 6, 12];
    return DropdownButtonFormField<int>(
      initialValue: months.contains(_months) ? _months : 1,
      items: [for (final m in months) DropdownMenuItem(value: m, child: Text('$m month${m == 1 ? '' : 's'}'))],
      onChanged: (v) => setState(() => _months = v ?? 1),
      decoration: const InputDecoration(isDense: true, labelText: 'Months'),
    );
  }

  Widget _modePicker() {
    return DropdownButtonFormField<String>(
      initialValue: _mode,
      items: const [
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
      ],
      onChanged: (v) => setState(() => _mode = v ?? 'Cash'),
      decoration: const InputDecoration(isDense: true, labelText: 'Mode'),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: Dates.parse(_date),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Select date',
        );
        if (picked != null) setState(() => _date = Dates.fmt(picked));
      },
      child: InputDecorator(
        decoration: const InputDecoration(isDense: true, labelText: 'Date'),
        child: Text(Dates.display(_date),
            style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500)),
      ),
    );
  }

  Widget _amountField(String label, int value, ValueChanged<int> onChanged, {bool hidden = false}) {
    if (hidden) return const SizedBox.shrink();
    return TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        prefixText: '₹ ',
        prefixStyle: wt(Theme.of(context).textTheme.bodyMedium, weight: 700, color: AppColors.gold),
      ),
    );
  }

  Widget _breakdownRow(String label, int amount, {bool bold = false, bool negative = false, bool green = false, bool red = false}) {
    final scheme = Theme.of(context).colorScheme;
    Color? c;
    if (red) c = AppColors.expired;
    if (green) c = AppColors.active;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: wt(Theme.of(context).textTheme.bodySmall,
                    weight: bold ? 700 : 500,
                    color: c ?? scheme.onSurface.withValues(alpha: 0.85))),
          ),
          Text(
            '${negative ? '-' : ''}${Money.fmt(amount.abs())}',
            style: wt(Theme.of(context).textTheme.bodyMedium,
                weight: bold ? 800 : 600, color: c),
          ),
        ],
      ),
    );
  }
}

/// "After save: PAID till {date} / ₹X due / ₹X advance" - updates per keystroke.
class _LivePreview extends StatelessWidget {
  final Student student;
  final int months;
  final String discountType;
  final int discountValue;
  final int paid;
  final bool withAdmission;
  final int admissionPaid;

  const _LivePreview({
    required this.student,
    required this.months,
    required this.discountType,
    required this.discountValue,
    required this.paid,
    required this.withAdmission,
    required this.admissionPaid,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final st = state.statusFor(student);
    final cycle = st.cyclePrice;
    final base = cycle * months;
    final disc = FeeEngine.applyDiscount(base, discountType, discountValue);
    final due = base - disc;
    var credit = st.credit;
    final advUsed = credit > 0 ? (due > credit ? credit : due) : 0;
    credit -= advUsed;
    final newCovered = cycle > 0 ? ((st.membershipPaid + paid + advUsed) ~/ cycle) : 0;
    final paidTill = cycle > 0 ? Dates.addMonths(Dates.parse(student.admissionDate), newCovered) : null;

    var newDue = 0;
    if (paidTill != null && paidTill.isBefore(DateTime.now())) {
      final overdue = Dates.monthsBetween(paidTill, DateTime.now());
      if (overdue > 0) newDue = overdue * cycle;
    }
    if (withAdmission && !student.admissionFeePaid) {
      newDue += state.admissionFeeAmount - admissionPaid;
      if (newDue < 0) newDue = 0;
    }
    newDue -= credit;
    if (newDue < 0) newDue = 0;

    final text = paidTill != null
        ? 'After save: PAID till ${Dates.display(Dates.fmt(paidTill))} / ${newDue > 0 ? '${Money.fmt(newDue)} due' : 'no dues'} / ${credit > 0 ? '${Money.fmt(credit)} advance' : 'no advance'}'
        : 'After save: no membership cycle';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: wt(Theme.of(context).textTheme.bodySmall, weight: 600, color: AppColors.gold),
      ),
    );
  }
}
