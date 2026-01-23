import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// A secondary action button with outline style.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The button label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destructiveColor = theme.colorScheme.error;

    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: isDestructive
            ? OutlinedButton.styleFrom(
                foregroundColor: destructiveColor,
                side: BorderSide(color: destructiveColor, width: 2),
              )
            : null,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDestructive
                      ? destructiveColor
                      : theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// A text-only button for tertiary actions.
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The button label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(label),
        ],
      ),
    );
  }
}
