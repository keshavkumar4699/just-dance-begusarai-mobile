import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/student.dart';
import '../../../services/fee_engine.dart';
import '../../../services/id_card_service.dart';
import '../../../app/widgets/app_button.dart';

class IDCardDialog extends StatefulWidget {
  final Student student;

  const IDCardDialog({
    super.key,
    required this.student,
  });

  @override
  State<IDCardDialog> createState() => _IDCardDialogState();
}

class _IDCardDialogState extends State<IDCardDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _openWhatsAppEmpty() async {
    final cleanMobile = widget.student.mobile.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;
    final uri = Uri.parse('https://wa.me/$formattedPhone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    await IDCardService.captureAndShareIDCard(context, _boundaryKey, widget.student);
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final eval = FeeEngine.evaluateStudent(student);
    final validTillStr = '${eval.paidTill.day}/${eval.paidTill.month}/${eval.paidTill.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.champagneGold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.champagneGold.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rendered ID Card Widget wrapped in RepaintBoundary for PNG image capture
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.champagneGold, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Header: Studio Brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 28, color: AppColors.champagneGold),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STUDIO CROW',
                              style: AppTypography.headingSmall(AppColors.champagneGold),
                            ),
                            const Text(
                              'BEGUSARAI BRANCH • MEMBER ID CARD',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.darkSecondaryText, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.darkHairline, height: 1),
                    const SizedBox(height: 12),

                    // Card Body: Photo & Member Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        student.photoPath != null && File(student.photoPath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(student.photoPath!),
                                  width: 75,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 75,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.champagneGoldMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.champagneGold),
                                ),
                                child: const Icon(Icons.person, size: 40, color: AppColors.champagneGold),
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    student.jdNo,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.champagneGold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.champagneGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      student.category,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.champagneGold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              if (student.fatherName != null)
                                Text(
                                  'S/O ${student.fatherName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.darkSecondaryText),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Plan: ${student.plan}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              Text(
                                'Services: ${student.services.join(", ")}',
                                style: const TextStyle(fontSize: 10, color: AppColors.darkSecondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Card Footer Strip: Valid Till & Mobile
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkHairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('VALID TILL', style: TextStyle(fontSize: 8, color: AppColors.darkSecondaryText, fontWeight: FontWeight.w700)),
                              Text(validTillStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.statusActive)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('MOBILE NO', style: TextStyle(fontSize: 8, color: AppColors.darkSecondaryText, fontWeight: FontWeight.w700)),
                              Text(student.mobile, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Actions Bar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openWhatsAppEmpty,
                    icon: const Icon(Icons.chat, size: 16, color: AppColors.statusActive),
                    label: const Text('WhatsApp 🟢', style: TextStyle(fontSize: 12, color: AppColors.statusActive, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.statusActive),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Share ID 🖨',
                    isLoading: _isSharing,
                    onPressed: _shareImage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.darkSecondaryText, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
