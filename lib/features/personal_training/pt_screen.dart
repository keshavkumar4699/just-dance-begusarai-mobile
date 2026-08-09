import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../database/database_helper.dart';
import '../../app/widgets/empty_state.dart';

class PTScreen extends StatefulWidget {
  const PTScreen({super.key});

  @override
  State<PTScreen> createState() => _PTScreenState();
}

class _PTScreenState extends State<PTScreen> {
  List<Student> _ptStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPTMembers();
  }

  Future<void> _loadPTMembers() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;
    final maps = await db.query('students', where: 'ptEnabled = 1', orderBy: 'id DESC');
    final loaded = maps.map((m) => Student.fromMap(m)).toList();
    if (mounted) {
      setState(() {
        _ptStudents = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementSession(Student student) async {
    if (student.ptSessionsDone >= student.ptSessions) return;

    final db = await DatabaseHelper().database;
    final updatedDone = student.ptSessionsDone + 1;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'students',
      {
        'ptSessionsDone': updatedDone,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [student.id],
    );

    _loadPTMembers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERSONAL TRAINING',
                    style: AppTypography.microLabel(AppColors.champagneGold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PT Sessions & Coaching',
                    style: AppTypography.headingMedium(primaryTextColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
                  : _ptStudents.isEmpty
                      ? const EmptyStateWidget(
                          title: 'Koi PT Member Nahi Hai',
                          subtitle: 'Student Detail screen me "Personal Training" toggle ON karke member add karein.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _ptStudents.length,
                          itemBuilder: (ctx, i) {
                            final s = _ptStudents[i];
                            final ptBalance = (s.ptSessions * s.ptSessionPrice) - s.ptPaid;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
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
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      Text(
                                        s.jdNo,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.champagneGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sessions: ${s.ptSessionsDone}/${s.ptSessions} done',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      if (ptBalance > 0)
                                        Text(
                                          'PT Due: ₹${ptBalance.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.statusExpired,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: s.ptSessions > 0 ? (s.ptSessionsDone / s.ptSessions).clamp(0.0, 1.0) : 0,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.champagneGold),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: s.ptSessionsDone < s.ptSessions ? () => _incrementSession(s) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.champagneGold,
                                        foregroundColor: AppColors.darkBackground,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.add_task, size: 16),
                                      label: const Text(
                                        '+1 Session Done',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
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
