import 'package:flutter/material.dart';
import '../constants.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Studio Crow branded splash: dark bg, gold hairline, logo scale-fade.
/// Max 900ms, then goes to lock screen or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Lock gate: first launch always asks device auth (if enabled).
      final state = AppState.instance;
      state.locked = true;
      if (!state.deviceLockOn) state.locked = false;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
              child: ScaleTransition(
                scale: Tween(begin: 0.82, end: 1.0).animate(
                  CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.4),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Container(
              width: 56,
              height: 1.4,
              color: AppColors.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'STUDIO CROW',
              style: wt(Theme.of(context).textTheme.labelMedium,
                  weight: 800, letterSpacing: 5, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

