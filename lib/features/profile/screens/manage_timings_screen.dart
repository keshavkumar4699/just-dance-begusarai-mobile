import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/timing.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../database/repositories/student_repository.dart';
import '../../../app/widgets/app_button.dart';

class ManageTimingsScreen extends StatefulWidget {
  const ManageTimingsScreen({super.key});

  @override
  State<ManageTimingsScreen> createState() => _ManageTimingsScreenState();
}

class _ManageTimingsScreenState extends State<ManageTimingsScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final StudentRepository _studentRepo = StudentRepository();
  List<Timing> _timings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  Future<void> _loadTimings() async {
    setState(() => _isLoading = true);
    final loaded = await _settingsRepo.getTimings();
    if (mounted) {
      setState(() {
        _timings = loaded;
        _isLoading = false;
      });
    }
  }

  void _showAddEditTimingDialog([Timing? timing, int? index]) {
    final nameCtrl = TextEditingController(text: timing?.name ?? '');
    final daysCtrl = TextEditingController(text: timing?.days ?? 'Mon–Sat');
    final hoursCtrl = TextEditingController(text: timing?.hours ?? '6 to 7 AM');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(timing == null ? 'Add Batch Timing' : 'Edit Batch Timing', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Batch Name (e.g. Morning Batch)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: daysCtrl,
                decoration: const InputDecoration(labelText: 'Days (e.g. Mon–Sat, Sat–Sun)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: 'Timing Hours (e.g. 6 to 7 AM)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final days = daysCtrl.text.trim();
              final hours = hoursCtrl.text.trim();

              if (name.isNotEmpty) {
                final updatedTiming = Timing(id: timing?.id ?? DateTime.now().millisecondsSinceEpoch, name: name, days: days, hours: hours);
                final updatedList = List<Timing>.from(_timings);
                if (index != null) {
                  updatedList[index] = updatedTiming;
                } else {
                  updatedList.add(updatedTiming);
                }
                await _settingsRepo.saveTimings(updatedList);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTimings();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTiming(Timing timing, int index) async {
    final students = await _studentRepo.getAllStudents();
    final isAssigned = students.any((s) => s.timingId == timing.id);

    if (isAssigned) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.statusNearExpiry),
                SizedBox(width: 8),
                Text('Cannot Delete'),
              ],
            ),
            content: Text('Ye timing batch "${timing.name}" members ko assigned hai. Pehle members ki details change karein.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    final updatedList = List<Timing>.from(_timings)..removeAt(index);
    await _settingsRepo.saveTimings(updatedList);
    _loadTimings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timings & Batches Management'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('BATCH SCHEDULES & TIMINGS', style: AppTypography.microLabel(secondaryTextColor)),
                  const SizedBox(height: 12),

                  ..._timings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final timing = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_outlined, color: AppColors.champagneGold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(timing.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor)),
                                Text('${timing.days} • ${timing.hours}', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showAddEditTimingDialog(timing, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusExpired),
                            onPressed: () => _deleteTiming(timing, index),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  AppButton(
                    label: '+ Nayi Batch Timing Add Karein',
                    icon: Icons.add,
                    onPressed: () => _showAddEditTimingDialog(),
                  ),
                ],
              ),
      ),
    );
  }
}
