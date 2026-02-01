import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A primary action button with large touch target for gym use.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon,
    this.isLoading = false,
    this.isLarge = false,
    this.backgroundColor,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The button label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether to use the larger button size.
  final bool isLarge;

  /// Optional background color override.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isLarge
        ? AppSpacing.largeButtonHeight
        : AppSpacing.buttonHeight;

    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isLarge ? 28 : 24),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(label, style: TextStyle(fontSize: isLarge ? 20 : 18)),
                ],
              ),
      ),
    );
  }
}

/// A large circular play/pause button for timer control.
class TimerControlButton extends StatelessWidget {
  const TimerControlButton({
    required this.onPressed,
    required this.icon,
    super.key,
    this.size = 80,
    this.backgroundColor,
    this.iconColor,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// The button size (width and height).
  final double size;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional icon color override.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: iconColor ?? Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: size * 0.5),
      ),
    );
  }
}
