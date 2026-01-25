import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A toggle with duration picker for the preparation countdown.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Prep Countdown',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            Semantics(
              label: widget.enabled
                  ? 'Prep countdown enabled, ${widget.duration} seconds'
                  : 'Prep countdown disabled',
              child: Switch.adaptive(
                value: widget.enabled,
                onChanged: widget.onEnabledChanged,
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
        // Duration options (shown when enabled)
        if (widget.enabled) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _presetDurations.map((seconds) {
              final isSelected = widget.duration == seconds;
              return Semantics(
                label: '$seconds seconds prep countdown',
                selected: isSelected,
                child: ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: isSelected,
                  onSelected: (_) => widget.onDurationChanged(seconds),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textDisabledDark
                          : AppColors.textDisabledLight),
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
