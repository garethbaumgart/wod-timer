import 'package:flutter/material.dart';

/// Signal design color palette - deep ink background with neon green accent
/// and colored sidebar lines per timer type.
abstract class AppColors {
  // Primary accent - neon green
  static const Color primary = Color(0xFF00FF88);
  static const Color primaryLight = Color(0xFF66FFB2);
  static const Color primaryDark = Color(0xFF00CC6E);

  // Secondary - light blue (For Time accent)
  static const Color secondary = Color(0xFF00AAFF);
  static const Color secondaryLight = Color(0xFF66CCFF);
  static const Color secondaryDark = Color(0xFF0088CC);

  // Timer type accent colors
  static const Color amrapAccent = Color(0xFF00FF88); // Green
  static const Color forTimeAccent = Color(0xFF00AAFF); // Blue
  static const Color emomAccent = Color(0xFFFF0088); // Pink/Magenta
  static const Color tabataAccent = Color(0xFFFFAA00); // Orange

  // Semantic colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF00AAFF);

  // Timer state colors
  static const Color work = Color(0xFF00FF88);
  static const Color rest = Color(0xFF00AAFF);
  static const Color prepare = Color(0xFFFFAA00);
  static const Color complete = Color(0xFF00FF88);
  static const Color paused = Color(0xFF666666);

  // Dark theme backgrounds (Signal: deep ink #050510)
  static const Color backgroundDark = Color(0xFF050510);
  static const Color surfaceDark = Color(0xFF0A0A1A);
  static const Color cardDark = Color(0xFF0E0E1E);

  // Light theme backgrounds (kept for compatibility)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Text colors - dark theme
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF666666);
  static const Color textDisabledDark = Color(0xFF333333);

  // Text colors - light theme
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // Timer display colors (high contrast for visibility)
  static const Color timerTextDark = Color(0xFFFFFFFF);
  static const Color timerTextLight = Color(0xFF212121);

  // Border/divider colors
  static const Color border = Color(0xFF1A1A1A);
  static const Color divider = Color(0xFF0E0E0E);
}
