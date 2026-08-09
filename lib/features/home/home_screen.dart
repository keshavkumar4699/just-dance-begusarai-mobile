import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../services/fee_engine.dart';
import '../../app/widgets/filter_chip.dart';
import '../../app/widgets/member_card.dart';
import '../../app/widgets/section_header.dart';
import '../../app/widgets/empty_state.dart';
import '../../database/repositories/student_repository.dart';
import '../student_detail/student_detail_screen.dart';
import 'dialogs/renew_dialog.dart';
import 'dialogs/block_dialog.dart';
import 'dialogs/delete_dialog.dart';
import 'dialogs/id_card_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final StudentRepository _studentRepo = StudentRepository();
  List<Student> _allStudents = [];
  String _selectedFilter = 'All'; // All, Active, Near Expiry, Expired, Due, Inactive, Blocked
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final loaded = await _studentRepo.getAllStudents();
    if (mounted) {
      setState(() {
        _allStudents = loaded;
        _isLoading = false;
      });
    }
  }

  // Filtered & Searched student list logic
  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();

    return _allStudents.where((student) {
      final eval = FeeEngine.evaluateStudent(student);

      // Search match across name, mobile, altMobile, jdNo
      final matchesSearch = query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.mobile.contains(query) ||
          (student.altMobile?.contains(query) ?? false) ||
          student.jdNo.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      // Filter match
      if (_selectedFilter == 'Active') {
        return eval.status == MemberStatus.active;
      } else if (_selectedFilter == 'Near Expiry') {
        return eval.status == MemberStatus.nearExpiry;
      } else if (_selectedFilter == 'Expired') {
        return eval.status == MemberStatus.expired;
      } else if (_selectedFilter == 'Due') {
        return eval.dueAmount > 0;
      } else if (_selectedFilter == 'Inactive') {
        return eval.status == MemberStatus.inactive;
      } else if (_selectedFilter == 'Blocked') {
        return eval.status == MemberStatus.blocked;
      }

      // 'All' filter excludes blocked members unless explicitly under Blocked filter
      return eval.status != MemberStatus.blocked;
    }).toList();
  }

  // Live Count Computations
  int get _activeCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.active).length;
  int get _nearExpiryCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.nearExpiry).length;
  int get _expiredCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.expired).length;
  int get _dueCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).dueAmount > 0).length;
  int get _inactiveCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.inactive).length;
  int get _blockedCount => _allStudents.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.blocked).length;

  // Member Sorting per Section 16
  List<Student> _sortMembers(List<Student> list) {
    final sorted = List<Student>.from(list);
    sorted.sort((a, b) {
      final evalA = FeeEngine.evaluateStudent(a);
      final evalB = FeeEngine.evaluateStudent(b);

      if (evalA.status == MemberStatus.expired && evalB.status != MemberStatus.expired) return -1;
      if (evalB.status == MemberStatus.expired && evalA.status != MemberStatus.expired) return 1;

      if (evalA.status == MemberStatus.nearExpiry && evalB.status != MemberStatus.nearExpiry) return -1;
      if (evalB.status == MemberStatus.nearExpiry && evalA.status != MemberStatus.nearExpiry) return 1;

      return evalA.daysLeft.compareTo(evalB.daysLeft);
    });
    return sorted;
  }

  Future<void> _handleCheckIn(Student student) async {
    await _studentRepo.recordCheckIn(student.id!);
    _loadStudents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} marked Present ✔'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StudentDetailScreen(studentId: student.id!),
      ),
    ).then((_) => _loadStudents());
  }

  void _showIDCardDialog(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => IDCardDialog(student: student),
    );
  }

  void _showRenewDialog(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => RenewDialog(
        student: student,
        onSaved: _loadStudents,
      ),
    );
  }

  void _showBlockDialog(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => BlockDialog(
        student: student,
        onToggled: _loadStudents,
      ),
    );
  }

  void _showDeleteDialog(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        student: student,
        onDeleted: _loadStudents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final searchBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    final sortedList = _sortMembers(_filteredStudents);

    // Grouping for section headers
    final expiredGroup = sortedList.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.expired).toList();
    final nearExpiryGroup = sortedList.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.nearExpiry).toList();
    final activeGroup = sortedList.where((s) => FeeEngine.evaluateStudent(s).status == MemberStatus.active).toList();
    final otherGroup = sortedList.where((s) =>
        FeeEngine.evaluateStudent(s).status != MemberStatus.expired &&
        FeeEngine.evaluateStudent(s).status != MemberStatus.nearExpiry &&
        FeeEngine.evaluateStudent(s).status != MemberStatus.active
    ).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
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
                        style: AppTypography.headingSmall(primaryTextColor),
                      ),
                      Text(
                        'Begusarai Branch',
                        style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadStudents,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 14, color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Naam, mobile ya ID no. se khojein…',
                    hintStyle: TextStyle(fontSize: 13, color: secondaryTextColor),
                    prefixIcon: Icon(Icons.search, size: 18, color: secondaryTextColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16, color: secondaryTextColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  CustomFilterChip(
                    label: 'Sabhi',
                    count: _allStudents.where((s) => !s.isBlocked).length,
                    isSelected: _selectedFilter == 'All',
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: 'Active',
                    count: _activeCount,
                    isSelected: _selectedFilter == 'Active',
                    onTap: () => setState(() => _selectedFilter = 'Active'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: '7 Din Paas',
                    count: _nearExpiryCount,
                    isSelected: _selectedFilter == 'Near Expiry',
                    onTap: () => setState(() => _selectedFilter = 'Near Expiry'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: 'Expired',
                    count: _expiredCount,
                    isSelected: _selectedFilter == 'Expired',
                    onTap: () => setState(() => _selectedFilter = 'Expired'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: 'Due',
                    count: _dueCount,
                    isSelected: _selectedFilter == 'Due',
                    onTap: () => setState(() => _selectedFilter = 'Due'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: 'Inactive',
                    count: _inactiveCount,
                    isSelected: _selectedFilter == 'Inactive',
                    onTap: () => setState(() => _selectedFilter = 'Inactive'),
                  ),
                  const SizedBox(width: 6),
                  CustomFilterChip(
                    label: 'Blocked',
                    count: _blockedCount,
                    isSelected: _selectedFilter == 'Blocked',
                    onTap: () => setState(() => _selectedFilter = 'Blocked'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Members List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
                  : _allStudents.isEmpty
                      ? const EmptyStateWidget(
                          title: 'Abhi koi member nahi hai',
                          subtitle: 'Studio me members add karne ke liye neeche "+" dabayein.',
                        )
                      : sortedList.isEmpty
                          ? const EmptyStateWidget(
                              title: 'Koi member nahi mila',
                              subtitle: 'Dusra naam, mobile ya filter try karein.',
                            )
                          : ListView(
                              children: [
                                if (expiredGroup.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: SectionHeader(title: 'EXPIRED'),
                                  ),
                                  ...expiredGroup.map((student) => MemberCard(
                                        student: student,
                                        onTap: () => _openStudentDetail(student),
                                        onCheckIn: () => _handleCheckIn(student),
                                        onRenew: () => _showRenewDialog(student),
                                        onBlockToggle: () => _showBlockDialog(student),
                                        onDelete: () => _showDeleteDialog(student),
                                        onShareId: () => _showIDCardDialog(student),
                                      )),
                                ],
                                if (nearExpiryGroup.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: SectionHeader(title: '7 DIN KE ANDAR'),
                                  ),
                                  ...nearExpiryGroup.map((student) => MemberCard(
                                        student: student,
                                        onTap: () => _openStudentDetail(student),
                                        onCheckIn: () => _handleCheckIn(student),
                                        onRenew: () => _showRenewDialog(student),
                                        onBlockToggle: () => _showBlockDialog(student),
                                        onDelete: () => _showDeleteDialog(student),
                                        onShareId: () => _showIDCardDialog(student),
                                      )),
                                ],
                                if (activeGroup.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: SectionHeader(title: 'ACTIVE'),
                                  ),
                                  ...activeGroup.map((student) => MemberCard(
                                        student: student,
                                        onTap: () => _openStudentDetail(student),
                                        onCheckIn: () => _handleCheckIn(student),
                                        onRenew: () => _showRenewDialog(student),
                                        onBlockToggle: () => _showBlockDialog(student),
                                        onDelete: () => _showDeleteDialog(student),
                                        onShareId: () => _showIDCardDialog(student),
                                      )),
                                ],
                                if (otherGroup.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: SectionHeader(title: 'OTHERS'),
                                  ),
                                  ...otherGroup.map((student) => MemberCard(
                                        student: student,
                                        onTap: () => _openStudentDetail(student),
                                        onCheckIn: () => _handleCheckIn(student),
                                        onRenew: () => _showRenewDialog(student),
                                        onBlockToggle: () => _showBlockDialog(student),
                                        onDelete: () => _showDeleteDialog(student),
                                        onShareId: () => _showIDCardDialog(student),
                                      )),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
