import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../services/auth_service.dart';
import '../../app/widgets/app_button.dart';
import '../../app/widgets/app_scaffold.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await AuthService().authenticate();

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppScaffold(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.champagneGoldMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.champagneGold, width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 38,
                  color: AppColors.champagneGold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'STUDIO CROW LOCKED',
                style: AppTypography.microLabel(AppColors.champagneGold),
              ),
              const SizedBox(height: 8),
              Text(
                'Identity Verify Karein',
                style: AppTypography.headingMedium(primaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'App access karne ke liye Android system biometric ya screen lock ka prayog karein.',
                style: AppTypography.bodySmall(secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Unlock Karein',
                  icon: Icons.fingerprint,
                  isLoading: _isAuthenticating,
                  onPressed: _authenticate,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'System Lock Fallback PIN: 2026',
                style: AppTypography.bodySmall(secondaryTextColor.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
