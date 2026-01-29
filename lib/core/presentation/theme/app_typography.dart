import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Signal design typography using Outfit font family.
abstract class AppTypography {
  /// Get the Outfit text theme for the app.
  static TextTheme get outfitTextTheme => GoogleFonts.outfitTextTheme();

  // Hero title - massive weight on home screen
  static TextStyle get heroTitle => GoogleFonts.outfit(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        height: 1,
      );

  // Timer display - extra large for visibility from 10+ feet
  static TextStyle get timerDisplay => GoogleFonts.outfit(
        fontSize: 96,
        fontWeight: FontWeight.w900,
        letterSpacing: -4,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Timer display - medium size
  static TextStyle get timerDisplayMedium => GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: -3,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Timer display - small size
  static TextStyle get timerDisplaySmall => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Round counter
  static TextStyle get roundDisplay => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  // Workout name / title
  static TextStyle get workoutTitle => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      );

  // Section headers
  static TextStyle get sectionHeader => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  // Strip item name (home page timer types)
  static TextStyle get stripName => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  // Body text
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  // Button text
  static TextStyle get buttonLarge => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      );

  static TextStyle get buttonMedium => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  // Labels
  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      );

  // Pill badge text
  static TextStyle get pillBadge => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      );

  // Summary values
  static TextStyle get summaryValue => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  // Summary labels
  static TextStyle get summaryLabel => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      );
}
