import 'package:flutter/material.dart';

/// Studio Crow Typography Specifications
abstract class AppTypography {
  static const String headingFont = 'PlayfairDisplay';
  static const String bodyFont = 'Manrope';

  static TextStyle headingLarge(Color color) => TextStyle(
        fontFamily: headingFont,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle headingMedium(Color color) => TextStyle(
        fontFamily: headingFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
      );

  static TextStyle headingSmall(Color color) => TextStyle(
        fontFamily: headingFont,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle microLabel(Color color) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
      );
}
