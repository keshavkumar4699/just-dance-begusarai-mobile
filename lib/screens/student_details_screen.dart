import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import '../services/fee_engine.dart';
import '../services/whatsapp_service.dart';
import '../widgets/ledger_table.dart';
import '../widgets/id_card_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'admission_form_screen.dart';
import 'payment_dialog.dart';

class StudentDetailsScreen extends StatefulWidget {
  final int studentId;

  const StudentDetailsScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  Student? _student;
  List<LedgerEntry> _ledger = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    setState(() => _isLoading = true);
    final student = await _dbHelper.getStudentById(widget.studentId);
    final ledger = await _dbHelper.getLedgerForStudent(widget.studentId);

    if (student != null && ledger.isNotEmpty) {
      final updatedStatus = FeeEngine.evaluateStudentStatus(ledger);
      if (updatedStatus != student.status) {
        final updatedStudent = student.copyWith(status: updatedStatus);
        await _dbHelper.updateStudent(updatedStudent);
        _student = updatedStudent;
      } else {
        _student = student;
      }
    } else {
      _student = student;
    }

    setState(() {
      _ledger = ledger;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.activeGreen;
      case 'pending':
        return AppColors.pendingAmber;
      case 'overdue':
        return AppColors.overdueRed;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Delete Student Profile', style: AppFonts.titleHeader(color: AppColors.overdueRed)),
        content: Text(
          'Are you sure you want to delete ${_student?.name}? All associated fee ledgers will be permanently removed.',
          style: AppFonts.bodyText(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppFonts.bodyText(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.overdueRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE', style: AppFonts.bodyText(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteStudent(widget.studentId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Student Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_student == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Student Details')),
        body: Center(child: Text('Student profile not found.', style: AppFonts.subtitleText())),
      );
    }

    final student = _student!;
    final statusColor = _getStatusColor(student.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(student.name, style: AppFonts.displayHeader(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.gold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdmissionFormScreen(studentToEdit: student)),
              ).then((_) => _loadStudentDetails());
            },
          ),
          PopupMenuButton<String>(
            color: AppColors.cardBg,
            onSelected: (val) {
              if (val == 'delete') _deleteStudent();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Student', style: AppFonts.bodyText(color: AppColors.overdueRed)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Student Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGold, width: 0.8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                        style: AppFonts.displayHeader(fontSize: 24, color: AppColors.gold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: AppFonts.titleHeader(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text("Joined: ${student.joiningDate}", style: AppFonts.subtitleText(fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 0.8),
                            ),
                            child: Text(
                              student.status.toUpperCase(),
                              style: AppFonts.subtitleText(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('MONTHLY FEE', style: AppFonts.subtitleText(color: AppColors.gold, fontSize: 9)),
                        Text(FeeEngine.formatCurrency(student.monthlyFee), style: AppFonts.numberText(fontSize: 18, color: AppColors.gold)),
                        Text("Due: ${student.dueDay}th", style: AppFonts.subtitleText(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                        onPressed: () => _makeCall(student.phone),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('WhatsApp'),
                        onPressed: () {
                          WhatsAppService.sendPaymentReminder(
                            student: student,
                            monthYear: FeeEngine.getCurrentMonthYear(),
                            amountDue: student.monthlyFee,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_card, size: 16),
                        label: const Text('Pay Fee'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PaymentDialog(student: student),
                          ).then((_) => _loadStudentDetails());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar (Ledger History vs ID Card View)
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppFonts.bodyText(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'PAYMENT LEDGER'),
              Tab(text: 'STUDENT ID CARD'),
            ],
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Ledger Table
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: LedgerTableWidget(entries: _ledger, student: student),
                ),

                // Tab 2: ID Card View
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      IDCardWidget(student: student),
                      const SizedBox(height: 20),
                      Text(
                        'This digital card can be saved or printed for studio attendance check-in.',
                        style: AppFonts.subtitleText(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
