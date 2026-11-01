import 'package:flutter/material.dart';

/// Apple Minimalist & Clean Color Palette (Koyu Lacivert Teması)
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFF0A1128);
  static const Color surface = Color(0xFF131D35);
  static const Color card = Color(0xFF1B2845);
  static const Color cardLight = Color(0xFF223354);
  static const Color foreground = Color(0xFFFFFFFF);

  // Accents & Borders
  static const Color accent = Color(0xFF274472);
  static const Color accentLight = Color(0xFF3A86FF);
  static const Color extraColorLightBlue = Color(0xFF3A86FF);
  static const Color todayBorder = Color(0xFF3A86FF);
  static const Color divider = Color(0xFF1E3050);

  // Calendar / Domain Specific
  static const Color cityInner = Color(0xFF48BFE3);
  static const Color cityOuter = Color(0xFFF9A826);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textHint = Color(0xFF556677);

  // Semantic Status
  static const Color success = Color(0xFF06D6A0);
  static const Color danger = Color(0xFFEF476F);
  static const Color warning = Color(0xFFF9A826);

  // Semantic Aliases
  static const Color profit = success;
  static const Color loss = danger;
  static const Color primary = accentLight;
  static const Color border = accent;
  static const Color borderSubtle = divider;
  static const Color profitBg = Color(0x1A06D6A0);
  static const Color lossBg = Color(0x1AEF476F);
  static const Color warningBg = Color(0x1AF9A826);
  static const Color textMuted = textHint;
}

