import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../services/theme_service.dart';
import '../../services/auth_service.dart';
import '../../database/database_helper.dart';
import '../../database/repositories/settings_repository.dart';
import '../../models/studio_info.dart';
import 'screens/manage_plans_screen.dart';
import 'screens/manage_services_screen.dart';
import 'screens/manage_timings_screen.dart';
import 'screens/manage_hobbies_screen.dart';
import 'screens/manage_templates_screen.dart';
import 'screens/edit_studio_info_screen.dart';
import 'screens/backup_restore_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StudioInfo _studioInfo = StudioInfo.defaultInfo;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final bioSetting = await DatabaseHelper().getSetting('biometricEnabled');
    final info = await SettingsRepository().getStudioInfo();

    if (mounted) {
      setState(() {
        _biometricEnabled = bioSetting == 'true';
        _studioInfo = info;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final authenticated = await AuthService().authenticate();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric verify nahi ho saka.')),
          );
        }
        return;
      }
    }
    await DatabaseHelper().setSetting('biometricEnabled', value ? 'true' : 'false');
    setState(() => _biometricEnabled = value);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Studio Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        size: 54,
                        color: AppColors.champagneGold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _studioInfo.studioName,
                      style: AppTypography.headingMedium(primaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Director: ${_studioInfo.directorName}',
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                    Text(
                      _studioInfo.address,
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const EditStudioInfoScreen()),
                        );
                        _loadProfileData();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.champagneGold,
                        side: const BorderSide(color: AppColors.champagneGold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Studio Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'PREFERENCES & SECURITY',
                style: AppTypography.microLabel(secondaryTextColor),
              ),
              const SizedBox(height: 8),

              // Theme Switcher Card
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService().themeModeNotifier,
                builder: (context, mode, _) {
                  final isCurrentlyDark = mode == ThemeMode.dark;
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        isCurrentlyDark ? '🌙 Dark Mode' : '☀ Light Mode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                      ),
                      subtitle: Text(
                        'App visual theme badlein',
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                      value: isCurrentlyDark,
                      activeTrackColor: AppColors.champagneGold,
                      onChanged: (_) => ThemeService().toggleTheme(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // App Lock Biometric Switch Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: SwitchListTile(
                  title: Text(
                    '🔐 Biometric App Lock',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                  ),
                  subtitle: Text(
                    'Fingerprint / Screen lock se app surakshit karein',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  value: _biometricEnabled,
                  activeTrackColor: AppColors.champagneGold,
                  onChanged: _toggleBiometrics,
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'BACKUP & DATA SAFETY',
                style: AppTypography.microLabel(secondaryTextColor),
              ),
              const SizedBox(height: 8),

              _buildMenuTile(
                icon: Icons.cloud_sync_outlined,
                title: '☁ Google Drive Backup & Restore',
                subtitle: 'Automatic / Manual backup to Google Drive AppData',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen())),
              ),

              const SizedBox(height: 24),
              Text(
                'STUDIO CONFIGURATION (CRUD)',
                style: AppTypography.microLabel(secondaryTextColor),
              ),
              const SizedBox(height: 8),

              _buildMenuTile(
                icon: Icons.price_change_outlined,
                title: 'Plans, Fees & Admission Setup',
                subtitle: 'Monthly, Quarterly, Yearly & admission fee',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManagePlansScreen())),
              ),
              _buildMenuTile(
                icon: Icons.category_outlined,
                title: 'Services (Home Tuition, Gym, Dance, Yoga)',
                subtitle: 'Add, Edit & Delete generic business services',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManageServicesScreen())),
              ),
              _buildMenuTile(
                icon: Icons.schedule_outlined,
                title: 'Timings & Batches (6 to 7 AM, Weekdays)',
                subtitle: 'Add, Edit & Delete batch timing schedules',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManageTimingsScreen())),
              ),
              _buildMenuTile(
                icon: Icons.palette_outlined,
                title: 'Hobbies List',
                subtitle: 'Add, Edit & Delete managed hobbies list',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManageHobbiesScreen())),
              ),
              _buildMenuTile(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp Templates',
                subtitle: 'Welcome kit & fee reminder templates',
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManageTemplatesScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.champagneGold, size: 22),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
        trailing: Icon(Icons.chevron_right, color: secondaryTextColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
