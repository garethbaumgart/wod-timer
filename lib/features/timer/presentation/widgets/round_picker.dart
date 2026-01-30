import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/repeating_icon_button.dart';

/// A Signal-design picker for selecting number of rounds.
///
/// Shows a big centered value with +/- adjustment buttons matching
/// the Signal design language.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.label!.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHintDark,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        // Big value display with +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepeatingIconButton(
              icon: Icons.remove,
              onPressed: _rounds > widget.minRounds ? _decrement : null,
              semanticsLabel: 'Decrease rounds',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: 80,
                child: Text(
                  _rounds.toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.timerDisplayMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
            RepeatingIconButton(
              icon: Icons.add,
              onPressed: _rounds < widget.maxRounds ? _increment : null,
              semanticsLabel: 'Increase rounds',
            ),
          ],
        ),
        const SizedBox(height: 4),
        // "rounds" label
        Text(
          _rounds == 1 ? 'ROUND' : 'ROUNDS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textHintDark,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
