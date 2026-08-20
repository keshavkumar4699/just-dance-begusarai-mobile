/// Just Dance — Instagram-inspired theme system.
/// Dark default, optional light, champagne gold accent. One font: Inter.
library;

import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  // Surfaces & text
  Color get bg => isDark ? const Color(0xFF0E0E10) : const Color(0xFFFAF8F4);
  Color get surface => isDark ? const Color(0xFF161619) : Colors.white;
  Color get surface2 => isDark ? const Color(0xFF1C1C20) : const Color(0xFFF1EEE8);
  Color get text => isDark ? const Color(0xFFF5F1E8) : const Color(0xFF141414);
  Color get textMuted => isDark ? const Color(0xFF8B8B93) : const Color(0xFF6E6E76);
  Color get hairline =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x14000000); // rgba 0.08

  // Accent
  Color get gold => const Color(0xFFC8A24A);
  Color get goldSoft => const Color(0xFFC8A24A).withValues(alpha: 0.14);

  // State colors
  Color get active => const Color(0xFF46A758);
  Color get nearExpiry => const Color(0xFFFFB224);
  Color get expired => const Color(0xFFE5484D);
  Color get inactive => const Color(0xFF8B8B93);
  Color get blocked => const Color(0xFF55555B);

  static AppColors of(BuildContext context) =>
      AppColors(Theme.of(context).brightness == Brightness.dark);
}

class AppTheme {
  static ThemeData build({required bool dark}) {
    final c = AppColors(dark);
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final textTheme = base.textTheme.apply(fontFamily: 'Inter');

    return base.copyWith(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      primaryColor: c.gold,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: c.gold,
        onPrimary: Colors.black,
        secondary: c.gold,
        onSecondary: Colors.black,
        error: c.expired,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      textTheme: textTheme.copyWith(
        // Bold geometric headings, regular body, tiny uppercase labels.
        headlineSmall: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text),
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: c.text),
        titleMedium: textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: c.text),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: c.text, height: 1.35),
        bodySmall: textTheme.bodySmall?.copyWith(color: c.textMuted),
        labelSmall: textTheme.labelSmall?.copyWith(
            color: c.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            fontSize: 10.5),
      ),
      dividerColor: c.hairline,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardColor: c.surface,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface2,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.gold, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.expired),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.expired, width: 1.2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surface2,
        selectedColor: c.gold,
        labelStyle: textTheme.bodySmall?.copyWith(color: c.text),
        side: BorderSide(color: c.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.black : c.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.gold : c.surface2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.gold),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bg,
        selectedItemColor: c.gold,
        unselectedItemColor: c.textMuted,
      ),
    );
  }
}
