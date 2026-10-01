import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A bordered icon button that supports long-press auto-repeat.
///
/// On tap, fires [onPressed] once. On long-press, fires [onPressed]
/// repeatedly at [repeatInterval] after an initial [repeatDelay], and twice
/// as fast after [accelerateAfter] repeats, so a long hold crosses a wide
/// range (a 60-minute cap) quickly.
class RepeatingIconButton extends StatefulWidget {
  const RepeatingIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    super.key,
    this.size = AppSpacing.minTouchTarget,
    this.iconSize = 20,
    this.repeatDelay = const Duration(milliseconds: 400),
    this.repeatInterval = const Duration(milliseconds: 100),
    this.accelerateAfter = 10,
  });

  /// The icon to display.
  final IconData icon;

  /// Callback when tapped or during long-press repeat.
  final VoidCallback? onPressed;

  /// Accessibility label.
  final String semanticsLabel;

  /// Outer container size (width & height).
  final double size;

  /// Icon size inside the button.
  final double iconSize;

  /// Delay before repeat starts on long-press.
  final Duration repeatDelay;

  /// Interval between repeated callbacks.
  final Duration repeatInterval;

  /// Repeats at [repeatInterval] before switching to half that interval.
  final int accelerateAfter;

  @override
  State<RepeatingIconButton> createState() => _RepeatingIconButtonState();
}

class _RepeatingIconButtonState extends State<RepeatingIconButton> {
  Timer? _timer;

  void _startRepeating() {
    if (widget.onPressed == null) return;
    var repeats = 0;
    _timer = Timer(widget.repeatDelay, () {
      _timer = Timer.periodic(widget.repeatInterval, (timer) {
        widget.onPressed?.call();
        if (++repeats == widget.accelerateAfter) {
          timer.cancel();
          _timer = Timer.periodic(widget.repeatInterval ~/ 2, (_) {
            widget.onPressed?.call();
          });
        }
      });
    });
  }

  void _stopRepeating() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTap: widget.onPressed,
        onLongPressStart: isEnabled ? (_) => _startRepeating() : null,
        onLongPressEnd: isEnabled ? (_) => _stopRepeating() : null,
        onLongPressCancel: _stopRepeating,
        // A live button reads as live: white glyph on a visible border.
        // At a limit the whole button drops to 30% (the old #666 glyph was
        // darker than the disabled colour, so live buttons looked off).
        child: Opacity(
          opacity: isEnabled ? 1 : 0.3,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
