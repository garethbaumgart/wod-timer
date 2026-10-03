import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// The Wharf WOD wordmark: a small tracked WHARF stacked over a heavy WOD
/// with a full stop, in Outfit with a soft neon glow. Preview build: the
/// `WORDMARK` dart-define picks the colour combination (22 or 25 from the
/// combo sheet); 'A' keeps the one-line 1.3.1 mark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 44});

  /// Height driver: the one-line mark's size; the stacked WOD is 1.45x.
  final double fontSize;

  static const _variant = String.fromEnvironment(
    'WORDMARK',
    defaultValue: 'A',
  );

  static const Color _white = Colors.white;

  List<Shadow> _glow(Color color, double size) => color == _white
      ? [Shadow(color: color.withValues(alpha: 0.18), blurRadius: size * 0.2)]
      : [
          Shadow(color: color.withValues(alpha: 0.5), blurRadius: size * 0.1),
          Shadow(color: color.withValues(alpha: 0.35), blurRadius: size * 0.3),
        ];

  @override
  Widget build(BuildContext context) {
    final Widget mark;
    if (_variant == 'A') {
      mark = _oneLine();
    } else {
      final (wharf, wod, dot) = switch (_variant) {
        '25' => (_white, AppColors.primary, AppColors.brand),
        '22p' => (AppColors.brand, AppColors.primary, AppColors.emomAccent),
        '25p' => (_white, AppColors.primary, AppColors.emomAccent),
        _ => (AppColors.brand, AppColors.primary, AppColors.brand), // 22
      };
      mark = _stacked(wharf, wod, dot);
    }
    return Semantics(
      header: true,
      label: 'Wharf WOD',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: mark,
      ),
    );
  }

  Widget _stacked(Color wharf, Color wod, Color dot) {
    final big = fontSize * 1.45;
    final base = AppTypography.heroTitle.copyWith(height: 0.9);
    return Column(
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
              color: wharf,
              shadows: _glow(wharf, big * 0.278),
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
                  color: wod,
                  shadows: _glow(wod, big),
                ),
              ),
              TextSpan(
                text: '.',
                style: base.copyWith(
                  fontSize: big,
                  color: dot,
                  shadows: _glow(dot, big),
                ),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }

  Widget _oneLine() {
    final base = AppTypography.heroTitle.copyWith(
      fontSize: fontSize,
      letterSpacing: -fontSize * 0.025,
      height: 1.1,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'WHARF WOD',
            style: base.copyWith(
              color: AppColors.brand,
              shadows: _glow(AppColors.brand, fontSize),
            ),
          ),
          TextSpan(
            text: '.',
            style: base.copyWith(
              color: AppColors.primary,
              shadows: _glow(AppColors.primary, fontSize),
            ),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }
}
