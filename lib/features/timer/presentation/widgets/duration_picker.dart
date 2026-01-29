import 'package:flutter/material.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A wheel-based duration picker for selecting minutes and seconds.
///
/// Designed for easy use during workout setup with large, easy-to-scroll values.
/// Features improved touch targets and haptic feedback for better mobile UX.
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
    this.hapticService,
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

  /// Optional haptic service for feedback. If provided, haptic feedback
  /// will respect the app's haptic settings.
  final IHapticService? hapticService;

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

    // Round to nearest interval and clamp to valid range
    _minutes = (_minutes ~/ widget.minuteInterval) * widget.minuteInterval;
    _minutes = _minutes.clamp(0, widget.maxMinutes);
    _seconds = (_seconds ~/ widget.secondInterval) * widget.secondInterval;
    _seconds = _seconds.clamp(0, 59);

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
    widget.hapticService?.selectionClick();
    setState(() {
      _minutes = index * widget.minuteInterval;
    });
    _notifyChange();
  }

  void _onSecondChanged(int index) {
    widget.hapticService?.selectionClick();
    setState(() {
      _seconds = index * widget.secondInterval;
    });
    _notifyChange();
  }

  void _notifyChange() {
    final duration = Duration(minutes: _minutes, seconds: _seconds);
    widget.onChanged(duration);
  }

  void _incrementMinutes() {
    final maxIndex = widget.maxMinutes ~/ widget.minuteInterval;
    final currentIndex = _minutes ~/ widget.minuteInterval;
    if (currentIndex < maxIndex) {
      widget.hapticService?.lightImpact();
      _minuteController.animateToItem(
        currentIndex + 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _decrementMinutes() {
    final currentIndex = _minutes ~/ widget.minuteInterval;
    if (currentIndex > 0) {
      widget.hapticService?.lightImpact();
      _minuteController.animateToItem(
        currentIndex - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _incrementSeconds() {
    final maxIndex = (60 ~/ widget.secondInterval) - 1;
    final currentIndex = _seconds ~/ widget.secondInterval;
    if (currentIndex < maxIndex) {
      widget.hapticService?.lightImpact();
      _secondController.animateToItem(
        currentIndex + 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _decrementSeconds() {
    final currentIndex = _seconds ~/ widget.secondInterval;
    if (currentIndex > 0) {
      widget.hapticService?.lightImpact();
      _secondController.animateToItem(
        currentIndex - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
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
          height: 220,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes picker with +/- buttons
              _buildPickerColumn(
                controller: _minuteController,
                itemCount: (widget.maxMinutes ~/ widget.minuteInterval) + 1,
                onSelectedItemChanged: _onMinuteChanged,
                itemBuilder: (index) {
                  final value = index * widget.minuteInterval;
                  return value.toString().padLeft(2, '0');
                },
                onIncrement: _incrementMinutes,
                onDecrement: _decrementMinutes,
                label: 'min',
                isDark: isDark,
              ),
              // Colon separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
              // Seconds picker with +/- buttons
              if (widget.showSeconds)
                _buildPickerColumn(
                  controller: _secondController,
                  itemCount: 60 ~/ widget.secondInterval,
                  onSelectedItemChanged: _onSecondChanged,
                  itemBuilder: (index) {
                    final value = index * widget.secondInterval;
                    return value.toString().padLeft(2, '0');
                  },
                  onIncrement: _incrementSeconds,
                  onDecrement: _decrementSeconds,
                  label: 'sec',
                  isDark: isDark,
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

  Widget _buildPickerColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) itemBuilder,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required String label,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label picker',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Increment button
          _buildStepButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: onIncrement,
            isDark: isDark,
            semanticsLabel: 'Increase $label',
          ),
          // Wheel picker
          SizedBox(
            width: 100,
            height: 120,
            child: _buildWheelPicker(
              controller: controller,
              itemCount: itemCount,
              onSelectedItemChanged: onSelectedItemChanged,
              itemBuilder: itemBuilder,
            ),
          ),
          // Decrement button
          _buildStepButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: onDecrement,
            isDark: isDark,
            semanticsLabel: 'Decrease $label',
          ),
          // Label
          ExcludeSemantics(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required String semanticsLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: 56,
            height: 44,
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 32,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
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
      itemExtent: 60, // Larger touch targets (was 50)
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
                fontSize: 36, // Larger text
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
