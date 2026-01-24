import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A picker for selecting number of rounds.
///
/// Supports both wheel picker and increment/decrement buttons.
class RoundPicker extends StatefulWidget {
  const RoundPicker({
    required this.initialRounds,
    required this.onChanged,
    super.key,
    this.minRounds = 1,
    this.maxRounds = 50,
    this.label,
  });

  /// Initial number of rounds.
  final int initialRounds;

  /// Callback when rounds change.
  final ValueChanged<int> onChanged;

  /// Minimum number of rounds.
  final int minRounds;

  /// Maximum number of rounds.
  final int maxRounds;

  /// Optional label displayed above the picker.
  final String? label;

  @override
  State<RoundPicker> createState() => _RoundPickerState();
}

class _RoundPickerState extends State<RoundPicker> {
  late int _rounds;

  @override
  void initState() {
    super.initState();
    _rounds = widget.initialRounds.clamp(widget.minRounds, widget.maxRounds);
  }

  void _increment() {
    if (_rounds < widget.maxRounds) {
      setState(() {
        _rounds++;
      });
      widget.onChanged(_rounds);
    }
  }

  void _decrement() {
    if (_rounds > widget.minRounds) {
      setState(() {
        _rounds--;
      });
      widget.onChanged(_rounds);
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement button
              _buildButton(
                icon: Icons.remove,
                onPressed: _rounds > widget.minRounds ? _decrement : null,
                isDark: isDark,
              ),
              // Rounds display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: 60,
                  child: Text(
                    _rounds.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              // Increment button
              _buildButton(
                icon: Icons.add,
                onPressed: _rounds < widget.maxRounds ? _increment : null,
                isDark: isDark,
              ),
            ],
          ),
        ),
        // Label showing "rounds"
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            _rounds == 1 ? 'round' : 'rounds',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          width: AppSpacing.iconButtonSize,
          height: AppSpacing.iconButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? AppColors.primary
                : (isDark
                    ? AppColors.textDisabledDark
                    : AppColors.textDisabledLight),
            size: 28,
          ),
        ),
      ),
    );
  }
}
