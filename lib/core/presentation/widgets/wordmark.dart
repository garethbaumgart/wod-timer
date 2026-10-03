import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// The Wharf WOD wordmark (1.3.1, combo 25): a small tracked WHARF in white
/// stacked over a heavy green WOD with a pink full stop, in Outfit with a
/// soft neon glow on the colours and a faint one on the white. The watch
/// ships the same mark as an image.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.wodSize = 64});

  /// The WOD line's font size; everything else is a ratio of it. Tablets
  /// get the same number scaled by TabletScale.
  final double wodSize;

  static const Color _wharf = Colors.white;
  static const Color _wod = AppColors.primary;
  static const Color _dot = AppColors.emomAccent;

  /// Soft glow on the colours, faint on white.
  static List<Shadow> glow(Color color, double size) => color == _wharf
      ? [Shadow(color: color.withValues(alpha: 0.18), blurRadius: size * 0.2)]
      : [
          Shadow(color: color.withValues(alpha: 0.5), blurRadius: size * 0.1),
          Shadow(color: color.withValues(alpha: 0.35), blurRadius: size * 0.3),
        ];

  @override
  Widget build(BuildContext context) {
    final big = wodSize;
    final base = AppTypography.heroTitle.copyWith(height: 0.9);
    return Semantics(
      header: true,
      label: 'Wharf WOD',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: big * 0.04),
              child: Text(
                'WHARF',
                style: base.copyWith(
                  fontSize: big * 0.278,
                  fontWeight: FontWeight.w800,
                  letterSpacing: big * 0.12,
                  color: _wharf,
                  shadows: glow(_wharf, big * 0.278),
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'WOD',
                    style: base.copyWith(
                      fontSize: big,
                      letterSpacing: -big * 0.028,
                      color: _wod,
                      shadows: glow(_wod, big),
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: base.copyWith(
                      fontSize: big,
                      color: _dot,
                      shadows: glow(_dot, big),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
