import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../constants.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Device-lock gate (face / fingerprint / device PIN - same behavior as
/// Google Photos "Locked Folder"). No custom PIN, no passwords.
///
/// The system authentication prompt (face / fingerprint / PIN) is triggered
/// automatically as soon as the lock screen appears - no extra tap needed.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _busy = false;
  String? _error;

  /// True when auth is impossible on this device (no biometrics + no lock).
  bool _notEnrolled = false;

  /// Guards against auto-triggering twice per lock session.
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask for the phone's authentication right away (after first frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 300), _unlock);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-relocked while backgrounded: re-ask as soon as the app is resumed.
    if (state == AppLifecycleState.resumed && !_attempted) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_busy || _attempted) return;
    _attempted = true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // biometricOnly: false lets the system offer face/fingerprint AND the
      // device PIN/pattern/password as fallback - whatever the phone has.
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Studio Crow',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (ok && mounted) {
        AppState.instance.locked = false;
      } else if (mounted) {
        // User cancelled the prompt - offer a retry button.
        setState(() {
          _busy = false;
          _error = 'Locked - tap Unlock to try again';
          _attempted = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Unlock failed (${e.code}) - tap Unlock to retry';
          _attempted = false;
        });
        if (_isNotEnrolled(e.code)) {
          setState(() => _notEnrolled = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Unlock failed - tap Unlock to retry';
          _attempted = false;
        });
      }
    }
  }

  /// Error codes when the phone has no usable security (biometric or lock).
  bool _isNotEnrolled(String code) => switch (code) {
        'NotAvailable' ||
        'NotEnrolled' ||
        'NoLockScreenLocked' ||
        'PasscodeNotSet' ||
        'PasscodeNotEnrolled' =>
          true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.4),
              ),
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 26),
            Container(width: 56, height: 1.4, color: AppColors.gold.withValues(alpha: 0.7)),
            const SizedBox(height: 18),
            Text(
              'STUDIO CROW',
              style: wt(Theme.of(context).textTheme.labelMedium,
                  weight: 800, letterSpacing: 5, color: AppColors.gold),
            ),
            const SizedBox(height: 34),
            Text(
              'Unlock with your phone lock',
              style: wt(Theme.of(context).textTheme.bodyMedium,
                  weight: 500, color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 26),
            // Unlock button (also acts as retry after a cancelled prompt).
            ScaleTap(
              onTap: _busy ? null : _unlock,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.gold, width: 1.3),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock',
                            style: wt(Theme.of(context).textTheme.labelLarge,
                                weight: 700, color: AppColors.gold),
                          ),
                        ],
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: wt(Theme.of(context).textTheme.bodySmall,
                      weight: 500, color: AppColors.nearExpiry)),
            ],
            if (_notEnrolled) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'This phone has no face / fingerprint / PIN set up.\nSet a screen lock in phone Settings, then reopen the app - or continue without lock.',
                  textAlign: TextAlign.center,
                  style: wt(Theme.of(context).textTheme.bodySmall,
                      weight: 500, color: scheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(height: 14),
              ScaleTap(
                onTap: () {
                  AppState.instance.setDeviceLock(false);
                  AppState.instance.locked = false;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyIcon),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('Continue without lock',
                      style: wt(Theme.of(context).textTheme.labelMedium,
                          weight: 600, color: scheme.onSurface)),
                ),
              ),
            ],
            const Spacer(flex: 3),
            Text(
              'App: ${AppInfo.name} v${AppInfo.version}',
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 500, color: scheme.onSurface.withValues(alpha: 0.35)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
