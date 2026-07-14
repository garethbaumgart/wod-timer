import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// A Signal-design summary box showing workout configuration.
///
/// Shows the configured workout time (prep listed separately so the
/// arithmetic always matches what the user set), plus per-mode values and
/// the active voice pack (tap to change).
class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({
    required this.timerType,
    required this.workoutDuration,
    super.key,
    this.prepSeconds = 10,
    this.isTimeCap = false,
    this.rounds,
    this.workDuration,
    this.restDuration,
    this.intervalDuration,
    this.voiceLabel,
    this.onVoiceTap,
  });

  /// The type of timer (e.g., "AMRAP", "For Time", "EMOM", "Tabata").
  final String timerType;

  /// Configured workout duration, excluding the get-ready countdown.
  final Duration workoutDuration;

  /// Get-ready countdown length, shown as its own line.
  final int prepSeconds;

  /// Whether [workoutDuration] is a ceiling (For Time cap), not a length.
  final bool isTimeCap;

  /// Number of rounds (for EMOM, Tabata).
  final int? rounds;

  /// Work duration per interval (for Tabata).
  final Duration? workDuration;

  /// Rest duration per interval (for Tabata).
  final Duration? restDuration;

  /// Interval duration (for EMOM).
  final Duration? intervalDuration;

  /// Currently selected voice pack label (e.g. "Major").
  final String? voiceLabel;

  /// Opens the voice picker; the wedge feature is choosable at setup.
  final VoidCallback? onVoiceTap;

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
                color: AppColors.textHintDark,
              ),
            ),
            const SizedBox(height: 12),
            // Hero: the configured workout time (prep NOT folded in)
            Center(
              child: Column(
                children: [
                  Text(
                    _clock(workoutDuration),
                    style: AppTypography.workoutTitle.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTimeCap ? 'TIME CAP' : 'WORKOUT TIME',
                    style: AppTypography.summaryLabel.copyWith(
                      color: AppColors.textHintDark,
                      fontSize: 10,
                    ),
                  ),
                  if (prepSeconds > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ 0:${prepSeconds.toString().padLeft(2, '0')} get-ready',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textHintDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                if (rounds != null)
                  _buildSummaryItem(label: 'ROUNDS', value: rounds.toString()),
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
                if (voiceLabel != null) _buildVoiceItem(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.summaryLabel.copyWith(
            color: AppColors.textHintDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.summaryValue.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildVoiceItem() {
    return Semantics(
      button: true,
      label: 'Voice: $voiceLabel. Tap to change.',
      child: GestureDetector(
        onTap: onVoiceTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOICE',
              style: AppTypography.summaryLabel.copyWith(
                color: AppColors.textHintDark,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.volume_up_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$voiceLabel ›',
                  style: AppTypography.summaryValue.copyWith(
                    color: AppColors.primary,
                  ),
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
    parts.add(
      '${isTimeCap ? 'Time cap' : 'Workout time'}: '
      '${_clock(workoutDuration)}',
    );
    if (prepSeconds > 0) {
      parts.add('plus $prepSeconds second get-ready countdown');
    }
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
    if (voiceLabel != null) {
      parts.add('Voice: $voiceLabel');
    }
    return parts.join(', ');
  }

  /// Clock format for stats: "4:00", "10:00", "0:19".
  String _clock(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
