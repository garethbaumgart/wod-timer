import 'package:flutter/material.dart';

/// Signal design color palette - deep ink background with neon green accent
/// and colored sidebar lines per timer type.
abstract class AppColors {
  // Primary accent - neon green
  static const Color primary = Color(0xFF00FF88);
  static const Color primaryLight = Color(0xFF66FFB2);
  static const Color primaryDark = Color(0xFF00CC6E);

  // Brand - neon orange (1.3.1): the wordmark's full stop went pink and the
  // headings white, so the orange now belongs to For Time alone.
  static const Color brand = Color(0xFFFF6B1A);

  // Secondary - light blue (For Time accent)
  static const Color secondary = Color(0xFF00AAFF);
  static const Color secondaryLight = Color(0xFF66CCFF);
  static const Color secondaryDark = Color(0xFF0088CC);

  // Timer type accent colors (1.3.1: one meaning each). The mode bar, its
  // Home timeline, the live clock and AGAIN / RESUME all wear this colour.
  static const Color forTimeAccent = Color(0xFFFF6B1A); // Orange (brand)
  static const Color emomAccent = Color(0xFFFF0088); // Pink
  static const Color amrapAccent = Color(0xFF00AAFF); // Blue
  static const Color tabataAccent = Color(0xFF00FF88); // Green (work)

  // Semantic colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF00AAFF);

  // Timer state colors. Rest is pink everywhere (Tabata blocks and the rest
  // phase) and the get-ready countdown is white in every mode, so neither
  // can be confused with a mode colour.
  static const Color work = Color(0xFF00FF88);
  static const Color rest = Color(0xFFFF0088);
  static const Color prepare = Color(0xFFFFFFFF);
  static const Color complete = Color(0xFF00FF88);
  static const Color paused = Color(0xFF8A8A93);

  // Setup START slab.
  static const Color start = Color(0xFF00FF88);

  // Surfaces (1.3.1): the soft fill behind a wheel's selected row and the
  // neutral slab cells (PAUSE, DONE); the timeline track for parts not yet
  // run; the HOLD TO STOP cell and its red.
  static const Color soft = Color(0xFF16172A);
  static const Color track = Color(0xFF24253A);
  static const Color stopSlab = Color(0xFF1A0E14);
  static const Color stopRed = Color(0xFFFF4444);

  // Stopwatch bezel: the ring, and a tick past the value.
  static const Color bezelRing = Color(0xFF1E1F33);
  static const Color bezelTickOff = Color(0xFF2E2E44);
  static const Color bezelKnob = Color(0xFFFF0088);

  // A wheel's unselected neighbour on the end screen.
  static const Color wheelDim = Color(0xFF3A3D58);

  // Dark theme backgrounds (Signal: deep ink #050510)
  static const Color backgroundDark = Color(0xFF050510);
  static const Color surfaceDark = Color(0xFF0A0A1A);
  static const Color cardDark = Color(0xFF0E0E1E);

  // Light theme backgrounds (kept for compatibility)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Text colors - dark theme
  // Functional greys sit at or above WCAG AA on #050510 (UX review 14 Jul
  // 2026: previous #666/#555/#333 measured 3.5:1 / 2.7:1 / 1.6:1).
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9A9AA2);
  static const Color textDisabledDark = Color(0xFF6A6A72);

  // Text colors - light theme
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // Timer display colors (high contrast for visibility)
  static const Color timerTextDark = Color(0xFFFFFFFF);
  static const Color timerTextLight = Color(0xFF212121);

  // Label/hint text (brighter than disabled, dimmer than secondary)
  static const Color textHintDark = Color(0xFF8A8A93);

  // Border/divider colors (borders >=3:1 so controls read as enabled)
  static const Color border = Color(0xFF3A3A44);
  static const Color borderLight = Color(0xFF55555E);
  static const Color divider = Color(0xFF16161F);

  // Progress bar track (visible against the ink background)
  static const Color progressTrack = Color(0xFF2A2A34);
}
