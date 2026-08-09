import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isDark = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper();
    final themeVal = await db.getSetting('theme');
    final bioVal = await AuthService().isBiometricEnabled();
    setState(() {
      _isDark = themeVal != 'light';
      _biometricEnabled = bioVal;
    });
  }

  Future<void> _toggleTheme() async {
    final db = DatabaseHelper();
    setState(() => _isDark = !_isDark);
    await db.setSetting('theme', _isDark ? 'dark' : 'light');
    // AppThemeNotifier would trigger rebuild in real app
  }

  Future<void> _toggleBiometric(bool val) async {
    // Check if biometric is available first
    final auth = AuthService();
    if (val && !await auth.canCheckBiometrics()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric available nahi hai device pe'),
        ),
      );
      return;
    }
    setState(() => _biometricEnabled = val);
    await auth.setBiometricEnabled(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Studio header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surface,
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.gold,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Studio. Your Rules.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Theme toggle
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(_isDark ? 'Abhi dark theme on hai' : 'Light theme on hai'),
              value: _isDark,
              activeTrackColor: AppColors.gold,
              onChanged: (_) => _toggleTheme(),
            ),
          ),
          const SizedBox(height: 12),

          // Biometric toggle
          Card(
            child: SwitchListTile(
              title: const Text('App Lock (Biometric)'),
              subtitle: const Text(
                'Default PIN: 2026 (README me details)',
              ),
              value: _biometricEnabled,
              activeColor: AppColors.gold,
              onChanged: _toggleBiometric,
            ),
          ),
          const SizedBox(height: 12),

          // Info card
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.gold),
              title: const Text('About'),
              subtitle: const Text('Version 1.0.0 • Phase 1 Foundation'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}