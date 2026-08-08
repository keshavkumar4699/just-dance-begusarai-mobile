import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/backup_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentPin = AppConstants.defaultPin;
  bool _biometricsEnabled = false;
  String _lastBackupTime = 'Never';
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pin = await SettingsService.getPin();
    final bio = await SettingsService.isBiometricsEnabled();
    final backup = await BackupService.getLastBackupTimestamp();

    setState(() {
      _currentPin = pin;
      _biometricsEnabled = bio;
      if (backup != null && backup.isNotEmpty) {
        _lastBackupTime = backup;
      }
    });
  }

  Future<void> _changePinDialog() async {
    final controller = TextEditingController(text: _currentPin);
    final formKey = GlobalKey<FormState>();

    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Change Security PIN', style: AppFonts.titleHeader(color: AppColors.gold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: AppFonts.displayHeader(fontSize: 24),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '2026',
            ),
            validator: (val) => val != null && val.length == 4 ? null : 'PIN must be 4 digits',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppFonts.bodyText(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: Text('SAVE PIN', style: AppFonts.bodyText(fontWeight: FontWeight.bold, color: AppColors.background)),
          ),
        ],
      ),
    );

    if (newPin != null && newPin.isNotEmpty) {
      await SettingsService.setPin(newPin);
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN updated successfully to $newPin')),
        );
      }
    }
  }

  Future<void> _runGoogleDriveBackup() async {
    setState(() => _isBackingUp = true);

    final success = await BackupService.performCloudBackup();
    await _loadSettings();

    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Database backed up to Google Drive!' : 'Backup initialized. Check Google Auth settings.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Studio Settings', style: AppFonts.displayHeader(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Security & Auth
          Text('SECURITY & ACCESS', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.gold),
                  title: Text('Security Lock PIN', style: AppFonts.bodyText(fontWeight: FontWeight.bold)),
                  subtitle: Text("Current PIN: $_currentPin (Default: 2026)", style: AppFonts.subtitleText()),
                  trailing: OutlinedButton(
                    onPressed: _changePinDialog,
                    child: const Text('CHANGE'),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint, color: AppColors.gold),
                  title: Text('Biometric Fingerprint Unlock', style: AppFonts.bodyText(fontWeight: FontWeight.bold)),
                  subtitle: Text('Require fingerprint to bypass PIN screen', style: AppFonts.subtitleText()),
                  value: _biometricsEnabled,
                  activeThumbColor: AppColors.gold,
                  onChanged: (val) async {
                    await SettingsService.setBiometricsEnabled(val);
                    _loadSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Data Backup & Sync
          Text('DATA BACKUP & CLOUD RESTORE', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.gold),
              title: Text('Google Drive Backup', style: AppFonts.bodyText(fontWeight: FontWeight.bold)),
              subtitle: Text("Last backup: $_lastBackupTime", style: AppFonts.subtitleText()),
              trailing: ElevatedButton(
                onPressed: _isBackingUp ? null : _runGoogleDriveBackup,
                child: _isBackingUp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                    : const Text('BACKUP NOW'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Studio Info
          Text('STUDIO INFORMATION', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(
                            AppConstants.logoAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppColors.gold, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppConstants.appName, style: AppFonts.titleHeader(fontSize: 16)),
                            Text(AppConstants.studioAddress, style: AppFonts.subtitleText()),
                            Text("Phone: ${AppConstants.studioPhone}", style: AppFonts.subtitleText(color: AppColors.gold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Footer
          Center(
            child: Text(
              "Just Dance Academy v1.0.0 (Begusarai)",
              style: AppFonts.subtitleText(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
