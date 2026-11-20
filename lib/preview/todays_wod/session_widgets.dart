import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/preview/todays_wod/todays_wod_preview.dart';

/// PROTOTYPE ONLY. The session as a strip: one segment per block in the
/// block's colour, flex by minutes, 3pt gaps like the workout timeline.
///
/// With [current] null every block is bright (Home, the builder, the end
/// screen). Given, earlier blocks are dimmed (done), that block is bright
/// and later ones are outlines (still to come).
class SessionStrip extends StatelessWidget {
  const SessionStrip({super.key, this.current, this.height = 8});

  final int? current;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SessionStripPainter(
            blocks: TodaysWodPreview.blocks,
            current: current,
            radius: height >= 14 ? 4 : 3,
          ),
        ),
      ),
    );
  }
}

class _SessionStripPainter extends CustomPainter {
  const _SessionStripPainter({
    required this.blocks,
    required this.current,
    required this.radius,
  });

  final List<WodBlock> blocks;
  final int? current;
  final double radius;

  static const double gap = 3;
  static const double outline = 1.5;
  static const double doneAlpha = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final total = blocks.fold(0, (sum, b) => sum + b.minutes);
    final usable = size.width - gap * (blocks.length - 1);
    if (total <= 0 || usable <= 0) return;
    var x = 0.0;
    for (final (i, block) in blocks.indexed) {
      final width = usable * block.minutes / total;
      final rect = Rect.fromLTWH(x, 0, width, size.height);
      final now = current;
      if (now != null && i > now) {
        // Still to come: an outline, drawn inside the segment's box.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(outline / 2),
            Radius.circular(radius - outline / 2),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = outline
            ..color = block.kind.color,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          Paint()
            ..color = now != null && i < now
                ? block.kind.color.withValues(alpha: doneAlpha)
                : block.kind.color,
        );
      }
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(_SessionStripPainter old) =>
      old.current != current || old.radius != radius || old.blocks != blocks;
}

/// PROTOTYPE ONLY. A secondary capsule ("+ THEN", "+ ADD BLOCK"): the soft
/// fill of the wheel bands and the direction switch, white tracked capitals.
class PreviewCapsule extends StatelessWidget {
  const PreviewCapsule({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.textPrimaryDark,
                fontSize: 17,
                letterSpacing: 17 * 0.06,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PROTOTYPE ONLY. One block as a row, in the Home card's dress: the 4pt
/// colour bar, the name in the block's colour, its setup right-aligned, and
/// an optional trailing widget (the builder's drag handle).
class BlockRow extends StatelessWidget {
  const BlockRow({
    required this.kind,
    required this.detail,
    super.key,
    this.trailing,
    this.detailColor = AppColors.textPrimaryDark,
    this.onTap,
  });

  final BlockKind kind;
  final String detail;
  final Widget? trailing;
  final Color detailColor;
  final VoidCallback? onTap;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          color: Colors.white.withValues(alpha: 0.035),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: kind.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              kind.label,
              maxLines: 1,
              style: AppTypography.stripName.copyWith(
                color: kind.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detail,
                maxLines: 1,
                textAlign: TextAlign.end,
                style: AppTypography.bodyLarge.copyWith(
                  color: detailColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// PROTOTYPE ONLY. The zone under a setup's wheels with "+ THEN" in it.
///
/// The capsule sits with START, [capsuleGap] above the slab, and the
/// timeline keeps layout rule 2 against the new edge: midway between the
/// wheels' glyphs ([aboveInkInset] above this zone) and the capsule.
class ThenZone extends StatelessWidget {
  const ThenZone({
    required this.aboveInkInset,
    required this.timelineHeight,
    required this.timeline,
    required this.onThen,
    super.key,
  });

  final double aboveInkInset;
  final double timelineHeight;
  final Widget timeline;
  final VoidCallback onThen;

  /// The capsule's bottom to the START slab.
  static const double capsuleGap = 16;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CentredTimeline(
            aboveInkInset: aboveInkInset,
            height: timelineHeight,
            child: timeline,
          ),
        ),
        PreviewCapsule(label: '+ THEN', onTap: onThen),
        const SizedBox(height: capsuleGap),
      ],
    );
  }
}
