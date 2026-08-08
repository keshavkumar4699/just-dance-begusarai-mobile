import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class PaymentDialog extends StatefulWidget {
  final Student student;

  const PaymentDialog({Key? key, required this.student}) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late TextEditingController _amountController;
  late TextEditingController _txnRefController;
  late TextEditingController _notesController;

  String _selectedMonthYear = DateFormat('MMM yyyy').format(DateTime.now());
  String _selectedMode = 'UPI';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.student.monthlyFee.toInt().toString());
    _txnRefController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amountPaid = double.tryParse(_amountController.text.trim()) ?? widget.student.monthlyFee;
    final currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final status = amountPaid >= widget.student.monthlyFee ? 'Paid' : 'Partial';

    final entry = LedgerEntry(
      studentId: widget.student.id!,
      monthYear: _selectedMonthYear,
      amountDue: widget.student.monthlyFee,
      amountPaid: amountPaid,
      paymentDate: currentDateStr,
      paymentMode: _selectedMode,
      status: status,
      transactionRef: _txnRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    await _dbHelper.insertLedgerEntry(entry);

    // Update Student Status to Active
    await _dbHelper.updateStudent(
      widget.student.copyWith(status: 'Active'),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);

      // Offer to send WhatsApp receipt
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text('Payment Logged Successfully', style: AppFonts.titleHeader(color: AppColors.gold)),
          content: Text(
            'Would you like to send a digital WhatsApp payment receipt to ${widget.student.name}?',
            style: AppFonts.bodyText(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('SKIP', style: AppFonts.bodyText(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 16),
              label: const Text('SEND RECEIPT'),
              onPressed: () {
                Navigator.pop(ctx);
                WhatsAppService.sendPaymentReceipt(
                  student: widget.student,
                  entry: entry,
                );
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGold, width: 1),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECORD FEE PAYMENT', style: AppFonts.displayHeader(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                "Student: ${widget.student.name}",
                style: AppFonts.subtitleText(color: AppColors.textSecondary),
              ),
              const Divider(color: AppColors.borderSubtle, height: 20),

              // Month Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedMonthYear,
                dropdownColor: AppColors.surface,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Payment Month',
                  prefixIcon: Icon(Icons.calendar_month, color: AppColors.gold),
                ),
                items: [
                  DateFormat('MMM yyyy').format(DateTime.now()),
                  DateFormat('MMM yyyy').format(DateTime.now().subtract(const Duration(days: 30))),
                  DateFormat('MMM yyyy').format(DateTime.now().subtract(const Duration(days: 60))),
                ].map((m) {
                  return DropdownMenuItem(value: m, child: Text(m, style: AppFonts.bodyText()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMonthYear = val);
                },
              ),
              const SizedBox(height: 14),

              // Amount Paid
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee, color: AppColors.gold),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter paid amount' : null,
              ),
              const SizedBox(height: 14),

              // Payment Mode
              DropdownButtonFormField<String>(
                initialValue: _selectedMode,
                dropdownColor: AppColors.surface,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.payment, color: AppColors.gold),
                ),
                items: ['UPI', 'Cash', 'Card', 'Bank Transfer'].map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode, style: AppFonts.bodyText()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMode = val);
                },
              ),
              const SizedBox(height: 14),

              // Transaction Ref
              TextFormField(
                controller: _txnRefController,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'UPI Ref / Receipt No. (Optional)',
                  prefixIcon: Icon(Icons.receipt_long, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitPayment,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: AppColors.background)
                      : Text(
                          'CONFIRM & LOG PAYMENT',
                          style: AppFonts.bodyText(fontWeight: FontWeight.bold, color: AppColors.background),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
