import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/repeating_icon_button.dart';

/// A Signal-design duration picker with big centered value and +/- buttons.
///
/// Displays the duration in MM:SS format with Outfit 64px w900 styling.
/// Features +/- adjustment buttons and haptic feedback for better mobile UX.
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
  }

  void _notifyChange() {
    final duration = Duration(minutes: _minutes, seconds: _seconds);
    widget.onChanged(duration);
  }

  void _incrementMinutes() {
    final max = widget.maxMinutes;
    if (_minutes + widget.minuteInterval <= max) {
      widget.hapticService?.lightImpact();
      setState(() {
        _minutes += widget.minuteInterval;
      });
      _notifyChange();
    }
  }

  void _decrementMinutes() {
    if (_minutes - widget.minuteInterval >= 0) {
      widget.hapticService?.lightImpact();
      setState(() {
        _minutes -= widget.minuteInterval;
      });
      _notifyChange();
    }
  }

  void _incrementSeconds() {
    final next = _seconds + widget.secondInterval;
    if (next < 60) {
      widget.hapticService?.lightImpact();
      setState(() {
        _seconds = next;
      });
      _notifyChange();
    }
  }

  void _decrementSeconds() {
    final next = _seconds - widget.secondInterval;
    if (next >= 0) {
      widget.hapticService?.lightImpact();
      setState(() {
        _seconds = next;
      });
      _notifyChange();
    }
  }

  String _formatValue() {
    final m = _minutes.toString().padLeft(2, '0');
    if (!widget.showSeconds) {
      return '$m:00';
    }
    final s = _seconds.toString().padLeft(2, '0');
    return '$m:$s';
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
                color: const Color(0xFF444444),
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        // Big value display
        Text(
          _formatValue(),
          style: AppTypography.timerDisplayMedium.copyWith(
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),
        // +/- buttons row for minutes and seconds
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minutes controls
            RepeatingIconButton(
              icon: Icons.remove,
              onPressed: _minutes > 0 ? _decrementMinutes : null,
              semanticsLabel: 'Decrease minutes',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'MIN',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: const Color(0xFF444444),
                ),
              ),
            ),
            RepeatingIconButton(
              icon: Icons.add,
              onPressed:
                  _minutes < widget.maxMinutes ? _incrementMinutes : null,
              semanticsLabel: 'Increase minutes',
            ),
            const SizedBox(width: 24),
            // Seconds controls
            if (widget.showSeconds) ...[
              RepeatingIconButton(
                icon: Icons.remove,
                onPressed: _seconds > 0 ? _decrementSeconds : null,
                semanticsLabel: 'Decrease seconds',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'SEC',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: const Color(0xFF444444),
                  ),
                ),
              ),
              RepeatingIconButton(
                icon: Icons.add,
                onPressed: _seconds + widget.secondInterval < 60
                    ? _incrementSeconds
                    : null,
                semanticsLabel: 'Increase seconds',
              ),
            ],
          ],
        ),
      ],
    );
  }
}
