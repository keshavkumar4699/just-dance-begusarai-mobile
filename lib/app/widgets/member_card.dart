import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../../models/student.dart';
import '../../services/fee_engine.dart';
import '../../features/home/dialogs/id_card_dialog.dart';
import 'status_dot.dart';
import 'hollow_button.dart';

class MemberCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onRenew;
  final VoidCallback? onShareId;
  final VoidCallback? onBlockToggle;
  final VoidCallback? onDelete;

  const MemberCard({
    super.key,
    required this.student,
    this.onTap,
    this.onCheckIn,
    this.onRenew,
    this.onShareId,
    this.onBlockToggle,
    this.onDelete,
  });

  Future<void> _makeCall(String mobile) async {
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsAppEmpty(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;
    final uri = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendReminderWhatsApp(String mobile, String name, int daysLeft) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanMobile.length == 10 ? '91$cleanMobile' : cleanMobile;
    final text = 'Hello $name ji! Studio Crow se reminder. Aapka fee plan expiry paas hai ($daysLeft din baki). Please renew karein. – Studio Crow 🕺';
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showIDCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => IDCardDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = FeeEngine.evaluateStudent(student);
    final statusColor = StatusDot.getStatusColor(eval.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final isNearOrExpired = eval.daysLeft <= 7 || eval.status == MemberStatus.expired || eval.status == MemberStatus.nearExpiry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkHairline : AppColors.lightHairline,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Strip: StatusDot + JD No + Category + Status Label
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  StatusDot(status: eval.status),
                  const SizedBox(width: 8),
                  Text(
                    student.jdNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGoldMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      student.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.champagneGold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    StatusDot.getStatusLabel(eval.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.darkHairline),

            // Middle Main Info Row: Photo + Name + Plan/Services + Days Left
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo / Fallback Avatar
                  student.photoPath != null && File(student.photoPath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(student.photoPath!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkHairline : AppColors.lightHairline,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: secondaryTextColor,
                          ),
                        ),

                  const SizedBox(width: 12),

                  // Name & Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student.plan} • ${student.services.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Due amount or Expiry boundary line
                        if (eval.dueAmount > 0)
                          Text(
                            'Due: ₹${eval.dueAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusExpired,
                            ),
                          )
                        else
                          Text(
                            'PAID till ${eval.paidTill.day}/${eval.paidTill.month}/${eval.paidTill.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Days Left / Overdue Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (eval.dueAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusExpired.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusExpired,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${eval.daysLeft}d left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Quick Action Buttons Row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  // Action 1: Check-in / Present
                  Expanded(
                    child: HollowButton(
                      label: '✔ Present',
                      onPressed: onCheckIn,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Action 2: Renew / Pay
                  Expanded(
                    child: HollowButton(
                      label: 'Renew',
                      color: AppColors.champagneGold,
                      onPressed: onRenew,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Action 3: ID Card 🪪 (Visual Dialog)
                  IconButton(
                    icon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.champagneGold),
                    tooltip: 'View ID Card',
                    onPressed: () => _showIDCardDialog(context),
                  ),

                  // Action 4: WhatsApp 🟢 (Empty Text Opener)
                  IconButton(
                    icon: const Icon(Icons.chat, size: 20, color: AppColors.statusActive),
                    tooltip: 'WhatsApp Direct Chat',
                    onPressed: () => _openWhatsAppEmpty(student.mobile),
                  ),

                  // Action 5: Call 📞
                  IconButton(
                    icon: Icon(Icons.phone, size: 20, color: secondaryTextColor),
                    tooltip: 'Call Member',
                    onPressed: () => _makeCall(student.mobile),
                  ),
                ],
              ),
            ),

            // Bottom Thin Expiry Bar & "Remind Them 🟢" Trigger (if <= 7 days)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Column(
                children: [
                  // Progress indicator bar
                  LinearProgressIndicator(
                    value: (eval.daysLeft / 30.0).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                  if (isNearOrExpired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                      color: AppColors.statusActive.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            eval.dueAmount > 0
                                ? '⚠️ Fee Overdue! Remind member now'
                                : '⏳ ${eval.daysLeft} days remaining before expiry',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                          GestureDetector(
                            onTap: () => _sendReminderWhatsApp(student.mobile, student.name, eval.daysLeft),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusActive,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.chat, size: 10, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Remind Them 🟢',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
