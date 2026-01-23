import 'package:flutter/material.dart';

/// App color palette optimized for high contrast gym visibility.
abstract class AppColors {
  // Primary colors - energetic orange for WOD theme
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F5C);
  static const Color primaryDark = Color(0xFFE55A25);

  // Secondary colors - cool blue for contrast
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color secondaryLight = Color(0xFF7EE8E0);
  static const Color secondaryDark = Color(0xFF3CB5AD);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF2196F3);

  // Timer state colors
  static const Color work = primary;
  static const Color rest = Color(0xFF4ECDC4);
  static const Color prepare = Color(0xFFFFC107);
  static const Color complete = success;
  static const Color paused = Color(0xFF9E9E9E);

  // Dark theme backgrounds
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2D2D2D);

  // Light theme backgrounds
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Text colors - dark theme
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textDisabledDark = Color(0xFF666666);

  // Text colors - light theme
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // Timer display colors (high contrast for visibility)
  static const Color timerTextDark = Color(0xFFFFFFFF);
  static const Color timerTextLight = Color(0xFF212121);
}
