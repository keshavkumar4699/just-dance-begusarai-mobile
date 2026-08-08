import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppFonts {
  // Heading typography - Playfair Display (Serif Luxury)
  static TextStyle displayHeader({Color color = AppColors.gold, double fontSize = 28, FontWeight fontWeight = FontWeight.bold}) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
    );
  }

  static TextStyle titleHeader({Color color = AppColors.ivory, double fontSize = 20, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  // Body typography - Manrope (Clean Modern Sans-Serif)
  static TextStyle bodyText({Color color = AppColors.textPrimary, double fontSize = 14, FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle subtitleText({Color color = AppColors.textSecondary, double fontSize = 12, FontWeight fontWeight = FontWeight.w400}) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle numberText({Color color = AppColors.gold, double fontSize = 16, FontWeight fontWeight = FontWeight.bold}) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
    );
  }
}
