import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../services/backup_service.dart';
import '../../../app/widgets/app_button.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  GoogleSignInAccount? _currentUser;
  bool _isCheckingUser = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = await BackupService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isCheckingUser = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    final user = await BackupService.signIn();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _handleSignOut() async {
    await BackupService.signOut();
    if (mounted) {
      setState(() => _currentUser = null);
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final success = await BackupService.uploadBackupToDrive();
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Google Drive backup safaltapoorvak ho gaya! ☁' : 'Backup upload fail ho gaya.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup me error aaya. Internet check karein.')),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusExpired),
            SizedBox(width: 8),
            Text('Restore Data?'),
          ],
        ),
        content: const Text('Restore karne se current local studio members and ledger data overwrite ho jayega. Kya aap continue karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusExpired, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isRestoring = true);
              try {
                final success = await BackupService.restoreBackupFromDrive();
                if (mounted) {
                  setState(() => _isRestoring = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Restore safaltapoorvak ho gaya! 🎉' : 'Google Drive par backup file nahi mili.'),
                    ),
                  );
                }
              } catch (e) {
                setState(() => _isRestoring = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore fail: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Confirm Restore'),
          ),
        ],
      ),
    );
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
        title: const Text('Google Drive Backup & Restore'),
      ),
      body: SafeArea(
        child: _isCheckingUser
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Google Account Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GOOGLE ACCOUNT', style: AppTypography.microLabel(AppColors.champagneGold)),
                        const SizedBox(height: 10),
                        if (_currentUser != null) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: _currentUser!.photoUrl != null ? NetworkImage(_currentUser!.photoUrl!) : null,
                                backgroundColor: AppColors.champagneGoldMuted,
                                child: _currentUser!.photoUrl == null ? const Icon(Icons.person, color: AppColors.champagneGold) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_currentUser!.displayName ?? 'Google User', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primaryTextColor)),
                                    Text(_currentUser!.email, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _handleSignOut,
                                child: const Text('Sign Out', style: TextStyle(fontSize: 12, color: AppColors.statusExpired)),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text('Aapka Google account connected nahi hai. Backup lene ke liye sign in karein.', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _handleSignIn,
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('Sign In with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.champagneGold,
                              side: const BorderSide(color: AppColors.champagneGold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions Section
                  Text('BACKUP & RESTORE ACTIONS', style: AppTypography.microLabel(secondaryTextColor)),
                  const SizedBox(height: 10),

                  // Action 1: Backup Now
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Backup Now to Google Drive', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor)),
                        const SizedBox(height: 4),
                        Text('Local SQLite database, students, and ledger records ka backup Google Drive AppData me save karein.', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Backup Now ☁',
                          isLoading: _isBackingUp,
                          onPressed: _currentUser != null ? _handleBackup : _handleSignIn,
                        ),
                      ],
                    ),
                  ),

                  // Action 2: Restore from Drive
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('2. Restore from Google Drive', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor)),
                        const SizedBox(height: 4),
                        Text('Google Drive se latest backup payload download karke local database restore karein.', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _currentUser != null && !_isRestoring ? _handleRestore : _handleSignIn,
                          icon: _isRestoring
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cloud_download_outlined, size: 18),
                          label: const Text('Restore Data 🔄'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.champagneGold,
                            side: const BorderSide(color: AppColors.champagneGold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
