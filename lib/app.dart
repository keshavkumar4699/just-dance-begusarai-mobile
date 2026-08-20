/// Just Dance — root widget: theme + splash -> lock -> home gating.
library;

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/store.dart';
import 'services/backup_service.dart';
import 'ui/home_shell.dart';
import 'ui/lock_screen.dart';
import 'ui/splash.dart';

class JustDanceApp extends StatelessWidget {
  final AppStore store;
  const JustDanceApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        title: 'Just Dance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(dark: store.isDark),
        darkTheme: AppTheme.build(dark: true),
        themeMode: store.isDark ? ThemeMode.dark : ThemeMode.light,
        home: RootGate(store: store),
      ),
    );
  }
}

class RootGate extends StatefulWidget {
  final AppStore store;
  const RootGate({super.key, required this.store});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  bool _splashDone = false;
  bool _unlocked = false;

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
    final store = widget.store;
    if (state == AppLifecycleState.paused) {
      // Auto-relock on background (Google-Photos-Locked-Folder behavior).
      // Only on real background (paused), never on inactive (shade/permissions),
      // and not while an in-app external flow (photo pick) is running.
      if (store.deviceLockOn && _unlocked && !store.suppressLock) {
        setState(() => _unlocked = false);
      }
    }
    if (state == AppLifecycleState.resumed) {
      // Statuses are realtime — recompute on resume (midnight rollovers,
      // expiries) and retry a pending backup.
      store.recomputeAll();
      if (store.backupPending) BackupService.instance.backupNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (!_splashDone) {
      return SplashScreen(onDone: () => setState(() => _splashDone = true));
    }
    // Lock overlays the shell instead of replacing it, so any in-progress
    // flow (photo picker, add-member form, welcome popup) survives a relock.
    return Stack(
      children: [
        HomeShell(store: store),
        if (store.deviceLockOn && !_unlocked)
          LockScreen(onUnlocked: () => setState(() => _unlocked = true)),
      ],
    );
  }
}
