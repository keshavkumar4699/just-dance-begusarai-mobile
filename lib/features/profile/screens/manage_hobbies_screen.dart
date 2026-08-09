import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../app/widgets/app_button.dart';

class ManageHobbiesScreen extends StatefulWidget {
  const ManageHobbiesScreen({super.key});

  @override
  State<ManageHobbiesScreen> createState() => _ManageHobbiesScreenState();
}

class _ManageHobbiesScreenState extends State<ManageHobbiesScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  List<String> _hobbies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHobbies();
  }

  Future<void> _loadHobbies() async {
    setState(() => _isLoading = true);
    final loaded = await _settingsRepo.getHobbies();
    if (mounted) {
      setState(() {
        _hobbies = loaded;
        _isLoading = false;
      });
    }
  }

  void _showAddEditHobbyDialog([String? hobby, int? index]) {
    final nameCtrl = TextEditingController(text: hobby ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hobby == null ? 'Add New Hobby' : 'Edit Hobby', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Hobby Name (e.g. Painting, Guitar)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final updatedList = List<String>.from(_hobbies);
                if (index != null) {
                  updatedList[index] = name;
                } else {
                  if (!updatedList.contains(name)) updatedList.add(name);
                }
                await _settingsRepo.saveHobbies(updatedList);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadHobbies();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHobby(int index) async {
    final updatedList = List<String>.from(_hobbies)..removeAt(index);
    await _settingsRepo.saveHobbies(updatedList);
    _loadHobbies();
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
        title: const Text('Hobbies Management'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('MANAGED HOBBIES LIST', style: AppTypography.microLabel(secondaryTextColor)),
                  const SizedBox(height: 12),

                  ..._hobbies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hobby = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.palette_outlined, color: AppColors.champagneGold, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hobby,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: () => _showAddEditHobbyDialog(hobby, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.statusExpired),
                            onPressed: () => _deleteHobby(index),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  AppButton(
                    label: '+ Naya Hobby Add Karein',
                    icon: Icons.add,
                    onPressed: () => _showAddEditHobbyDialog(),
                  ),
                ],
              ),
      ),
    );
  }
}
