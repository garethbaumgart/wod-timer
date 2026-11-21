import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

/// The live screen's text styles (1.3.0 big clock, 1.3.1 colours), shared
/// by a timer's live screen and Today's WOD's own phases (2.6.0) so both
/// are drawn with the same numbers.
abstract class LiveStyles {
  /// The phase word ("GET READY", "REST").
  static TextStyle phase(Color color, double size) =>
      AppTypography.sectionHeader.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: size * 0.06,
        height: 1,
      );

  /// The big number on the second line ("2/10", the AMRAP count).
  static TextStyle bigNumber(double size) => AppTypography.timerDisplay
      .copyWith(color: Colors.white, fontSize: size, letterSpacing: -1);

  /// The grey words on the second line ("TAP TO COUNT", "CAP 20:00").
  static TextStyle hint(double size) => AppTypography.sectionHeader.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: size * 0.1,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// The small unit beside a number ("ROUNDS", "TIME").
  static TextStyle unit(double size) => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: size * 0.14,
    height: 1,
  );
}

/// The clock's fixed size for a workout: the font that fits its longest
/// value in the width, capped by the slot, with the line box trimmed to
/// the glyphs (even leading at 0.76em) so the box is the ink.
class ClockSpec {
  const ClockSpec({required this.style, required this.boxHeight});

  factory ClockSpec.fit({
    required String reference,
    required double maxWidth,
    required double slotHeight,
    required TextStyle Function(TextStyle style) resolve,
  }) {
    final size = fontSizeFor(
      reference: reference,
      style: resolve(baseStyle(100)),
      maxWidth: maxWidth,
      slotHeight: slotHeight,
    );
    final style = resolve(baseStyle(size));
    return ClockSpec(
      style: style,
      boxHeight: GlyphInk.boxHeight(reference, style),
    );
  }

  final TextStyle style;
  final double boxHeight;

  static const double lineHeight = 0.76;

  static TextStyle baseStyle(double size) =>
      AppTypography.timerDisplay.copyWith(
        fontSize: size,
        letterSpacing: -size * 0.02,
        height: lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// The largest size at which [reference] in [style] (given at 100pt)
  /// fits [maxWidth] and whose line box fits [slotHeight].
  static double fontSizeFor({
    required String reference,
    required TextStyle style,
    required double maxWidth,
    required double slotHeight,
  }) {
    final width100 = GlyphInk.boxWidth(reference, style);
    final height100 = GlyphInk.boxHeight(reference, style);
    final byWidth = width100 > 0 ? maxWidth / width100 * 100 : slotHeight;
    final byHeight = height100 > 0 ? slotHeight / height100 * 100 : slotHeight;
    return math.max<double>(8, math.min(byWidth, byHeight));
  }
}

/// The second line under the clock: what it shows, and the text and style
/// of its lowest glyphs for the centring rule.
typedef LiveSecondLine = ({Widget widget, String text, TextStyle style});

/// What sits above a live screen's phase word in its 30pt (8pt held
/// sideways): Today's WOD's strip and line (2.6.0). The clock is sized
/// from the space a timer on its own has, so a header only moves it down.
abstract class LiveHeader {
  double heightOf(BuildContext context, {required bool landscape});

  Widget build(BuildContext context, {required bool landscape});
}

/// What a timer's live screen shows when the timer is a block of Today's
/// WOD (2.6.0): the session's strip and line on top, the block named in
/// its colour on the get-ready, and HOLD TO STOP ending the whole session.
/// The session page keeps the screen awake and the system UI hidden.
abstract class LiveSessionFrame {
  LiveHeader header(TimerNotifierState state);

  /// The get-ready's second line in place of TAP TO SKIP (which moves to
  /// the session's line): "NEXT · AMRAP 12:00" and the block's colour.
  (String, Color) get gettingReadyFor;

  void stop();

  /// False for a moment after the session changed phase: a tap made on
  /// the screen before (a double tap that skipped a Rest, or ended the
  /// block before) must not skip, pause, resume or finish this one.
  bool get canTap;

  /// The back gesture on the get-ready: never ends the session (only the
  /// very first get-ready goes back to the builder).
  void back();
}

/// The phase-word style at the largest size up to [size] at which [text]
/// fits [maxWidth], so a long line shrinks rather than clipping.
TextStyle fitPhaseStyle(
  BuildContext context,
  String text,
  Color color,
  double size,
  double maxWidth,
) {
  final style = GlyphInk.resolve(context, LiveStyles.phase(color, size));
  final width = GlyphInk.boxWidth(
    text,
    style,
    textScaler: MediaQuery.textScalerOf(context),
  );
  if (width <= maxWidth || width <= 0) return style;
  final fitted = size * maxWidth / width;
  return GlyphInk.resolve(context, LiveStyles.phase(color, fitted));
}

/// The live screen's fixed slots top to bottom (layout rule 1): the phase
/// word, the clock, the second line, the timeline centred under them
/// (layout rule 2) and the slab along the bottom (layout rule 3).
class LiveFrame extends StatelessWidget {
  const LiveFrame({
    required this.landscape,
    required this.clockReference,
    required this.phaseWord,
    required this.clock,
    required this.secondLine,
    required this.timeline,
    required this.slab,
    super.key,
    this.secondLineWhileRunning = true,
    this.header,
  });

