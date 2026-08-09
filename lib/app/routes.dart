import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/lock/app_lock_screen.dart';
import 'widgets/app_scaffold.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String lock = '/lock';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        lock: (context) => const AppLockScreen(),
        home: (context) => const AppScaffold(),
      };
}
