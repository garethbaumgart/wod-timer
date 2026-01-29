import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A bordered icon button that supports long-press auto-repeat.
///
/// On tap, fires [onPressed] once. On long-press, fires [onPressed]
/// repeatedly at [repeatInterval] after an initial [repeatDelay].
/// This enables fast value adjustments in pickers without requiring
/// many individual taps.
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

  @override
  State<RepeatingIconButton> createState() => _RepeatingIconButtonState();
}

class _RepeatingIconButtonState extends State<RepeatingIconButton> {
  Timer? _timer;

  void _startRepeating() {
    if (widget.onPressed == null) return;
    _timer = Timer(widget.repeatDelay, () {
      _timer = Timer.periodic(widget.repeatInterval, (_) {
        widget.onPressed?.call();
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
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: isEnabled
                  ? const Color(0xFF666666)
                  : AppColors.textDisabledDark,
            ),
          ),
        ),
      ),
    );
  }
}
