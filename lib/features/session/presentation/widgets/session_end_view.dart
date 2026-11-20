import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/presentation/widgets/end_fact_tiles.dart';
import 'package:wod_timer/features/timer/presentation/widgets/live_frame.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';

/// One block's result on the session's end screen: the block's name in its
/// colour, a grey unit after it, the value.
@immutable
class BlockResult {
  const BlockResult(this.kind, this.value, {this.unit});

  final BlockKind kind;
  final String value;

  /// Grey word after the block's name in the tile's label ("ROUNDS").
  final String? unit;

  String get label => unit == null ? kind.label : '${kind.label} $unit';

  /// What a block came to, or null for a block with nothing to score (a
  /// Rest): SETS 5, EMOM ROUNDS 10, AMRAP ROUNDS 7, FOR TIME 6:42 (CAP when
  /// the cap ended it), TABATA ROUNDS 8.
  static BlockResult? of(BlockOutcome outcome) {
    final count = '${outcome.count ?? 0}';
    return switch (outcome.block) {
      SetsBlock() => BlockResult(BlockKind.sets, count),
      EmomBlock() => BlockResult(BlockKind.emom, count, unit: 'ROUNDS'),
      AmrapBlock() => BlockResult(BlockKind.amrap, count, unit: 'ROUNDS'),
      TabataBlock() => BlockResult(BlockKind.tabata, count, unit: 'ROUNDS'),
      ForTimeBlock() => BlockResult(
        BlockKind.forTime,
        outcome.capped ? 'CAP' : setupClock(outcome.seconds ?? 0),
      ),
      RestBlock() => null,
    };
  }
}

/// The end screen for a whole session (2.6.0), in the style of the 2.5.1
/// end screens: the word, the config line, the total time as the hero in
/// the session's colour (brand green), one fact tile per scored block
/// three to a row, the strip, AGAIN | DONE. Stopped, it says so and shows
/// only the blocks that were completed.
class SessionEndView extends StatefulWidget {
  const SessionEndView({
    required this.run,
    required this.onAgain,
    required this.onDone,
    super.key,
  });

  final WodRun run;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  /// AGAIN and DONE ignore taps this long after the screen appears, so
  /// the second tap of a double tap on the last SET DONE never restarts
  /// the session or leaves before the results are seen.
  static const tapGuard = Duration(milliseconds: 700);

  @override
  State<SessionEndView> createState() => _SessionEndViewState();

  /// The session's own colour: its hero and AGAIN.
  static const Color accent = AppColors.primary;

  static const double _rowGap = 8;
  static const int perRow = 3;
}

class _SessionEndViewState extends State<SessionEndView> {
  /// Started as the screen appears (not on first use).
  late final Timer _guard;

  @override
  void initState() {
    super.initState();
    _guard = Timer(SessionEndView.tapGuard, () {});
  }

  WodRun get run => widget.run;

  static const Color accent = SessionEndView.accent;
  static const double _topPad = 28;
  static const double _heroGap = 36;
  static const double _tilesGap = 28;

  List<BlockResult> get _results => [
    for (final outcome in run.outcomes) ?BlockResult.of(outcome),
  ];

  @override
  void dispose() {
    _guard.cancel();
    super.dispose();
  }

  void _onAgain() {
    if (!_guard.isActive) widget.onAgain();
  }

