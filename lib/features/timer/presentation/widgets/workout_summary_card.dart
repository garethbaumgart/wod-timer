import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// A Signal-design summary box showing workout configuration.
///
/// Uses a green-tinted transparent background with green border,
/// displaying label/value pairs in the Signal design language.
class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({
    required this.timerType,
    required this.totalDuration,
    super.key,
    this.rounds,
    this.workDuration,
    this.restDuration,
    this.intervalDuration,
  });

  /// The type of timer (e.g., "AMRAP", "For Time", "EMOM", "Tabata").
  final String timerType;

  /// Total estimated workout duration.
  final Duration totalDuration;

  /// Number of rounds (for EMOM, Tabata).
  final int? rounds;

  /// Work duration per interval (for Tabata).
  final Duration? workDuration;

  /// Rest duration per interval (for Tabata).
  final Duration? restDuration;

  /// Interval duration (for EMOM).
  final Duration? intervalDuration;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildAccessibilityLabel(),
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary label
            Text(
              'SUMMARY',
              style: AppTypography.summaryLabel.copyWith(
                color: AppColors.textDisabledDark,
              ),
            ),
            const SizedBox(height: 12),
            // Hero total duration row
            Center(
              child: Column(
                children: [
                  Text(
                    _formatDuration(totalDuration),
                    style: AppTypography.workoutTitle.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TOTAL DURATION',
                    style: AppTypography.summaryLabel.copyWith(
                      color: AppColors.textHintDark,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFF00FF88).withValues(alpha: 0.06),
            ),
            const SizedBox(height: 12),
            // Summary items in a wrap
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildSummaryItem(
                  label: 'TYPE',
                  value: timerType.toUpperCase(),
                ),
                if (rounds != null)
                  _buildSummaryItem(
                    label: 'ROUNDS',
                    value: rounds.toString(),
                  ),
                if (workDuration != null)
                  _buildSummaryItem(
                    label: 'WORK',
                    value: _formatDurationShort(workDuration!),
                  ),
                if (restDuration != null)
                  _buildSummaryItem(
                    label: 'REST',
                    value: _formatDurationShort(restDuration!),
                  ),
                if (intervalDuration != null)
                  _buildSummaryItem(
                    label: 'INTERVAL',
                    value: _formatDurationShort(intervalDuration!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.summaryLabel.copyWith(
            color: AppColors.textDisabledDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.summaryValue.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  String _buildAccessibilityLabel() {
    final parts = <String>['$timerType workout'];
    parts.add('Total duration: ${_formatDuration(totalDuration)}');

    if (rounds != null) {
      parts.add('$rounds rounds');
    }
    if (workDuration != null) {
      parts.add('Work: ${_formatDurationShort(workDuration!)}');
    }
    if (restDuration != null) {
      parts.add('Rest: ${_formatDurationShort(restDuration!)}');
    }
    if (intervalDuration != null) {
      parts.add('Interval: ${_formatDurationShort(intervalDuration!)}');
    }
    return parts.join(', ');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDurationShort(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0 && seconds > 0) {
      return '${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
