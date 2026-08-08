import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import '../services/fee_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../constants.dart';
import 'admission_form_screen.dart';
import 'student_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Student> _students = [];
  List<LedgerEntry> _ledgerEntries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final students = await _dbHelper.getAllStudents(
      searchQuery: _searchQuery,
      statusFilter: _selectedStatusFilter,
    );
    final ledger = await _dbHelper.getAllLedgerEntries();

    setState(() {
      _students = students;
      _ledgerEntries = ledger;
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

  @override
  Widget build(BuildContext context) {
    final stats = FeeEngine.calculateDashboardStats(
      students: _students,
      ledgerEntries: _ledgerEntries,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  AppConstants.logoAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppColors.gold, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(AppConstants.appName, style: AppFonts.displayHeader(fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            // 1. Dashboard Metrics Summary Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24242A), Color(0xFF16161A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGold, width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('THIS MONTH COLLECTION', style: AppFonts.subtitleText(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              FeeEngine.formatCurrency(stats['totalCollectedMonth'] as double),
                              style: AppFonts.numberText(fontSize: 22, color: AppColors.ivory),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            FeeEngine.getCurrentMonthYear(),
                            style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip('Total', stats['totalStudents'].toString(), AppColors.ivory),
                        _buildStatChip('Active', stats['activeStudents'].toString(), AppColors.activeGreen),
                        _buildStatChip('Pending', stats['pendingStudents'].toString(), AppColors.pendingAmber),
                        _buildStatChip('Overdue', stats['overdueStudents'].toString(), AppColors.overdueRed),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                style: AppFonts.bodyText(),
                onChanged: (val) {
                  _searchQuery = val;
                  _loadData();
                },
                decoration: InputDecoration(
                  hintText: 'Search student name, phone, dance style...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Status Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Active', 'Pending', 'Overdue'].map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatusFilter = status);
                          _loadData();
                        }
                      },
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.surface,
                      labelStyle: isSelected
                          ? AppFonts.bodyText(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 12)
                          : AppFonts.bodyText(color: AppColors.textSecondary, fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isSelected ? AppColors.gold : AppColors.borderSubtle),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Student List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.group_outlined, color: AppColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              Text('No students match your criteria.', style: AppFonts.subtitleText()),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final statusColor = _getStatusColor(student.status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.surfaceLight,
                                      child: Text(
                                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                        style: AppFonts.displayHeader(fontSize: 18, color: AppColors.gold),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.cardBg, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        style: AppFonts.titleHeader(fontSize: 15, color: AppColors.ivory),
                                      ),
                                    ),
                                    Text(
                                      FeeEngine.formatCurrency(student.monthlyFee),
                                      style: AppFonts.numberText(fontSize: 14, color: AppColors.gold),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "📞 ${student.phone} • ${student.batchTiming}",
                                        style: AppFonts.subtitleText(fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: student.danceStyles.map((style) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(style, style: AppFonts.subtitleText(fontSize: 9, color: AppColors.goldLight)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentDetailsScreen(studentId: student.id!),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdmissionFormScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.person_add),
        label: Text('New Student', style: AppFonts.bodyText(fontWeight: FontWeight.bold, color: AppColors.background)),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppFonts.numberText(fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppFonts.subtitleText(fontSize: 10)),
      ],
    );
  }
}
