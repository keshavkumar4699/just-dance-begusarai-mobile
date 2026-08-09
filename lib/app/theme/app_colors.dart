import 'package:flutter/material.dart';

/// Studio Crow Design System - Color Tokens
abstract class AppColors {
  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF0E0E10);
  static const Color darkSurface = Color(0xFF17171C);
  static const Color darkCardBackground = Color(0xFF141418);
  static const Color darkPrimaryText = Color(0xFFF5F1E8);
  static const Color darkSecondaryText = Color(0xFF9E9EA6);
  static const Color darkHairline = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF141414);
  static const Color lightSecondaryText = Color(0xFF6E6E73);
  static const Color lightHairline = Color(0x14000000); // rgba(0,0,0,0.08)

  // Primary Accent - Champagne Gold
  static const Color champagneGold = Color(0xFFC8A24A);
  static const Color champagneGoldMuted = Color(0x29C8A24A);

  // Status Colors
  static const Color statusActive = Color(0xFF46A758);
  static const Color statusNearExpiry = Color(0xFFFFB224);
  static const Color statusExpired = Color(0xFFE5484D);
  static const Color statusInactive = Color(0xFF8B8B93);
  static const Color statusBlocked = Color(0xFF55555B);
}