  final bool landscape;

  /// The longest value the clock shows (its size is set once from it), or
  /// null before there is a workout.
  final String? clockReference;

  final Widget Function(double fontSize) phaseWord;
  final Widget Function(ClockSpec clock) clock;

  /// The second line, given the big number's style.
  final LiveSecondLine? Function(BuildContext context, TextStyle big)
  secondLine;

  /// False for a count-down For Time: no second line while it runs, so the
  /// zone under the empty slot must still hold a centred bar.
  final bool secondLineWhileRunning;

  final Widget timeline;
  final Widget slab;
  final LiveHeader? header;

  static const double sidePad = 14;
  static const double timelineHeight = 14;
  static const double clockShare = 0.42;

  /// The space above the phase word: 30pt upright, 8pt held sideways.
  static double topPadOf({required bool landscape}) => landscape ? 8 : 30;

  static double phaseSlotOf({required bool landscape}) => landscape ? 32 : 40;

  /// Held sideways in a session: the clear space kept between the clock's
  /// ink and the lines above and below it.
  static const double inkClear = 6;

  /// How far (in em) [reference]'s glyphs paint past the clock's trimmed
  /// line box: a slash well past it, round digits a little.
  static double overshootEmOf(String reference) =>
      reference.contains('/') ? 0.12 : 0.04;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final slabHeight = BottomSlab.heightOf(context);
        final area = constraints.maxHeight - slabHeight;
        final width = constraints.maxWidth - 2 * sidePad;
        final topPad = topPadOf(landscape: landscape);
        final phaseSlot = phaseSlotOf(landscape: landscape);

        // The second line: a fixed slot the height of its big number, every
        // content sharing that number's baseline.
        final bigStyle = GlyphInk.resolve(
          context,
          LiveStyles.bigNumber(landscape ? 44 : 64),
        );
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

        final second = clockReference == null
            ? null
            : secondLine(context, bigStyle);
        final zoneReserve = secondLineWhileRunning
            ? 40.0
            : secondSlot + timelineHeight + 24;
        // Held sideways in a session (2.6.0) the strip and its line take
        // their room from the clock, not from the timeline's zone, and the
        // clock's ink keeps clear of the phase word and the second line.
        // A timer on its own is sized exactly as before.
        final header = this.header;
        final sessionSideways = landscape && header != null;
        final above = sessionSideways
            ? header.heightOf(context, landscape: true)
            : topPad;
        final clockSlot = landscape
            ? math.max<double>(
                80,
                area - above - phaseSlot - secondSlot - zoneReserve,
              )
            : area * clockShare;
        final reference = clockReference;
        TextStyle resolve(TextStyle style) => GlyphInk.resolve(context, style);
        var spec = reference == null
            ? null
            : ClockSpec.fit(
                reference: reference,
                maxWidth: width * 0.94,
                slotHeight: clockSlot,
                resolve: resolve,
              );
        if (sessionSideways && spec != null && reference != null) {
          // A slash or a round digit paints past the trimmed line box:
          // leave that, and [inkClear], above and below the digits.
          final size = spec.style.fontSize!;
          spec = ClockSpec.fit(
            reference: reference,
            maxWidth: width * 0.94,
            slotHeight:
                clockSlot - 2 * (inkClear + overshootEmOf(reference) * size),
            resolve: resolve,
          );
        }

        // Layout rule 2: where the content above the timeline's glyphs end.
        // Measured from what the slot is sized for (the big digits' line
        // and their overshoot, the clock's longest value), not the ticking
        // text, so it is one number per workout (layout rule 1).
        final double aboveInset;
        if (second != null) {
          final own =
              GlyphInk.belowBaselineEm(second.text, second.style.fontWeight!) *
              textScaler.scale(second.style.fontSize!);
          final digits =
              GlyphInk.belowBaselineEm('0', bigStyle.fontWeight!) *
              textScaler.scale(bigStyle.fontSize!);
          aboveInset = (secondSlot - secondBaseline) - math.max(own, digits);
        } else if (spec != null && reference != null) {
          aboveInset =
              secondSlot +
              (clockSlot - spec.boxHeight) / 2 +
              GlyphInk.bottomInset(reference, spec.style);
        } else {
          aboveInset = secondSlot;
        }

        return Column(
          children: [
            if (header == null)
              SizedBox(height: topPad)
            else
              SizedBox(
                height: header.heightOf(context, landscape: landscape),
                child: header.build(context, landscape: landscape),
              ),
            SizedBox(height: phaseSlot, child: phaseWord(28)),
            SizedBox(
              height: clockSlot,
              child: spec == null ? null : clock(spec),
            ),
            SizedBox(
              height: secondSlot,
              child: second == null
                  ? null
                  : Align(
                      alignment: Alignment.topCenter,
                      child: Baseline(
                        baseline: secondBaseline,
                        baselineType: TextBaseline.alphabetic,
                        child: second.widget,
                      ),
                    ),
            ),
            Expanded(
              child: CentredTimeline(
                aboveInkInset: aboveInset,
                height: timelineHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: sidePad),
                  child: timeline,
                ),
              ),
            ),
            slab,
          ],
        );
      },
    );
  }
}
