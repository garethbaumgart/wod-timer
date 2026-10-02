import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/repeating_icon_button.dart';

/// One setup value: a label, the value, and a − / + pair either side of it.
///
/// Controlled: the page owns the value and passes it back in, so anything
/// that changes the value elsewhere (Tabata's "Reset to classic") always
/// shows here. Each number on a setup screen appears exactly once, here.
class SetupStepper extends StatelessWidget {
  const SetupStepper({
    required this.label,
    required this.value,
    required this.semanticValue,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
    super.key,
    this.labelColor,
  });

  /// Short label above the value ("EVERY", "ROUNDS").
  final String label;

  /// Display string ("1:00", "10", "20s").
  final String value;

  /// What a screen reader says for the value ("1 minute").
  final String semanticValue;

  /// Null when the value is at its minimum.
  final VoidCallback? onDecrement;

  /// Null when the value is at its maximum.
  final VoidCallback? onIncrement;

  final String decrementLabel;
  final String incrementLabel;

  /// Phase colour for Tabata's WORK / REST labels. The label carries it
  /// alone: a dot beside it was a second signal for the same thing.
  final Color? labelColor;

  static const double _buttonSize = 60;
  static const double _gap = 12;
  static const double _valueWidth = 184;

  // Compact: three across a landscape phone (Tabata) in one row.
  static const double _compactButtonSize = 52;
  static const double _compactGap = 8;
  static const double _compactValueWidth = 104;

  /// Fixed so steppers side by side keep their buttons level, whatever
  /// FittedBox does to a wide value like "1:05".
  static const double _compactValueHeight = 72;

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? AppColors.textSecondaryDark;
    final compact = CompactSetupSteppers.of(context);
    final buttonSize = compact ? _compactButtonSize : _buttonSize;
    final gap = compact ? _compactGap : _gap;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 15,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepeatingIconButton(
              icon: Icons.remove,
              onPressed: onDecrement,
              semanticsLabel: decrementLabel,
              size: buttonSize,
              iconSize: compact ? 24 : 26,
            ),
            SizedBox(width: gap),
            SizedBox(
              width: compact ? _compactValueWidth : _valueWidth,
              height: compact ? _compactValueHeight : null,
              child: Semantics(
                label: '$label: $semanticValue',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: AppTypography.timerDisplayMedium.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontSize: 72,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            RepeatingIconButton(
              icon: Icons.add,
              onPressed: onIncrement,
              semanticsLabel: incrementLabel,
              size: buttonSize,
              iconSize: compact ? 24 : 26,
            ),
          ],
        ),
      ],
    );
  }
}

/// Steppers below this render compact (52pt buttons, 8pt gaps, a 104pt
/// value box), so a landscape setup can put them side by side in one row.
class CompactSetupSteppers extends InheritedWidget {
  const CompactSetupSteppers({required super.child, super.key});

  /// Whether [context] sits under a [CompactSetupSteppers].
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompactSetupSteppers>() !=
      null;

  @override
  bool updateShouldNotify(CompactSetupSteppers oldWidget) => false;
}

/// Clock format used across setup: "0:45", "1:00", "10:00".
String setupClock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// A phase length the way athletes say it: "20s" under a minute, "2:00"
/// from a minute up. Used for Tabata values, config lines and Home.
String setupPhase(int totalSeconds) =>
    totalSeconds < 60 ? '${totalSeconds}s' : setupClock(totalSeconds);

/// Spoken form of a duration: "1 minute 30 seconds", "45 seconds".
String setupSpokenDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final parts = <String>[
    if (minutes > 0) '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
    if (seconds > 0 || minutes == 0)
      '$seconds ${seconds == 1 ? 'second' : 'seconds'}',
  ];
  return parts.join(' ');
}
