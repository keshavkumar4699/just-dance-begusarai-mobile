import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/student.dart';
import '../../../models/plan.dart';
import '../../../services/fee_engine.dart';
import '../../../database/repositories/ledger_repository.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../app/widgets/app_button.dart';

class RenewDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onSaved;

  const RenewDialog({
    super.key,
    required this.student,
    required this.onSaved,
  });

  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _paymentMode = 'Cash'; // Cash, UPI
  final DateTime _paymentDate = DateTime.now();
  bool _sendWhatsAppMsg = true;
  bool _isSaving = false;
  double _cyclePrice = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadPlanPrice();
  }

  Future<void> _loadPlanPrice() async {
    final plans = await SettingsRepository().getPlans();
    final match = plans.firstWhere(
      (p) => p.name.toLowerCase() == widget.student.plan.toLowerCase(),
      orElse: () => Plan.defaults.first,
    );
    if (mounted) {
      setState(() {
        _cyclePrice = match.finalPrice;
        _amountController.text = _cyclePrice.toStringAsFixed(0);
      });
    }
  }

  Future<void> _savePayment() async {
    if (_isSaving) return;
    final paid = double.tryParse(_amountController.text.trim());
    if (paid == null || paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi amount darj karein')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await LedgerRepository().recordPayment(
        student: widget.student,
        paidAmount: paid,
        cyclePrice: _cyclePrice,
        paymentMode: _paymentMode,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        paymentDate: _paymentDate,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();

        if (_sendWhatsAppMsg) {
          _openWhatsAppFeeMsg(paid);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment save nahi ho saka. Dobara try karein.')),
        );
      }
    }
  }

  Future<void> _openWhatsAppFeeMsg(double paidAmount) async {
    final eval = FeeEngine.evaluateStudent(widget.student);
    final paidTillStr = '${eval.paidTill.day}/${eval.paidTill.month}/${eval.paidTill.year}';
    final text = '✅ ${widget.student.name} ji, fees ₹${paidAmount.toStringAsFixed(0)} mil gayi. Ab valid till: $paidTillStr. Dhanyavad! – Studio Crow';

    final cleanMobile = widget.student.mobile.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    final eval = FeeEngine.evaluateStudent(widget.student);
    final enteredPaid = double.tryParse(_amountController.text.trim()) ?? 0.0;

    // Realtime Breakdown Calculation
    final admissionDue = (widget.student.admissionFeeEnabled && !widget.student.admissionFeePaid) ? 500.0 : 0.0;
    final currentDue = eval.dueAmount;
    final advanceCredit = eval.creditAmount;
    final netDue = (admissionDue + currentDue + _cyclePrice) - advanceCredit;

    // Live preview post-save
    final previewCredit = enteredPaid > _cyclePrice ? (enteredPaid - _cyclePrice) : 0.0;
    final previewDue = enteredPaid < _cyclePrice ? (_cyclePrice - enteredPaid) : 0.0;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEE PAYMENT & RENEW',
                      style: AppTypography.microLabel(AppColors.champagneGold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.student.name,
                      style: AppTypography.headingSmall(primaryTextColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Realtime Financial Breakdown Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANCIAL BREAKDOWN',
                    style: AppTypography.microLabel(secondaryTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admission ₹${admissionDue.toStringAsFixed(0)} + Plan ₹${_cyclePrice.toStringAsFixed(0)} − Advance ₹${advanceCredit.toStringAsFixed(0)} = Net Due ₹${netDue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount Input Field
            Text('Paid Amount (₹)*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryTextColor),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.champagneGold, fontWeight: FontWeight.w700),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.champagneGold)),
              ),
            ),

            const SizedBox(height: 14),

            // Mode Selection (Cash / UPI)
            Text('Payment Mode*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
            const SizedBox(height: 6),
            Row(
              children: ['Cash', 'UPI'].map((mode) {
                final isSelected = _paymentMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMode = mode),
                    child: Container(
                      margin: EdgeInsets.only(right: mode == 'Cash' ? 8.0 : 0.0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.champagneGold : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.champagneGold : borderColor, width: 1),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.darkBackground : primaryTextColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Notes Field
            Text('Note (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: TextStyle(fontSize: 13, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'e.g. Monthly fee payment',
                hintStyle: TextStyle(fontSize: 12, color: secondaryTextColor),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              ),
            ),

            const SizedBox(height: 14),

            // Live Preview Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.champagneGoldMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Save ke baad: ${previewDue > 0 ? "₹${previewDue.toStringAsFixed(0)} baki" : (previewCredit > 0 ? "+₹${previewCredit.toStringAsFixed(0)} advance credit" : "PAID fully")}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.champagneGold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Optional Fee Collected WhatsApp checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fee Collected msg 🟢 (WhatsApp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _sendWhatsAppMsg,
              activeColor: AppColors.champagneGold,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => setState(() => _sendWhatsAppMsg = val ?? true),
            ),

            const SizedBox(height: 16),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Payment',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _savePayment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
