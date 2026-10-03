import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// The Wharf WOD wordmark (1.3.1): neon-orange Outfit Black with a soft
/// glow, ending in the neon-green full stop kept from the old "WOD." hero.
/// The watch app ships the same mark as an image.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 44});

  /// Cap height scales with this; the mark never wraps, it shrinks to fit.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.heroTitle.copyWith(
      fontSize: fontSize,
      letterSpacing: -fontSize * 0.025,
      height: 1.1,
    );
    List<Shadow> glow(Color color) => [
      Shadow(color: color.withValues(alpha: 0.6), blurRadius: fontSize * 0.1),
      Shadow(color: color.withValues(alpha: 0.4), blurRadius: fontSize * 0.3),
    ];
    return Semantics(
      header: true,
      label: 'Wharf WOD',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'WHARF WOD',
                style: base.copyWith(
                  color: AppColors.brand,
                  shadows: glow(AppColors.brand),
                ),
              ),
              TextSpan(
                text: '.',
                style: base.copyWith(
                  color: AppColors.primary,
                  shadows: glow(AppColors.primary),
                ),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
