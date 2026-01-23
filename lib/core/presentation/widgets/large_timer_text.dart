import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// Size variants for the timer display.
enum TimerTextSize {
  /// Extra large (120px) - readable from 10+ feet.
  large,

  /// Medium (80px) - for secondary timers.
  medium,

  /// Small (48px) - for compact displays.
  small,
}

/// A large timer text widget optimized for high visibility.
///
/// Designed to be readable from 10+ feet away in gym environments.
/// Uses tabular figures for stable width during countdown.
class LargeTimerText extends StatelessWidget {
  const LargeTimerText({
    required this.time,
    super.key,
    this.size = TimerTextSize.large,
    this.color,
  });

  /// The time to display (e.g., "10:00", "0:45").
  final String time;

  /// The size variant of the timer text.
  final TimerTextSize size;

  /// Optional color override. Uses theme default if not specified.
  final Color? color;

  TextStyle get _baseStyle {
    return switch (size) {
      TimerTextSize.large => AppTypography.timerDisplay,
      TimerTextSize.medium => AppTypography.timerDisplayMedium,
      TimerTextSize.small => AppTypography.timerDisplaySmall,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.timerTextDark : AppColors.timerTextLight;

    return Text(
      time,
      style: _baseStyle.copyWith(color: color ?? defaultColor),
      textAlign: TextAlign.center,
    );
  }
}
