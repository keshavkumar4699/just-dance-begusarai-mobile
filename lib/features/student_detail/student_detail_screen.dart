import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../models/ledger_entry.dart';
import '../../services/fee_engine.dart';
import '../../database/repositories/student_repository.dart';
import '../../database/repositories/ledger_repository.dart';
import '../home/dialogs/renew_dialog.dart';
import '../home/dialogs/block_dialog.dart';
import '../home/dialogs/delete_dialog.dart';
import '../home/dialogs/id_card_dialog.dart';
import 'edit_student_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final StudentRepository _studentRepo = StudentRepository();
  final LedgerRepository _ledgerRepo = LedgerRepository();

  Student? _student;
  List<LedgerEntry> _ledgerEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    setState(() => _isLoading = true);
    final s = await _studentRepo.getStudentById(widget.studentId);
    final ledger = await _ledgerRepo.getLedgerForStudent(widget.studentId);

    if (mounted) {
      setState(() {
        _student = s;
        _ledgerEntries = ledger;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (_student == null) return;
    await _studentRepo.recordCheckIn(_student!.id!);
    _loadStudentDetails();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_student!.name} marked Present ✔')),
      );
    }
  }

  Future<void> _makeCall() async {
    if (_student == null) return;
    final clean = _student!.mobile.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsAppEmpty() async {
    if (_student == null) return;
    final clean = _student!.mobile.replaceAll(RegExp(r'\D'), '');
    final phone = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showIDCardDialog() {
    if (_student == null) return;
    showDialog(
      context: context,
      builder: (ctx) => IDCardDialog(student: _student!),
    );
  }

  Future<void> _incrementPTSession() async {
    if (_student == null || !_student!.ptEnabled) return;

    final currentDone = _student!.ptSessionsDone;
    final updatedDone = currentDone + 1;

    final updatedStudent = _student!.copyWith(
      ptSessionsDone: updatedDone,
    );

    await _studentRepo.updateStudent(updatedStudent);
    await _ledgerRepo.insertLedgerEntry(LedgerEntry(
      studentId: _student!.id!,
      date: DateTime.now(),
      type: 'NOTE',
      monthLabel: 'PT Session',
      paidAmount: 0.0,
      note: 'PT Session completed ($updatedDone / ${_student!.ptSessions})',
    ));

    _loadStudentDetails();
  }

  Future<void> _togglePT(bool enabled) async {
    if (_student == null) return;
    final updated = _student!.copyWith(ptEnabled: enabled);
    await _studentRepo.updateStudent(updated);
    _loadStudentDetails();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    if (_isLoading || _student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold)),
      );
    }

    final student = _student!;
    final eval = FeeEngine.evaluateStudent(student);
    final validTillStr = '${eval.paidTill.day}/${eval.paidTill.month}/${eval.paidTill.year}';

    // Status Banner Colors
    Color bannerBg;
    String bannerText;
    if (eval.dueAmount > 0) {
      bannerBg = AppColors.statusExpired;
      final days = DateTime.now().difference(eval.paidTill).inDays;
      bannerText = 'FEES DUE ₹${eval.dueAmount.toStringAsFixed(0)} ($days DAYS OVERDUE)';
    } else if (eval.status == MemberStatus.nearExpiry) {
      bannerBg = AppColors.statusNearExpiry;
      bannerText = 'EXPIRING IN ${eval.daysLeft} DAYS (TILL $validTillStr)';
    } else {
      bannerBg = AppColors.statusActive;
      bannerText = 'FEES PAID ✔ (TILL $validTillStr${eval.creditAmount > 0 ? ' + ₹${eval.creditAmount.toStringAsFixed(0)} ADVANCE' : ''})';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => EditStudentScreen(student: student)),
              );
              if (result == true) _loadStudentDetails();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Banner Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bannerText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Black & Gold Member ID Card Header (Clickable -> Opens ID Card Dialog)
            GestureDetector(
              onTap: _showIDCardDialog,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.champagneGold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        student.photoPath != null && File(student.photoPath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(student.photoPath!),
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.champagneGoldMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.champagneGold),
                                ),
                                child: const Icon(Icons.person, size: 36, color: AppColors.champagneGold),
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
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.champagneGold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.champagneGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      student.category,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.champagneGold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              if (student.fatherName != null)
                                Text(
                                  'S/O ${student.fatherName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.darkSecondaryText),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Plan: ${student.plan} • Services: ${student.services.join(", ")}',
                                style: const TextStyle(fontSize: 11, color: AppColors.darkSecondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.touch_app, size: 12, color: AppColors.champagneGold),
                        SizedBox(width: 4),
                        Text(
                          'Tap to view Visual ID Card 🪪',
                          style: TextStyle(fontSize: 10, color: AppColors.champagneGold, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions Toolbar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => RenewDialog(student: student, onSaved: _loadStudentDetails),
                    ),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Renew / Pay'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.champagneGold,
                      side: const BorderSide(color: AppColors.champagneGold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openWhatsAppEmpty,
                    icon: const Icon(Icons.chat, size: 16, color: AppColors.statusActive),
                    label: const Text('WhatsApp', style: TextStyle(color: AppColors.statusActive)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.statusActive),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.champagneGold),
                  onPressed: _makeCall,
                ),
                IconButton(
                  icon: const Icon(Icons.badge_outlined, color: AppColors.champagneGold),
                  onPressed: _showIDCardDialog,
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleCheckIn,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('✔ Present (Check-in)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusActive,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(student.isBlocked ? Icons.lock_open : Icons.block, color: student.isBlocked ? AppColors.statusActive : AppColors.statusBlocked),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => BlockDialog(student: student, onToggled: _loadStudentDetails),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusExpired),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => DeleteDialog(student: student, onDeleted: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Personal Training (PT) Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PERSONAL TRAINING (PT)', style: AppTypography.microLabel(secondaryTextColor)),
                      Switch(
                        value: student.ptEnabled,
                        activeTrackColor: AppColors.champagneGold,
                        onChanged: _togglePT,
                      ),
                    ],
                  ),
                  if (student.ptEnabled) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${student.ptSessionsDone} / ${student.ptSessions} Sessions Completed',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                              ),
                              Text(
                                'Timing: ${student.ptTiming ?? 'Flexible'} • Price: ₹${student.ptSessionPrice.toStringAsFixed(0)}/sess',
                                style: TextStyle(fontSize: 12, color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _incrementPTSession,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('+1 Session', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.champagneGold,
                            foregroundColor: AppColors.darkBackground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ledger History Section
            Text('FINANCIAL LEDGER HISTORY', style: AppTypography.microLabel(secondaryTextColor)),
            const SizedBox(height: 8),

            _ledgerEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Koi ledger entries nahi hain', style: TextStyle(fontSize: 12))),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ledgerEntries.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, index) {
                        final entry = _ledgerEntries[index];
                        final dateStr = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
                        final amount = entry.paidAmount > 0 ? entry.paidAmount : entry.dueAmount;
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${entry.type} — ₹${amount.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryTextColor),
                          ),
                          subtitle: Text(
                            '$dateStr • ${entry.note ?? entry.monthLabel} • Mode: ${entry.mode}',
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
