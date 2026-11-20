import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/preview/todays_wod/session_widgets.dart';
import 'package:wod_timer/preview/todays_wod/todays_wod_preview.dart';

/// PROTOTYPE ONLY. Home's "TODAY'S WOD" card, above the four modes: the
/// last session as a repeat row (each block in its colour), its strip, how
/// long it runs, and "+ NEW" to build another. The card is the repeat
/// button, in the mode cards' dress.
class TodaysWodHomeCard extends StatelessWidget {
  const TodaysWodHomeCard({super.key});

  /// Home's top and bottom padding while the card is shown (50 and 20
  /// without it), so the card and all four mode cards fit a 6.3in phone
  /// without scrolling.
  static const double homeTopPadding = 16;
  static const double homeBottomPadding = 8;

  static const double _chipHeight = 24;

  /// Box gaps that leave 15pt between the glyphs: the label's capitals to
  /// the summary's (measured on the 3x capture: 6 and 12 gave 14.5 each).
  static const double _labelToSummary = 6.5;
  static const double _summaryToStrip = 12.5;

  TextStyle get _label => AppTypography.labelSmall.copyWith(
    color: AppColors.textPrimaryDark,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 13 * 0.14,
    height: 1,
  );

  TextStyle get _muted => AppTypography.bodyLarge.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  TextStyle get _summary => AppTypography.bodyLarge.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final named = [
      for (final block in TodaysWodPreview.blocks)
        if (block.summary != null) block,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(TodaysWodPreview.path('sets-work')),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            color: Colors.white.withValues(alpha: 0.035),
          ),
          child: Padding(
            // 15pt from the card's edge (its 1pt border included) to the
            // chip above and the strip below, the gap the rows keep.
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _chipHeight,
                  child: Row(
                    children: [
                      Text("TODAY'S WOD", maxLines: 1, style: _label),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          TodaysWodPreview.total,
                          maxLines: 1,
                          style: _muted,
                        ),
                      ),
                      _NewChip(
                        height: _chipHeight,
                        onTap: () =>
                            context.go(TodaysWodPreview.path('builder')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _labelToSummary),
                Row(
                  children: [
                    // The glyph sits 3.3pt inside its box: pulled left so its
                    // ink starts on the strip's edge.
                    Transform.translate(
                      offset: const Offset(-3.3, 0),
                      child: const Icon(
                        Icons.replay,
                        size: 20,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              for (final (i, block) in named.indexed) ...[
                                if (i > 0) const TextSpan(text: '  ·  '),
                                TextSpan(
                                  text: block.summary,
                                  style: TextStyle(color: block.kind.textColor),
                                ),
                              ],
                            ],
                          ),
                          maxLines: 1,
                          style: _summary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _summaryToStrip),
                const SessionStrip(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ NEW": the setup voice chip's outline, smaller.
class _NewChip extends StatelessWidget {
  const _NewChip({required this.height, required this.onTap});

  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Build a new Today's WOD",
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              '+ NEW',
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
                letterSpacing: 1,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
