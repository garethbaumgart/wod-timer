import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';
import 'package:wod_timer/preview/todays_wod/live_styles.dart';
import 'package:wod_timer/preview/todays_wod/session_widgets.dart';

/// PROTOTYPE ONLY. The session's place on a live screen: the strip of
/// blocks and one small line under it ("BLOCK 3 OF 5 · NEXT REST 2:00").
///
/// It takes the place of the 30pt the live screen keeps above the phase
/// word today and is [heightOf] tall, so everything under it sits
/// `heightOf - 30` lower and keeps its size.
class SessionHeader extends StatelessWidget {
  const SessionHeader({required this.current, required this.line, super.key});

  /// Index of the block running.
  final int current;
  final String line;

  static const double stripHeight = 8;

  /// Top edge to the strip, the strip to the line's capitals, and the
  /// line's baseline to the bottom edge.
  static const double above = 8;
  static const double gap = 9;
  static const double below = 10;

  static const double _fontSize = 13;

  static TextStyle lineStyle() => LiveStyles.unit(
    _fontSize,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static double _capHeight(BuildContext context) =>
      GlyphInk.capHeightEm(FontWeight.w800) *
      MediaQuery.textScalerOf(context).scale(_fontSize);

  static double heightOf(BuildContext context) =>
      above + stripHeight + gap + _capHeight(context) + below;

  @override
  Widget build(BuildContext context) {
    final style = GlyphInk.resolve(context, lineStyle());
    final textScaler = MediaQuery.textScalerOf(context);
    final baseline = GlyphInk.baseline(line, style, textScaler: textScaler);
    // The line's box is placed so its capitals start [gap] under the strip.
    final lineTop = above + stripHeight + gap + _capHeight(context) - baseline;
    return SizedBox(
      height: heightOf(context),
      child: Stack(
        children: [
          Positioned(
            top: above,
            left: LiveStyles.sidePad,
            right: LiveStyles.sidePad,
            child: SessionStrip(current: current),
          ),
          Positioned(
            top: lineTop,
            left: LiveStyles.sidePad,
            right: LiveStyles.sidePad,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(line, maxLines: 1, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the second line under the clock shows.
@immutable
class SecondLine {
  /// The big white number ("2/10").
  const SecondLine.big(this.text) : color = null, _kind = _SecondKind.big;

  /// The grey words ("TAP TO SKIP").
  const SecondLine.hint(this.text) : color = null, _kind = _SecondKind.hint;

  /// A phase word in a colour ("NEXT · AMRAP 12:00").
  const SecondLine.word(this.text, Color this.color) : _kind = _SecondKind.word;

  final String text;
  final Color? color;
  final _SecondKind _kind;
}

enum _SecondKind { big, hint, word }

/// PROTOTYPE ONLY. One frozen moment of a live screen in a session: the
/// live screen's own slots (upright), drawn from fixed values, under the
/// session header.
class PreviewLiveScreen extends StatefulWidget {
  const PreviewLiveScreen({
    required this.block,
    required this.line,
    required this.clock,
    required this.clockReference,
    required this.clockColor,
    required this.shape,
    required this.elapsedSeconds,
    required this.slab,
    super.key,
    this.phase,
    this.second,
    this.onCanvasTap,
  });

  /// Index of the block running, and the line under the strip.
  final int block;
  final String line;

  /// The phase word above the clock and its colour.
  final (String, Color)? phase;

  /// The digits, the longest value this block's clock shows (its size is
  /// set once from that), and their colour.
  final String clock;
  final String clockReference;
  final Color clockColor;

  final SecondLine? second;

  /// The block's own timeline, as progress.
  final WorkoutShape shape;
  final double elapsedSeconds;

  /// The slab's cells.
  final List<Widget> slab;

  final VoidCallback? onCanvasTap;

  @override
  State<PreviewLiveScreen> createState() => _PreviewLiveScreenState();
}

class _PreviewLiveScreenState extends State<PreviewLiveScreen> {
  @override
  void initState() {
    super.initState();
    // As the live screen does.
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
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onCanvasTap,
          child: LayoutBuilder(builder: _buildLive),
        ),
      ),
    );
  }

  Widget _buildLive(BuildContext context, BoxConstraints constraints) {
    final textScaler = MediaQuery.textScalerOf(context);
    // The clock is sized from the space the live screen has today (the
    // header only moves it down), so a session never shrinks it.
    final area = constraints.maxHeight - BottomSlab.heightOf(context);
    final width = constraints.maxWidth - 2 * LiveStyles.sidePad;

    final bigStyle = GlyphInk.resolve(context, LiveStyles.bigNumber(64));
    final secondSlot = GlyphInk.boxHeight(
      '0',
      bigStyle,
      textScaler: textScaler,
    );
    final secondBaseline = GlyphInk.baseline(
      '0',
      bigStyle,
      textScaler: textScaler,
    );
    final clockSlot = area * LiveStyles.clockShare;
    final clock = ClockSpec.fit(
      reference: widget.clockReference,
      maxWidth: width * 0.94,
      slotHeight: clockSlot,
      resolve: (style) => GlyphInk.resolve(context, style),
    );

    final second = widget.second;
    final secondStyle = second == null
        ? null
        : GlyphInk.resolve(context, switch (second._kind) {
            _SecondKind.big => LiveStyles.bigNumber(64),
            _SecondKind.hint => LiveStyles.hint(26),
            _SecondKind.word => LiveStyles.phase(second.color!, 26),
          });

    // Layout rule 2, as on the live screen: where the glyphs above the
    // timeline end.
    final double aboveInset;
    if (second != null && secondStyle != null) {
      final own =
          GlyphInk.belowBaselineEm(second.text, secondStyle.fontWeight!) *
          textScaler.scale(secondStyle.fontSize!);
      final digits =
          GlyphInk.belowBaselineEm('0', bigStyle.fontWeight!) *
          textScaler.scale(bigStyle.fontSize!);
      aboveInset = (secondSlot - secondBaseline) - math.max(own, digits);
    } else {
      aboveInset =
          secondSlot +
          (clockSlot - clock.boxHeight) / 2 +
          GlyphInk.bottomInset(widget.clockReference, clock.style);
    }

    final phase = widget.phase;
    return Column(
      children: [
        SessionHeader(current: widget.block, line: widget.line),
        SizedBox(
          height: LiveStyles.phaseSlot,
          child: phase == null
              ? null
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      phase.$1,
                      maxLines: 1,
                      style: LiveStyles.phase(phase.$2, 28),
                    ),
                  ),
                ),
        ),
        SizedBox(height: clockSlot, child: _buildClock(clock)),
        SizedBox(
          height: secondSlot,
          child: second == null
              ? null
              : Align(
                  alignment: Alignment.topCenter,
                  child: Baseline(
                    baseline: secondBaseline,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(second.text, maxLines: 1, style: secondStyle),
                  ),
                ),
        ),
        Expanded(
          child: CentredTimeline(
            aboveInkInset: aboveInset,
            height: LiveStyles.timelineHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LiveStyles.sidePad,
              ),
              child: WorkoutTimeline(
                shape: widget.shape,
                height: LiveStyles.timelineHeight,
                elapsedSeconds: widget.elapsedSeconds,
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: BottomSlab(cells: widget.slab),
        ),
      ],
    );
  }

  /// The digits with the radial wash behind them, as on the live screen.
  Widget _buildClock(ClockSpec clock) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.clockColor.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            widget.clock,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: clock.style.copyWith(color: widget.clockColor),
          ),
        ),
      ],
    );
  }
}
