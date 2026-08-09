import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/ledger_entry.dart';
import '../../models/student.dart';
import '../../database/repositories/ledger_repository.dart';
import '../../database/repositories/student_repository.dart';
import '../../app/widgets/empty_state.dart';
import '../student_detail/student_detail_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final LedgerRepository _ledgerRepo = LedgerRepository();
  final StudentRepository _studentRepo = StudentRepository();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<LedgerEntry> _monthEntries = [];
  Map<int, Student> _studentMap = {};
  String _selectedCategory = 'All'; // All, Fees, PT, Admission
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollectionsData();
  }

  Future<void> _loadCollectionsData() async {
    setState(() => _isLoading = true);

    final allLedger = await _ledgerRepo.getAllLedgerEntries();
    final allStudents = await _studentRepo.getAllStudents();

    final sMap = <int, Student>{};
    for (final s in allStudents) {
      if (s.id != null) sMap[s.id!] = s;
    }

    // Filter entries belonging to _selectedMonth
    final filtered = allLedger.where((entry) {
      return entry.date.year == _selectedMonth.year && entry.date.month == _selectedMonth.month;
    }).toList();

    if (mounted) {
      setState(() {
        _studentMap = sMap;
        _monthEntries = filtered;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _loadCollectionsData();
  }

  // Calculated KPI Totals
  double get _totalCollected => _monthEntries.fold(0.0, (sum, e) => sum + e.paidAmount);
  double get _cashCollected => _monthEntries.where((e) => e.mode.toLowerCase() == 'cash').fold(0.0, (sum, e) => sum + e.paidAmount);
  double get _upiCollected => _monthEntries.where((e) => e.mode.toLowerCase() == 'upi').fold(0.0, (sum, e) => sum + e.paidAmount);
  double get _admissionCollected => _monthEntries.where((e) => e.type == 'ADMISSION_FEE_PAID').fold(0.0, (sum, e) => sum + e.paidAmount);
  double get _ptCollected => _monthEntries.where((e) => e.type == 'PT_PAYMENT').fold(0.0, (sum, e) => sum + e.paidAmount);

  List<LedgerEntry> get _filteredEntries {
    if (_selectedCategory == 'Fees') {
      return _monthEntries.where((e) => e.type == 'PAYMENT' || e.type == 'PLAN_CHANGE').toList();
    } else if (_selectedCategory == 'PT') {
      return _monthEntries.where((e) => e.type == 'PT_PAYMENT').toList();
    } else if (_selectedCategory == 'Admission') {
      return _monthEntries.where((e) => e.type == 'ADMISSION_FEE_PAID').toList();
    }
    return _monthEntries;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    final displayedList = _filteredEntries;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Month Selector Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Column(
                    children: [
                      Text(
                        'COLLECTIONS',
                        style: AppTypography.microLabel(AppColors.champagneGold),
                      ),
                      Text(
                        monthLabel,
                        style: AppTypography.headingMedium(primaryTextColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),

            // Financial Summary KPI Cards Carousel / Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Main Total Collected Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGoldMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.champagneGold, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL COLLECTED THIS MONTH',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.champagneGold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_totalCollected.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.champagneGold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Breakdown Cards Row (Cash, UPI, Admission, PT)
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiPill('CASH', '₹${_cashCollected.toStringAsFixed(0)}', Colors.green, cardBg, borderColor, primaryTextColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiPill('UPI', '₹${_upiCollected.toStringAsFixed(0)}', Colors.blue, cardBg, borderColor, primaryTextColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiPill('ADMISSION', '₹${_admissionCollected.toStringAsFixed(0)}', Colors.orange, cardBg, borderColor, primaryTextColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiPill('PT', '₹${_ptCollected.toStringAsFixed(0)}', Colors.purple, cardBg, borderColor, primaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category Filter Segment Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildSegmentChip('Sabhi (${_monthEntries.length})', 'All', primaryTextColor),
                  const SizedBox(width: 8),
                  _buildSegmentChip('Fee Payments', 'Fees', primaryTextColor),
                  const SizedBox(width: 8),
                  _buildSegmentChip('PT Payments', 'PT', primaryTextColor),
                  const SizedBox(width: 8),
                  _buildSegmentChip('Admission Fees', 'Admission', primaryTextColor),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Transactions List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
                  : displayedList.isEmpty
                      ? const EmptyStateWidget(
                          title: 'Is mahine koi collections nahi hui',
                          subtitle: 'Jab members fee ya admission denge, yahan list dikhegi.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: displayedList.length,
                          itemBuilder: (ctx, index) {
                            final entry = displayedList[index];
                            final student = _studentMap[entry.studentId];
                            final dateStr = DateFormat('dd MMM, hh:mm a').format(entry.date);
                            final isCash = entry.mode.toLowerCase() == 'cash';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor, width: 1),
                              ),
                              child: ListTile(
                                onTap: () {
                                  if (student != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (ctx) => StudentDetailScreen(studentId: student.id!)),
                                    );
                                  }
                                },
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isCash ? Colors.green.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                                  child: Icon(
                                    isCash ? Icons.money : Icons.qr_code,
                                    color: isCash ? Colors.green : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  student?.name ?? 'Member #${entry.studentId}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                                ),
                                subtitle: Text(
                                  '${student?.jdNo ?? ''} • $dateStr • ${entry.note ?? entry.type}',
                                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+₹${entry.paidAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.statusActive),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isCash ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        entry.mode.toUpperCase(),
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isCash ? Colors.green : Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildKpiPill(String label, String amount, Color accent, Color cardBg, Color borderColor, Color primaryText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 2),
          Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryText)),
        ],
      ),
    );
  }

  Widget _buildSegmentChip(String label, String key, Color primaryTextColor) {
    final isSel = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.champagneGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppColors.champagneGold : AppColors.darkHairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? AppColors.darkBackground : primaryTextColor,
          ),
        ),
      ),
    );
  }
}
