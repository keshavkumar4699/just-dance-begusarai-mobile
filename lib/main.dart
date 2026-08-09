import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'services/database_helper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DatabaseHelper().database;
  runApp(const StudioCrowApp());
}

class StudioCrowApp extends StatefulWidget {
  const StudioCrowApp({super.key});

  @override
  State<StudioCrowApp> createState() => _StudioCrowAppState();
}

class _StudioCrowAppState extends State<StudioCrowApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final db = DatabaseHelper();
    final themeVal = await db.getSetting('theme');
    setState(() {
      _themeMode = themeVal == 'light' ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudioCrow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}