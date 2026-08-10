import 'package:flutter/material.dart';
import '../constants.dart';

/// Helper to set a weight on the bundled Plus Jakarta Sans variable font.
/// Usage: TextStyle style = wt(base, 700, size: 18, color: ...)
TextStyle wt(
  TextStyle? base, {
  required int weight,
  double? size,
  Color? color,
  double? height,
  FontStyle? fontStyle,
  double? letterSpacing,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontVariations: [FontVariation('wght', weight.toDouble())],
    fontSize: size ?? base?.fontSize,
    color: color ?? base?.color,
    height: height ?? base?.height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

/// Studio Crow theme - dark / light, champagne gold accent, geometric sans font.
class AppTheme {
  static ThemeData dark() => _build(
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        text: AppColors.darkText,
        hairline: AppColors.darkHairline,
        brightness: Brightness.dark,
      );

  static ThemeData light() => _build(
        bg: AppColors.lightBg,
        card: AppColors.lightCard,
        text: AppColors.lightText,
        hairline: AppColors.lightHairline,
        brightness: Brightness.light,
      );

  static ThemeData _build({
    required Color bg,
    required Color card,
    required Color text,
    required Color hairline,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.gold,
      onPrimary: AppColors.darkBg,
      secondary: AppColors.gold,
      onSecondary: AppColors.darkBg,
      error: AppColors.expired,
      onError: Colors.white,
      surface: card,
      onSurface: text,
      outline: hairline,
      outlineVariant: hairline,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: InkRipple.splashFactory,
    );
    final body = TextStyle(fontFamily: 'PlusJakartaSans', color: text);
    return base.copyWith(
      textTheme: TextTheme(
        displaySmall: wt(body, weight: 800, size: 30),
        headlineMedium: wt(body, weight: 700, size: 24),
        headlineSmall: wt(body, weight: 700, size: 20),
        titleLarge: wt(body, weight: 700, size: 18),
        titleMedium: wt(body, weight: 600, size: 16),
        titleSmall: wt(body, weight: 600, size: 14),
        bodyLarge: wt(body, weight: 400, size: 16),
        bodyMedium: wt(body, weight: 400, size: 14),
        bodySmall: wt(body, weight: 400, size: 12),
        labelLarge: wt(body, weight: 600, size: 14),
        labelMedium: wt(body, weight: 500, size: 12),
        labelSmall: wt(body, weight: 600, size: 10, letterSpacing: 1.2),
      ),
      dividerColor: hairline,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: wt(body, weight: 700, size: 18),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF2A2A2E) : const Color(0xFF26262B),
        contentTextStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? const Color(0xFF1C1C1F) : const Color(0xFFF1EFE9),
        hintStyle: wt(body, weight: 400, size: 14, color: AppColors.greyIcon),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.expired),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.expired),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1C1C1F) : const Color(0xFFF1EFE9),
        side: BorderSide(color: hairline),
        labelStyle: wt(body, weight: 500, size: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold : AppColors.greyIcon,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.35)
              : hairline,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.gold),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 220ms fade + 8dp slide-up page transition (spec: page transitions).
class FadeUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
