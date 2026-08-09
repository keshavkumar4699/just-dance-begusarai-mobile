import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../services/theme_service.dart';
import 'routes.dart';

class StudioCrowApp extends StatelessWidget {
  const StudioCrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Studio Crow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
