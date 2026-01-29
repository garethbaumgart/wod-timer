import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A card that displays a summary of the configured workout.
class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({
    required this.timerType,
    required this.totalDuration,
    super.key,
    this.rounds,
    this.workDuration,
    this.restDuration,
    this.intervalDuration,
    this.prepCountdown,
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

  /// Prep countdown duration.
  final Duration? prepCountdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: _buildAccessibilityLabel(),
      container: true,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  timerType.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                size: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                _formatDuration(totalDuration),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Details
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              if (rounds != null)
                _buildDetailItem(
                  context,
                  icon: Icons.repeat,
                  label: 'Rounds',
                  value: rounds.toString(),
                ),
              if (workDuration != null)
                _buildDetailItem(
                  context,
                  icon: Icons.fitness_center,
                  label: 'Work',
                  value: _formatDurationShort(workDuration!),
                ),
              if (restDuration != null)
                _buildDetailItem(
                  context,
                  icon: Icons.pause_circle_outline,
                  label: 'Rest',
                  value: _formatDurationShort(restDuration!),
                ),
              if (intervalDuration != null)
                _buildDetailItem(
                  context,
                  icon: Icons.timer,
                  label: 'Interval',
                  value: _formatDurationShort(intervalDuration!),
                ),
              if (prepCountdown != null && prepCountdown!.inSeconds > 0)
                _buildDetailItem(
                  context,
                  icon: Icons.hourglass_top,
                  label: 'Prep',
                  value: '${prepCountdown!.inSeconds}s',
                ),
            ],
          ),
        ],
      ),
      ),
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
    if (prepCountdown != null && prepCountdown!.inSeconds > 0) {
      parts.add('Prep countdown: ${prepCountdown!.inSeconds} seconds');
    }

    return parts.join(', ');
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
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
