import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';

/// PT edit sheet: session timing, charges, no. of sessions, mark complete,
/// PT payment, live earnings (earnings = done x price - ptPaid).
class PtEditSheet extends StatefulWidget {
  final Student student;

  const PtEditSheet({super.key, required this.student});

  @override
  State<PtEditSheet> createState() => _PtEditSheetState();
}

class _PtEditSheetState extends State<PtEditSheet> {
  late final TextEditingController _timing = TextEditingController(text: widget.student.ptTiming);
  late final TextEditingController _price = TextEditingController(
      text: widget.student.ptSessionPrice == 0 ? '' : '${widget.student.ptSessionPrice}');
  late final TextEditingController _sessions = TextEditingController(
      text: widget.student.ptSessions == 0 ? '' : '${widget.student.ptSessions}');
  late final TextEditingController _ptPay = TextEditingController();
  String _mode = 'Cash';
  bool _saving = false;

  /// Always-fresh student (updates after mark-session taps).
  Student get _s => AppState.instance.studentById(widget.student.id!) ?? widget.student;

  @override
  void dispose() {
    _timing.dispose();
    _price.dispose();
    _sessions.dispose();
    _ptPay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final s = _s;
        final scheme = Theme.of(context).colorScheme;
        final price = int.tryParse(_price.text) ?? s.ptSessionPrice;
        final earnings = s.ptSessionsDone * price - s.ptPaid;
        final due = s.ptSessionsDone > 0 ? earnings.clamp(0, 1 << 31) : 0;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(photoPath: s.photoPath, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                            Text(s.jdNo,
                                style: wt(Theme.of(context).textTheme.labelSmall,
                                    weight: 700, color: AppColors.gold)),
                          ],
                        ),
                      ),
                      Text('Due ${Money.fmt(due > 0 ? due : 0)}',
                          style: wt(Theme.of(context).textTheme.labelMedium,
                              weight: 700, color: due > 0 ? AppColors.expired : AppColors.active)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _timing,
                    decoration: const InputDecoration(isDense: true, labelText: 'Session timing'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration:
                              const InputDecoration(isDense: true, labelText: 'Session price (₹)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _sessions,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration:
                              const InputDecoration(isDense: true, labelText: 'Total sessions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _stat('Done', '${s.ptSessionsDone} / ${s.ptSessions}')),
                      const SizedBox(width: 10),
                      Expanded(child: _stat('Paid', Money.fmt(s.ptPaid))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat('Earnings', Money.fmt(earnings),
                            color: earnings >= 0 ? AppColors.active : AppColors.expired),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ScaleTap(
                      onTap: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              await AppState.instance.markPtSession(_s);
                              if (mounted) setState(() => _saving = false);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: _s.ptSessionsDone >= _s.ptSessions
                              ? Text('All sessions done',
                                  style: wt(Theme.of(context).textTheme.labelMedium,
                                      weight: 700, color: AppColors.active))
                              : Text('Mark session complete (+1)',
                                  style: wt(Theme.of(context).textTheme.labelMedium,
                                      weight: 700, color: AppColors.gold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ptPay,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration:
                              const InputDecoration(isDense: true, labelText: 'PT payment (₹)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _mode,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        ],
                        onChanged: (v) => setState(() => _mode = v ?? 'Cash'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ScaleTap(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final pay = int.tryParse(_ptPay.text) ?? 0;
                        if (pay > 0) {
                          await AppState.instance.recordPtPayment(_s, pay, _mode);
                        }
                        await AppState.instance.savePt(
                          _s,
                          sessions: int.tryParse(_sessions.text) ?? _s.ptSessions,
                          price: int.tryParse(_price.text) ?? _s.ptSessionPrice,
                          timing: _timing.text.trim(),
                        );
                        if (mounted) navigator.pop(true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text('Save PT',
                              style: wt(Theme.of(context).textTheme.labelLarge,
                                  weight: 800, color: AppColors.darkBg)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 600, color: AppColors.greyIcon)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: wt(Theme.of(context).textTheme.titleMedium,
                  weight: 800, color: color ?? scheme.onSurface)),
        ],
      ),
    );
  }
}
