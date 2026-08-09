import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> initTheme() async {
    final savedTheme = await DatabaseHelper().getSetting('theme');
    if (savedTheme == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
      await DatabaseHelper().setSetting('theme', 'light');
    } else {
      themeModeNotifier.value = ThemeMode.dark;
      await DatabaseHelper().setSetting('theme', 'dark');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await DatabaseHelper().setSetting('theme', mode == ThemeMode.light ? 'light' : 'dark');
  }
}
