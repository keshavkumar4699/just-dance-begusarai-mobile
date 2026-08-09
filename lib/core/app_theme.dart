import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.darkBg,
        secondary: AppColors.gold,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkHairline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkHairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: _buttonTheme(Brightness.dark),
      outlinedButtonTheme: _outlineButtonTheme(Brightness.dark),
      inputDecorationTheme: _inputTheme(Brightness.dark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.darkHairline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      splashColor: AppColors.gold.withValues(alpha: 0.1),
      highlightColor: AppColors.gold.withValues(alpha: 0.05),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: AppColors.lightBg,
        secondary: AppColors.gold,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightHairline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightHairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: _buttonTheme(Brightness.light),
      outlinedButtonTheme: _outlineButtonTheme(Brightness.light),
      inputDecorationTheme: _inputTheme(Brightness.light),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      splashColor: AppColors.gold.withValues(alpha: 0.1),
      highlightColor: AppColors.gold.withValues(alpha: 0.05),
    );
  }

  static TextTheme _buildTextTheme(Brightness mode) {
    final isDark = mode == Brightness.dark;
    final color = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.6)
        : AppColors.lightText.withValues(alpha: 0.6);

    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: subColor,
        letterSpacing: 1.8,
      ),
    );
  }

  static ElevatedButtonThemeData _buttonTheme(Brightness mode) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: mode == Brightness.dark
            ? AppColors.darkBg
            : AppColors.lightBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlineButtonTheme(Brightness mode) {
    final hairline = mode == Brightness.dark
        ? AppColors.darkHairline
        : AppColors.lightHairline;
    final textColor = mode == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;

    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: hairline, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Brightness mode) {
    final hairline = mode == Brightness.dark
        ? AppColors.darkHairline
        : AppColors.lightHairline;
    final textColor = mode == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;

    return InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
    );
  }
}