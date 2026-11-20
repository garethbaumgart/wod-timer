import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';

/// The session as a strip (2.6.0): one segment per block in its colour,
/// flex by how long it runs, 3pt gaps like the workout timeline.
///
/// With [current] null every block is bright (Home, the builder, the end
/// screen). Given, earlier blocks are dimmed (done), that block is bright
/// and later ones are outlines (still to come). [doneThrough] draws a
/// stopped session: the blocks run filled, the rest outlined.
class SessionStrip extends StatelessWidget {
  const SessionStrip({
    required this.blocks,
    super.key,
    this.current,
    this.doneThrough,
    this.height = 8,
  });

  final List<SessionBlock> blocks;
  final int? current;
  final int? doneThrough;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: SessionStripPainter(
            blocks: blocks,
            current: current,
            doneThrough: doneThrough,
            radius: height >= 14 ? 4 : 3,
          ),
        ),
      ),
    );
  }
}

class SessionStripPainter extends CustomPainter {
  const SessionStripPainter({
    required this.blocks,
    required this.radius,
    this.current,
    this.doneThrough,
  });

  final List<SessionBlock> blocks;
  final int? current;
  final int? doneThrough;
  final double radius;

  static const double gap = 3;
  static const double outline = 1.5;
  static const double doneAlpha = 0.4;

  /// Each block's share of the strip: how long it runs, at least a set.
  static int weightOf(SessionBlock block) =>
      block.estimatedSeconds < SetsBlock.setSeconds
      ? SetsBlock.setSeconds
      : block.estimatedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final total = blocks.fold(0, (sum, b) => sum + weightOf(b));
    final usable = size.width - gap * (blocks.length - 1);
    if (total <= 0 || usable <= 0) return;
    var x = 0.0;
    for (final (i, block) in blocks.indexed) {
      final width = usable * weightOf(block) / total;
      final rect = Rect.fromLTWH(x, 0, width, size.height);
      final color = block.kind.color;
      final now = current;
      final done = doneThrough;
      final toCome = (now != null && i > now) || (done != null && i > done);
      if (toCome) {
        // An outline, drawn inside the segment's box.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(outline / 2),
            Radius.circular(radius - outline / 2),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = outline
            ..color = color,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          Paint()
            ..color = now != null && i < now
                ? color.withValues(alpha: doneAlpha)
                : color,
        );
      }
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(SessionStripPainter old) =>
      old.current != current ||
      old.doneThrough != doneThrough ||
      old.radius != radius ||
      !identical(old.blocks, blocks);
}

/// A secondary capsule ("+ THEN", "+ ADD BLOCK"): the soft fill of the
/// wheel bands and the direction switch, white tracked capitals. Scales
/// down rather than overflowing a narrow phone at large text.
class SessionCapsule extends StatelessWidget {
  const SessionCapsule({
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
    super.key,
    this.height = defaultHeight,
  });

  final String label;
  final VoidCallback onTap;
  final String semanticsLabel;
  final double height;

  static const double defaultHeight = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
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

/// One block as a row, in the Home card's dress: the 4pt colour bar, the
/// name in the block's colour, its setup right-aligned, and an optional
/// trailing widget (the builder's drag handle).
class BlockRow extends StatelessWidget {
  const BlockRow({
    required this.block,
    super.key,
    this.trailing,
    this.detailColor = AppColors.textPrimaryDark,
    this.onTap,
    this.semanticsHint,
  });

  final SessionBlock block;
  final Widget? trailing;
  final Color detailColor;
  final VoidCallback? onTap;

  /// Said after the block ("Double tap to edit").
  final String? semanticsHint;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    final kind = block.kind;
    // Large text: the row grows rather than clipping its words.
    final scale = MediaQuery.textScalerOf(context).scale(24) / 24;
    return Semantics(
      button: onTap != null,
      label: '${block.spoken}. ${semanticsHint ?? ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: height),
          padding: EdgeInsets.only(
            left: 16,
            right: trailing == null ? 16 : 6,
            top: scale > 1 ? 8 : 0,
            bottom: scale > 1 ? 8 : 0,
          ),
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kind.label,
                    maxLines: 1,
                    style: AppTypography.stripName.copyWith(
                      color: kind.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    block.detail,
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
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
