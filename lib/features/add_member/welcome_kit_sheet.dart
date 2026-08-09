import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../services/id_card_service.dart';
import '../../services/invoice_service.dart';
import '../../services/fee_engine.dart';
import '../../app/widgets/app_button.dart';

class WelcomeKitSheet extends StatelessWidget {
  final Student student;
  final double initialPaid;

  const WelcomeKitSheet({
    super.key,
    required this.student,
    required this.initialPaid,
  });

  Future<void> _openWhatsAppWelcome() async {
    final eval = FeeEngine.evaluateStudent(student);
    final validTillStr = '${eval.paidTill.day}/${eval.paidTill.month}/${eval.paidTill.year}';
    final text = '🎉 Welcome ${student.name} ji! Studio Crow family me swagat hai. ID No: ${student.jdNo}. Plan: ${student.plan}. Valid till: $validTillStr. – Rahul Raja Sir 🕺';

    final cleanMobile = student.mobile.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.celebration, color: AppColors.champagneGold, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member Jud Gaya 🎉',
                        style: AppTypography.headingSmall(primaryTextColor),
                      ),
                      Text(
                        '${student.name} (${student.jdNo}) • ${student.mobile}',
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              'WELCOME KIT ACTIONS',
              style: AppTypography.microLabel(secondaryTextColor),
            ),
            const SizedBox(height: 12),

            // Action 1: Welcome Message 🟢
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.statusActive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusActive, width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.chat, color: AppColors.statusActive),
                title: const Text(
                  '1. Welcome Message 🟢',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.statusActive),
                ),
                subtitle: const Text('WhatsApp par welcome message bhejo', style: TextStyle(fontSize: 12)),
                onTap: _openWhatsAppWelcome,
              ),
            ),

            // Action 2: ID Card Bhejo 🖨
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.badge_outlined, color: AppColors.champagneGold),
                title: Text(
                  '2. ID Card Bhejo 🖨',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                ),
                subtitle: const Text('Member ki ID card file share karein', style: TextStyle(fontSize: 12)),
                onTap: () => IDCardService.shareMemberIDCard(context, student),
              ),
            ),

            // Action 3: Invoice Bhejo 🧾
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: AppColors.champagneGold),
                title: Text(
                  '3. Invoice Bhejo 🧾',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                ),
                subtitle: const Text('Admission & fee invoice receipt share karein', style: TextStyle(fontSize: 12)),
                onTap: () {
                  InvoiceService.shareInvoice(
                    context: context,
                    student: student,
                    paidAmount: initialPaid,
                    planPrice: 1000.0,
                    admissionFee: student.admissionFeeEnabled ? 500.0 : 0.0,
                    paymentMode: 'Cash',
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
