import 'package:flutter/material.dart';

class AppColors {
  // ---------- PRIMARY (blue) ----------
  static const Color primary = Color(0xFF2563EB);        // main blue
  static const Color primaryLight = Color(0xFF60A5FA);   // light blue
  static const Color primaryDark = Color(0xFF1D4ED8);    // deep blue
  static const Color primarySoft = Color(0xFFEFF6FF);    // very light blue tint

  // ---------- ACCENT (yellow) ----------
  static const Color accent = Color(0xFFFFC107);         // yellow accent
  static const Color accentSoft = Color(0xFFFFF8E1);     // soft yellow tint
  static const Color accentDark = Color(0xFFF59E0B);     // amber

  // ---------- BACKGROUND / SURFACE ----------
  static const Color background = Color(0xFFF5F7FB);     // off-white cool grey
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFFAFBFF);

  // ---------- TEXT ----------
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnYellow = Color(0xFF1F2937);

  // ---------- LINES ----------
  static const Color border = Color(0xFFE2E8F0);

  // ---------- STATUS ----------
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color live = Color(0xFF22C55E);

  // ---------- GLASS ----------
  static Color glassWhite = Colors.white.withValues(alpha: 0.55);
  static Color glassBorder = Colors.white.withValues(alpha: 0.6);
  static Color glassShadow = Colors.black.withValues(alpha: 0.08);

  // ---------- Keep legacy names working ----------
  static const Color warning = accent;
}