import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';

/// One fact on an end screen: a small label over a value ("TIME", "10:00").
@immutable
class EndFact {
  const EndFact(this.label, this.value);

  final String label;
  final String value;

  /// A wall-clock time the way the phone shows it: "6:42 am", or "18:42"
  /// when the phone uses 24-hour time.
  static String clockTime(DateTime t, {required bool use24h}) {
    final minutes = t.minute.toString().padLeft(2, '0');
    if (use24h) return '${t.hour}:$minutes';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:$minutes ${t.hour < 12 ? 'am' : 'pm'}';
  }

  /// Seconds of work in a Tabata that ran [elapsed] seconds: every full
  /// round's work, plus the part of the last round's work it reached.
  static int tabataWorkSeconds(
    int elapsed, {
    required int work,
    required int rest,
  }) {
    final round = work + rest;
    if (round <= 0) return 0;
    final full = elapsed ~/ round;
    final part = elapsed % round;
    return full * work + (part < work ? part : work);
  }

  @override
  bool operator ==(Object other) =>
      other is EndFact && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => '$label $value';
}

/// The end screen's three fact tiles (2.5.1): soft rounded boxes side by
/// side, like the bands behind the setup wheels. A value too wide for its
/// tile scales down rather than wrapping.
class EndFactTiles extends StatelessWidget {
  const EndFactTiles({required this.facts, super.key});

  final List<EndFact> facts;

  /// The largest font the AMRAP rounds wheel takes above the tiles.
  static const double amrapWheelCap = 100;

  static const double labelSize = 11;
  static const double valueSize = 28;
  static const double padding = 16;
  static const double spacing = 8;

  /// The tiles cap the text size so three still fit across a phone.
  static const double maxTextScale = 1.4;

  static TextStyle labelStyle() => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: labelSize,
    fontWeight: FontWeight.w800,
    letterSpacing: labelSize * 0.14,
    height: 1.1,
  );

  static TextStyle valueStyle() => AppTypography.timerDisplay.copyWith(
    color: AppColors.textPrimaryDark,
    fontSize: valueSize,
    letterSpacing: -valueSize * 0.02,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextScaler _scaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxTextScale);

  /// The tiles' height for the text size in [context].
  static double heightOf(BuildContext context) {
    final scaler = _scaler(context);
    return 2 * padding +
        GlyphInk.boxHeight(
          'TIME',
          GlyphInk.resolve(context, labelStyle()),
          textScaler: scaler,
        ) +
        8 +
        GlyphInk.boxHeight(
          '10:00',
          GlyphInk.resolve(context, valueStyle()),
          textScaler: scaler,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scaler = _scaler(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          spacing: spacing,
          children: [
            for (final fact in facts)
              Expanded(
                // One line each in the end screen's spoken summary.
                child: Semantics(
                  label: '${fact.label.toLowerCase()} ${fact.value}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: padding,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      spacing: 8,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            fact.label,
                            maxLines: 1,
                            style: labelStyle(),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            fact.value,
                            maxLines: 1,
                            style: valueStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
