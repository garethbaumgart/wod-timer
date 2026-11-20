import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';

/// PROTOTYPE ONLY. The live and end screens' text styles and the clock's
/// sizing rule, copied from `TimerActivePage` (where they are private) so
/// the prototype screens are drawn with the same numbers.
abstract class LiveStyles {
  static const double sidePad = 14;
  static const double timelineHeight = 14;
  static const double clockShare = 0.42;
  static const double phaseSlot = 40;

  /// The space the live screen keeps above the phase word today.
  static const double topPad = 30;

  static TextStyle phase(Color color, double size) =>
      AppTypography.sectionHeader.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: size * 0.06,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle bigNumber(double size) => AppTypography.timerDisplay
      .copyWith(color: Colors.white, fontSize: size, letterSpacing: -1);

  static TextStyle hint(double size) => AppTypography.sectionHeader.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: size * 0.1,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle unit(double size) => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: size * 0.14,
    height: 1,
  );

  static TextStyle hero(Color color, double size) =>
      AppTypography.timerDisplay.copyWith(
        color: color,
        fontSize: size,
        letterSpacing: -size * 0.02,
        height: ClockSpec.lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

/// PROTOTYPE ONLY. The live page hides the system UI while it is open. The
/// prototype's live and end screens are separate pages, and a page is
/// disposed only after the next one is up, so they share one count: the
/// system UI comes back when the last of them has gone.
abstract class ImmersiveHold {
  static int _holders = 0;

  static void acquire() {
    _holders++;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static void release() {
    _holders--;
    if (_holders <= 0) {
      _holders = 0;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}

/// The clock's fixed size for a workout: the font that fits its longest
/// value in the width, capped by the slot, with the line box trimmed to the
/// glyphs.
class ClockSpec {
  const ClockSpec({required this.style, required this.boxHeight});

  factory ClockSpec.fit({
    required String reference,
    required double maxWidth,
    required double slotHeight,
    required TextStyle Function(TextStyle style) resolve,
  }) {
    final size = fontSizeFor(
      reference: reference,
      style: resolve(baseStyle(100)),
      maxWidth: maxWidth,
      slotHeight: slotHeight,
    );
    final style = resolve(baseStyle(size));
    return ClockSpec(
      style: style,
      boxHeight: GlyphInk.boxHeight(reference, style),
    );
  }

  final TextStyle style;
  final double boxHeight;

  static const double lineHeight = 0.76;

  static TextStyle baseStyle(double size) =>
      AppTypography.timerDisplay.copyWith(
        fontSize: size,
        letterSpacing: -size * 0.02,
        height: lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static double fontSizeFor({
    required String reference,
    required TextStyle style,
    required double maxWidth,
    required double slotHeight,
  }) {
    final width100 = GlyphInk.boxWidth(reference, style);
    final height100 = GlyphInk.boxHeight(reference, style);
    final byWidth = width100 > 0 ? maxWidth / width100 * 100 : slotHeight;
    final byHeight = height100 > 0 ? slotHeight / height100 * 100 : slotHeight;
    return math.max(8, math.min(byWidth, byHeight));
  }
}
