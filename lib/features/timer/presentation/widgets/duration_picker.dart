import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A wheel-based duration picker for selecting minutes and seconds.
///
/// Designed for easy use during workout setup with large, easy-to-scroll values.
class DurationPicker extends StatefulWidget {
  const DurationPicker({
    required this.initialDuration,
    required this.onChanged,
    super.key,
    this.maxMinutes = 60,
    this.minuteInterval = 1,
    this.secondInterval = 5,
    this.showSeconds = true,
    this.label,
  });

  /// Initial duration to display.
  final Duration initialDuration;

  /// Callback when duration changes.
  final ValueChanged<Duration> onChanged;

  /// Maximum number of minutes selectable.
  final int maxMinutes;

  /// Interval between minute options.
  final int minuteInterval;

  /// Interval between second options.
  final int secondInterval;

  /// Whether to show seconds picker.
  final bool showSeconds;

  /// Optional label displayed above the picker.
  final String? label;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDuration.inMinutes;
    _seconds = widget.initialDuration.inSeconds % 60;

    // Round to nearest interval
    _minutes = (_minutes ~/ widget.minuteInterval) * widget.minuteInterval;
    _seconds = (_seconds ~/ widget.secondInterval) * widget.secondInterval;

    _minuteController = FixedExtentScrollController(
      initialItem: _minutes ~/ widget.minuteInterval,
    );
    _secondController = FixedExtentScrollController(
      initialItem: _seconds ~/ widget.secondInterval,
    );
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _onMinuteChanged(int index) {
    setState(() {
      _minutes = index * widget.minuteInterval;
    });
    _notifyChange();
  }

  void _onSecondChanged(int index) {
    setState(() {
      _seconds = index * widget.secondInterval;
    });
    _notifyChange();
  }

  void _notifyChange() {
    final duration = Duration(minutes: _minutes, seconds: _seconds);
    widget.onChanged(duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              widget.label!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes picker
              SizedBox(
                width: 80,
                child: _buildWheelPicker(
                  controller: _minuteController,
                  itemCount: (widget.maxMinutes ~/ widget.minuteInterval) + 1,
                  onSelectedItemChanged: _onMinuteChanged,
                  itemBuilder: (index) {
                    final value = index * widget.minuteInterval;
                    return value.toString().padLeft(2, '0');
                  },
                ),
              ),
              // Colon separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  ':',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              // Seconds picker
              if (widget.showSeconds)
                SizedBox(
                  width: 80,
                  child: _buildWheelPicker(
                    controller: _secondController,
                    itemCount: 60 ~/ widget.secondInterval,
                    onSelectedItemChanged: _onSecondChanged,
                    itemBuilder: (index) {
                      final value = index * widget.secondInterval;
                      return value.toString().padLeft(2, '0');
                    },
                  ),
                ),
            ],
          ),
        ),
        // Current value display
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            _formatDuration(Duration(minutes: _minutes, seconds: _seconds)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.005,
      diameterRatio: 1.2,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(
            child: Text(
              itemBuilder(index),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
