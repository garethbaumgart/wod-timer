import 'package:flutter/material.dart';

/// App typography with large, readable text for gym environments.
abstract class AppTypography {
  // Timer display - extra large for visibility from 10+ feet
  static const TextStyle timerDisplay = TextStyle(
    fontSize: 120,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Timer display - medium size
  static const TextStyle timerDisplayMedium = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Timer display - small size
  static const TextStyle timerDisplaySmall = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Round counter
  static const TextStyle roundDisplay = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  // Workout name / title
  static const TextStyle workoutTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  // Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Button text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}
