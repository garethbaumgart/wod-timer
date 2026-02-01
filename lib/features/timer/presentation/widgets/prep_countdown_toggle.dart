import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// A Signal-design toggle with duration picker for the preparation countdown.
///
/// Displays a minimal row with "Prep Countdown" text and a switch,
/// separated by a top border divider. When enabled, shows preset
/// duration chips below.
class PrepCountdownToggle extends StatefulWidget {
  const PrepCountdownToggle({
    required this.enabled,
    required this.duration,
    required this.onEnabledChanged,
    required this.onDurationChanged,
    super.key,
  });

  /// Whether prep countdown is enabled.
  final bool enabled;

  /// Current prep countdown duration in seconds.
  final int duration;

  /// Callback when toggle changes.
  final ValueChanged<bool> onEnabledChanged;

  /// Callback when duration changes.
  final ValueChanged<int> onDurationChanged;

  @override
  State<PrepCountdownToggle> createState() => _PrepCountdownToggleState();
}

class _PrepCountdownToggleState extends State<PrepCountdownToggle> {
  static const List<int> _presetDurations = [3, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row with top border
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prep Countdown',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF777777),
                  fontSize: 12,
                ),
              ),
              Semantics(
                label: widget.enabled
                    ? 'Prep countdown enabled, ${widget.duration} seconds'
                    : 'Prep countdown disabled',
                child: Switch.adaptive(
                  value: widget.enabled,
                  onChanged: widget.onEnabledChanged,
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
        // Duration chips (shown when enabled)
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presetDurations.map((seconds) {
              final isSelected = widget.duration == seconds;
              return Semantics(
                label: '$seconds seconds prep countdown',
                selected: isSelected,
                child: GestureDetector(
                  onTap: () => widget.onDurationChanged(seconds),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${seconds}s',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
