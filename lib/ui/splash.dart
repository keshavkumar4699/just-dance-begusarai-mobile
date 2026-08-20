/// Just Dance — branded splash: dark bg, gold hairline, 600ms logo
/// scale-fade. Total time under 900ms.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import 'widgets/common.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _doneCalled = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    Future.delayed(const Duration(milliseconds: 850), _finish);
  }

  void _finish() {
    if (_doneCalled || !mounted) return;
    _doneCalled = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final curved = CurvedAnimation(parent: _c, curve: Motion.curve);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: const AppLogo(size: 120),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: curved,
              child: Text(
                kAppName.toUpperCase(),
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: curved,
              child: Container(width: 56, height: 1, color: c.gold),
            ),
          ],
        ),
      ),
    );
  }
}