  void _onDone() {
    if (!_guard.isActive) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          bottom: false,
          child: OrientationBuilder(
            builder: (context, orientation) => LayoutBuilder(
              builder: (context, constraints) => _build(
                context,
                constraints,
                landscape: orientation == Orientation.landscape,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context,
    BoxConstraints constraints, {
    required bool landscape,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final word = run.stopped ? 'Stopped' : 'Finished';
    final blocks = run.blockCount;
    final configText =
        "TODAY'S WOD  ·  $blocks ${blocks == 1 ? 'BLOCK' : 'BLOCKS'}";
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
    final time = setupClock(run.totalMs ~/ 1000);
    final results = _results;
    final rows = (results.length / SessionEndView.perRow).ceil();
    final tilesHeight = rows == 0
        ? 0.0
        : rows * EndFactTiles.heightOf(context) +
              (rows - 1) * SessionEndView._rowGap;
    const stripZone = LiveFrame.timelineHeight + 2 * 24;
    final topPad = landscape ? 16.0 : _topPad;
    final header =
        topPad +
        GlyphInk.boxHeight(word, wordStyle, textScaler: textScaler) +
        4 +
        GlyphInk.boxHeight(configText, configStyle, textScaler: textScaler);
    final slab = BottomSlab.heightOf(context);

    // What the hero may take: everything but the header, the gaps, the
    // tiles (upright), the strip's zone and the slab.
    final heroWidth = landscape
        ? (constraints.maxWidth - 48) / 2 * 0.86
        : (constraints.maxWidth - 32) * 0.86;
    final heroRoom = landscape
        ? constraints.maxHeight - header - 12 - stripZone - slab - 32
        : constraints.maxHeight -
              header -
              _heroGap -
              _tilesGap -
              math.min(tilesHeight, EndFactTiles.heightOf(context) * 2) -
              stripZone -
              slab -
              40;
    final heroStyle = GlyphInk.resolve(
      context,
      _heroStyle(
        ClockSpec.fontSizeFor(
          reference: time,
          style: GlyphInk.resolve(context, _heroStyle(100)),
          maxWidth: heroWidth,
          slotHeight: math.max(
            40,
            math.min(constraints.maxHeight * 0.22, heroRoom),
          ),
        ),
      ),
    );
    // The hero's line box is trimmed to its cap height: keep the label
    // clear of the round digits' overshoot.
    final overshoot = math.max(
      0,
      GlyphInk.glyphBottom(time, heroStyle) -
          GlyphInk.boxHeight(time, heroStyle),
    );
    final hero = Semantics(
      label: 'Total time $time',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: overshoot.toDouble()),
            child: Text(
              time,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: heroStyle,
            ),
          ),
          Text('TIME', style: unit),
        ],
      ),
    );
    final tiles = results.isEmpty
        ? const SizedBox.shrink()
        : _BlockTiles(results: results);
    final strip = SessionStrip(
      blocks: run.session.blocks,
      height: LiveFrame.timelineHeight,
      // Stopped: the blocks run filled, the rest outlined.
      doneThrough: run.stopped ? run.outcomes.length - 1 : null,
    );
    final heading = [
      SizedBox(height: topPad),
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
    ];
    final endSlab = BottomSlab(
      cells: [
        SlabCell(
          label: 'AGAIN',
          background: accent,
          foreground: Colors.black,
          onTap: _onAgain,
          semanticsLabel: 'Run the same session again',
        ),
        SlabCell(
          label: 'DONE',
          background: AppColors.soft,
          foreground: Colors.white,
          onTap: _onDone,
          semanticsLabel: 'Done, back to Home',
        ),
      ],
    );

    if (landscape) {
      return Column(
        children: [
          ...heading,
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Center(child: hero)),
                if (results.isNotEmpty)
                  Expanded(
                    child: Center(child: SingleChildScrollView(child: tiles)),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: stripZone,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: strip,
              ),
            ),
          ),
          endSlab,
        ],
      );
    }

    // Upright: the tiles scroll when there are more rows than fit.
    final tilesMax = math.max(
      EndFactTiles.heightOf(context),
      constraints.maxHeight -
          header -
          _heroGap -
          GlyphInk.boxHeight(time, heroStyle) -
          overshoot -
          6 -
          GlyphInk.boxHeight('TIME', unit, textScaler: textScaler) -
          _tilesGap -
          stripZone -
          slab,
    );
    return Column(
      children: [
        ...heading,
        const SizedBox(height: _heroGap),
        hero,
        if (results.isNotEmpty) ...[
          const SizedBox(height: _tilesGap),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: tilesMax),
            child: SingleChildScrollView(child: tiles),
          ),
        ],
        Expanded(
          child: CentredTimeline(
            // The tiles' filled boxes are their lowest ink; with none, the
            // TIME label's glyphs.
            aboveInkInset: results.isNotEmpty
                ? 0
                : GlyphInk.bottomInset('TIME', unit, textScaler: textScaler),
            height: LiveFrame.timelineHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: strip,
            ),
          ),
        ),
        endSlab,
      ],
    );
  }

  static TextStyle _heroStyle(double size) =>
      AppTypography.timerDisplay.copyWith(
        color: accent,
        fontSize: size,
        letterSpacing: -size * 0.02,
        height: ClockSpec.lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

/// The end screen's fact tiles with one block each, three to a row and
/// wrapping: the tile, its padding and its two text styles are
/// [EndFactTiles]'s; only the label differs (the block's name in its
/// colour, then a grey unit). One label size for every tile, set from the
/// longest label, so no two differ.
class _BlockTiles extends StatelessWidget {
  const _BlockTiles({required this.results});

  final List<BlockResult> results;

  static const double _sidePadding = 8;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: EndFactTiles.maxTextScale);
    final base = GlyphInk.resolve(context, EndFactTiles.labelStyle());
    const perRow = SessionEndView.perRow;
    final tile =
        (MediaQuery.sizeOf(context).width -
            32 -
            EndFactTiles.spacing * (perRow - 1)) /
        perRow;
    final longest = results
        .map((r) => GlyphInk.boxWidth(r.label, base, textScaler: scaler))
        .reduce(math.max);
    final scale = math.min(1, (tile - 2 * _sidePadding) / longest);
    final label = EndFactTiles.labelStyle().copyWith(
      fontSize: EndFactTiles.labelSize * scale,
      letterSpacing: EndFactTiles.labelSize * 0.14 * scale,
    );
    final rows = [
      for (var i = 0; i < results.length; i += perRow)
        results.sublist(i, math.min(i + perRow, results.length)),
    ];
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          spacing: SessionEndView._rowGap,
          children: [
            for (final row in rows)
              Row(
                spacing: EndFactTiles.spacing,
                children: [
                  for (final result in row)
                    Expanded(child: _tile(result, label)),
                  // A short last row keeps the tiles their width.
                  for (var i = row.length; i < perRow; i++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BlockResult result, TextStyle label) {
    return Semantics(
      label: '${result.label.toLowerCase()} ${result.value}',
      excludeSemantics: true,
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
                    if (result.unit != null) TextSpan(text: ' ${result.unit}'),
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
    );
  }
}
