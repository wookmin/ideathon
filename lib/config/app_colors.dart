import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6DF3);

  static const Color primaryDark = Color(0xFF0A4FB8);
  static const Color primaryLight = Color(0xFFEAF3FF);
  static const Color primarySoft = Color(0xFFF3F8FF);

  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A0F6DF3);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF1F5F9);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color mapBlue = Color(0xFF0F6DF3);
  static const Color mapGlow = Color(0x660F6DF3);
  static const Color currentLocation = Color(0xFF2563EB);

  static const Color restaurant = Color(0xFFFF7043);
  static const Color cafe = Color(0xFF8B5CF6);
  static const Color shopping = Color(0xFF06B6D4);
  static const Color attraction = Color(0xFF22C55E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0F6DF3),
      Color(0xFF4D9BFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}