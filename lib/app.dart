import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';
import 'services/photo_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// Root widget: theme wiring, app lock gate, lifecycle relock.
class StudioCrowApp extends StatefulWidget {
  const StudioCrowApp({super.key});

  @override
  State<StudioCrowApp> createState() => _StudioCrowAppState();
}

class _StudioCrowAppState extends State<StudioCrowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-relock when the app goes to background (Google-Photos-Locked-Folder style).
    if (state == AppLifecycleState.paused && AppState.instance.deviceLockOn) {
      AppState.instance.locked = true;
    }
    // Recompute statuses on resume (midnight boundary while away).
    if (state == AppLifecycleState.resumed) {
      AppState.instance.refreshStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        if (state.loading) {
          // Very first frame - plain dark to avoid any flash.
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Studio Crow',
            theme: AppTheme.dark(),
            home: const SplashScreen(),
          );
        }
        final theme = state.dark ? AppTheme.dark() : AppTheme.light();
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Studio Crow',
          theme: theme,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            child: state.locked
                ? const LockScreen(key: ValueKey('lock'))
                : const HomeShell(key: ValueKey('home')),
          ),
        );
      },
    );
  }
}
