import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/presentation/widgets/end_fact_tiles.dart';
import 'package:wod_timer/preview/todays_wod/live_styles.dart';
import 'package:wod_timer/preview/todays_wod/session_widgets.dart';
import 'package:wod_timer/preview/todays_wod/todays_wod_preview.dart';

/// One block's result on the session's end screen.
@immutable
class BlockResult {
  const BlockResult(this.kind, this.value, {this.unit});

  final BlockKind kind;
  final String value;

  /// Grey word after the block's name in the tile's label ("ROUNDS").
  final String? unit;
}

/// PROTOTYPE ONLY. The end screen for a whole session, laid out as the
/// upright end screen is (2.5.1): the word, the config line, the hero in
/// the session's colour, three tiles, the strip centred above AGAIN | DONE.
class PreviewEndScreen extends StatefulWidget {
  const PreviewEndScreen({
    required this.time,
    required this.results,
    required this.onAgain,
    required this.onDone,
    super.key,
  });

  /// The session's total time ("41:36").
  final String time;
  final List<BlockResult> results;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  State<PreviewEndScreen> createState() => _PreviewEndScreenState();
}

class _PreviewEndScreenState extends State<PreviewEndScreen> {
  static const double _topPad = 28;
  static const double _heroGap = 36;
  static const double _tilesGap = 28;

  @override
  void initState() {
    super.initState();
    // The end screen is the live page's last state: same system UI.
    ImmersiveHold.acquire();
  }

  @override
  void dispose() {
    ImmersiveHold.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(bottom: false, child: LayoutBuilder(builder: _buildEnd)),
    );
  }

  Widget _buildEnd(BuildContext context, BoxConstraints constraints) {
    final textScaler = MediaQuery.textScalerOf(context);
    const word = 'Finished';
    final configText =
        "TODAY'S WOD  ·  ${TodaysWodPreview.blocks.length} BLOCKS";
    final configStyle = GlyphInk.resolve(context, LiveStyles.unit(14));
    final wordStyle = GlyphInk.resolve(
      context,
      AppTypography.heroTitle.copyWith(
        color: Colors.white,
        fontSize: 30,
        letterSpacing: -0.3,
      ),
    );
    final unit = GlyphInk.resolve(context, LiveStyles.unit(16));
    final blockHeight =
        constraints.maxHeight -
        _topPad -
        GlyphInk.boxHeight(word, wordStyle, textScaler: textScaler) -
        4 -
        GlyphInk.boxHeight(configText, configStyle, textScaler: textScaler) -
        _heroGap -
        _tilesGap -
        EndFactTiles.heightOf(context) -
        BottomSlab.heightOf(context) -
        2 * (LiveStyles.timelineHeight + 24);
    const accent = TodaysWodPreview.sessionAccent;
    final heroStyle = GlyphInk.resolve(
      context,
      LiveStyles.hero(
        accent,
        ClockSpec.fontSizeFor(
          reference: widget.time,
          style: GlyphInk.resolve(context, LiveStyles.hero(accent, 100)),
          maxWidth: (constraints.maxWidth - 32) * 0.86,
          slotHeight: math.min(
            constraints.maxHeight * 0.22,
            math.max(48, blockHeight - 40),
          ),
        ),
      ),
    );
    final overshoot = math.max(
      0,
      GlyphInk.glyphBottom(widget.time, heroStyle) -
          GlyphInk.boxHeight(widget.time, heroStyle),
    );

    return Column(
      children: [
        const SizedBox(height: _topPad),
        Text(word, style: wordStyle),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            configText,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: configStyle,
          ),
        ),
        const SizedBox(height: _heroGap),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: overshoot.toDouble()),
              child: Text(
                widget.time,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: heroStyle,
              ),
            ),
            Text('TIME', style: unit),
          ],
        ),
        const SizedBox(height: _tilesGap),
        _BlockTiles(results: widget.results),
        const Expanded(
          child: CentredTimeline(
            aboveInkInset: 0,
            height: LiveStyles.timelineHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SessionStrip(height: LiveStyles.timelineHeight),
            ),
          ),
        ),
        BottomSlab(
          cells: [
            SlabCell(
              label: 'AGAIN',
              background: accent,
              foreground: Colors.black,
              onTap: widget.onAgain,
              semanticsLabel: 'Run the same session again',
            ),
            SlabCell(
              label: 'DONE',
              background: AppColors.soft,
              foreground: Colors.white,
              onTap: widget.onDone,
              semanticsLabel: 'Done, back to Home',
            ),
          ],
        ),
      ],
    );
  }
}

/// The end screen's fact tiles with one block each: the tile, its padding
/// and its two text styles are [EndFactTiles]'s; only the label differs
/// (the block's name in its colour, then a grey unit).
class _BlockTiles extends StatelessWidget {
  const _BlockTiles({required this.results});

  final List<BlockResult> results;

  static const double _sidePadding = 8;

  String _labelOf(BlockResult result) => result.unit == null
      ? result.kind.label
      : '${result.kind.label} ${result.unit}';

  @override
  Widget build(BuildContext context) {
    // One label size for the row, set from the longest label, so the three
    // never differ (a lone FittedBox would shrink only the long one).
    final base = GlyphInk.resolve(context, EndFactTiles.labelStyle());
    final tile =
        (MediaQuery.sizeOf(context).width -
            32 -
            EndFactTiles.spacing * (results.length - 1)) /
        results.length;
    final longest = results
        .map((r) => GlyphInk.boxWidth(_labelOf(r), base))
        .reduce(math.max);
    final scale = math.min(1, (tile - 2 * _sidePadding) / longest);
    final label = EndFactTiles.labelStyle().copyWith(
      fontSize: EndFactTiles.labelSize * scale,
      letterSpacing: EndFactTiles.labelSize * 0.14 * scale,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: EndFactTiles.spacing,
        children: [
          for (final result in results)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: EndFactTiles.padding,
                  horizontal: _sidePadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  spacing: 8,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: result.kind.label,
                              style: TextStyle(color: result.kind.textColor),
                            ),
                            if (result.unit != null)
                              TextSpan(text: ' ${result.unit}'),
                          ],
                        ),
                        maxLines: 1,
                        style: label,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        result.value,
                        maxLines: 1,
                        style: EndFactTiles.valueStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
