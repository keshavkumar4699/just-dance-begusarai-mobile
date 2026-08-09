import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/service.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../database/repositories/student_repository.dart';
import '../../../app/widgets/app_button.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final StudentRepository _studentRepo = StudentRepository();
  List<BusinessService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final loaded = await _settingsRepo.getServices();
    if (mounted) {
      setState(() {
        _services = loaded;
        _isLoading = false;
      });
    }
  }

  void _showAddEditServiceDialog([BusinessService? service, int? index]) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(service == null ? 'Add New Service' : 'Edit Service', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Service Name (e.g. Home Tuition, Yoga, Gym)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final updatedList = List<BusinessService>.from(_services);
                if (index != null) {
                  updatedList[index] = BusinessService(id: service?.id, name: name);
                } else {
                  updatedList.add(BusinessService(id: DateTime.now().millisecondsSinceEpoch, name: name));
                }
                await _settingsRepo.saveServices(updatedList);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadServices();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(BusinessService service, int index) async {
    // Safety Check: Check if any member has this service assigned
    final students = await _studentRepo.getAllStudents();
    final isAssigned = students.any((s) => s.services.contains(service.name));

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
            content: Text('Ye service "${service.name}" members ko assigned hai. Pehle members ki service change karein.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    final updatedList = List<BusinessService>.from(_services)..removeAt(index);
    await _settingsRepo.saveServices(updatedList);
    _loadServices();
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
        title: const Text('Services Management'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('MANAGED BUSINESS SERVICES', style: AppTypography.microLabel(secondaryTextColor)),
                  const SizedBox(height: 12),

                  ..._services.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined, color: AppColors.champagneGold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              service.name,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showAddEditServiceDialog(service, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusExpired),
                            onPressed: () => _deleteService(service, index),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  AppButton(
                    label: '+ Nayi Service Add Karein',
                    icon: Icons.add,
                    onPressed: () => _showAddEditServiceDialog(),
                  ),
                ],
              ),
      ),
    );
  }
}
