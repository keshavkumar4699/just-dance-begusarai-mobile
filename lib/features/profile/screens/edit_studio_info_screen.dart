import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/studio_info.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../app/widgets/app_button.dart';

class EditStudioInfoScreen extends StatefulWidget {
  const EditStudioInfoScreen({super.key});

  @override
  State<EditStudioInfoScreen> createState() => _EditStudioInfoScreenState();
}

class _EditStudioInfoScreenState extends State<EditStudioInfoScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();

  final TextEditingController _studioNameCtrl = TextEditingController();
  final TextEditingController _directorCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _instaCtrl = TextEditingController();
  final TextEditingController _ytCtrl = TextEditingController();
  final TextEditingController _footerCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudioInfo();
  }

  Future<void> _loadStudioInfo() async {
    final info = await _settingsRepo.getStudioInfo();
    if (mounted) {
      setState(() {
        _studioNameCtrl.text = info.studioName;
        _directorCtrl.text = info.directorName;
        _mobileCtrl.text = info.mobile;
        _addressCtrl.text = info.address;
        _instaCtrl.text = info.instagram ?? '';
        _ytCtrl.text = info.youtube ?? '';
        _footerCtrl.text = info.ownerFooter;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveStudioInfo() async {
    setState(() => _isSaving = true);
    try {
      final info = StudioInfo(
        studioName: _studioNameCtrl.text.trim().isNotEmpty ? _studioNameCtrl.text.trim() : 'Studio Crow',
        directorName: _directorCtrl.text.trim().isNotEmpty ? _directorCtrl.text.trim() : 'Rahul Raja Sir',
        mobile: _mobileCtrl.text.trim().isNotEmpty ? _mobileCtrl.text.trim() : '+919999999999',
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Begusarai, Bihar',
        instagram: _instaCtrl.text.trim().isNotEmpty ? _instaCtrl.text.trim() : null,
        youtube: _ytCtrl.text.trim().isNotEmpty ? _ytCtrl.text.trim() : null,
        ownerFooter: _footerCtrl.text.trim().isNotEmpty ? _footerCtrl.text.trim() : '– Rahul Raja Sir 🕺',
      );

      await _settingsRepo.saveStudioInfo(info);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studio details saved!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save nahi ho paya.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Studio Info'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _studioNameCtrl,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Studio Name*', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _directorCtrl,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Director / Owner Name*', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Contact Mobile*', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Studio Address*', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _instaCtrl,
                          style: TextStyle(color: primaryTextColor),
                          decoration: _inputDecoration('Instagram Handle', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ytCtrl,
                          style: TextStyle(color: primaryTextColor),
                          decoration: _inputDecoration('YouTube Channel', borderColor, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _footerCtrl,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Owner Footer (e.g. – Rahul Raja Sir 🕺)', borderColor, secondaryTextColor),
                  ),

                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Save Studio Info',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _saveStudioInfo,
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, Color borderColor, Color secondaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: secondaryColor),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.champagneGold)),
    );
  }
}
