import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/pages/timer_active_page.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';
import 'package:wod_timer/features/timer/presentation/widgets/live_frame.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// The session's place on a live screen (2.6.0): the strip of blocks and
/// one small line under it ("BLOCK 3 OF 5 · NEXT REST 2:00"), in place of
/// the 30pt a live screen keeps above its phase word, so everything under
/// it sits lower and keeps its size. Held sideways the line sits beside
/// the strip, in the 8pt's place plus one line.
class SessionHeader implements LiveHeader {
  const SessionHeader({
    required this.blocks,
    required this.current,
    required this.line,
  });

  final List<SessionBlock> blocks;
  final int current;
  final String line;

  static const double stripHeight = 8;

  /// Top edge to the strip, the strip to the line's capitals, and the
  /// line's baseline to the bottom edge (upright).
  static const double above = 8;
  static const double gap = 9;
  static const double below = 10;

  static const double _fontSize = 13;

  /// The line for [run]: which block, and what is next or, where the
  /// screen can be skipped, TAP TO SKIP. The last block names nothing next.
  static String lineFor(WodRun run, {required bool skippable}) {
    final where = 'BLOCK ${run.index + 1} OF ${run.blockCount}';
    if (skippable) return '$where · TAP TO SKIP';
    final next = run.next;
    return next == null ? where : '$where · NEXT ${next.title}';
  }

  static TextStyle lineStyle() => LiveStyles.unit(
    _fontSize,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static double _capHeight(BuildContext context) =>
      GlyphInk.capHeightEm(FontWeight.w800) *
      MediaQuery.textScalerOf(context).scale(_fontSize);

  static double _lineBox(BuildContext context) => GlyphInk.boxHeight(
    'B',
    GlyphInk.resolve(context, lineStyle()),
    textScaler: MediaQuery.textScalerOf(context),
  );

  @override
  double heightOf(BuildContext context, {required bool landscape}) => landscape
      ? LiveFrame.topPadOf(landscape: true) + _lineBox(context) + 4
      : above + stripHeight + gap + _capHeight(context) + below;

  @override
  Widget build(BuildContext context, {required bool landscape}) {
    final style = GlyphInk.resolve(context, lineStyle());
    final strip = SessionStrip(blocks: blocks, current: current);
    if (landscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          LiveFrame.sidePad,
          8,
          LiveFrame.sidePad,
          4,
        ),
        child: Row(
          children: [
            Expanded(child: Center(child: strip)),
            const SizedBox(width: 14),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(line, maxLines: 1, style: style),
              ),
            ),
          ],
        ),
      );
    }
    final textScaler = MediaQuery.textScalerOf(context);
    final baseline = GlyphInk.baseline(line, style, textScaler: textScaler);
    // The line's box is placed so its capitals start [gap] under the strip.
    final lineTop = above + stripHeight + gap + _capHeight(context) - baseline;
    return Stack(
      children: [
        Positioned(
          top: above,
          left: LiveFrame.sidePad,
          right: LiveFrame.sidePad,
          child: strip,
        ),
        Positioned(
          top: lineTop,
          left: LiveFrame.sidePad,
          right: LiveFrame.sidePad,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(line, maxLines: 1, style: style),
            ),
          ),
        ),
      ],
    );
  }
}

/// Today's WOD running (2.6.0): every block on one route. A timer block is
/// the timer's own live screen under the session's strip; a Sets block's
/// get-ready, its sets and their rests and a Rest block are drawn here in
/// the same slots; the end is the session's own end screen. The screen
/// stays awake and the system UI hidden for the whole session.
class SessionActivePage extends ConsumerStatefulWidget {
  const SessionActivePage({super.key});

  @override
  ConsumerState<SessionActivePage> createState() => _SessionActivePageState();
}

class _SessionActivePageState extends ConsumerState<SessionActivePage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  TodaysWodController get _controller => ref.read(todaysWodProvider.notifier);

  /// This page sent her somewhere: the run ending is not a cold link.
  bool _leaving = false;

  /// HOLD TO STOP: before anything has happened (the first get-ready),
  /// back to the builder as a timer goes back to setup; otherwise the end
  /// screen in its stopped form.
  void _stop() {
    if (_controller.nothingDoneYet) {
      _leaving = true;
      _controller.exit();
      context.go(AppRoutes.todaysWod);
      return;
    }
    _controller.stop();
  }

  void _done() {
    _leaving = true;
    _controller.exit();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(todaysWodProvider);
    if (run == null) {
      // Nothing running (DONE, or a cold link): Home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_leaving && ref.read(todaysWodProvider) == null) {
          context.go(AppRoutes.home);
        }
      });
      return const Scaffold(backgroundColor: AppColors.backgroundDark);
    }
    if (run.isFinished) {
      // The session's end screen comes in P6.
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: TextButton(onPressed: _done, child: const Text('DONE')),
        ),
      );
    }
    if (run.phase == WodPhase.timer) {
      // The timer is still starting (a frame at most): hold the ink.
      if (ref.watch(timerNotifierProvider) is TimerInitial) {
        return const Scaffold(backgroundColor: AppColors.backgroundDark);
      }
      return TimerActivePage(
        key: ValueKey('timer-${run.index}'),
        timerType: run.block.kind.code,
        session: _TimerBlockFrame(run: run, onStop: _stop),
      );
    }
    return SessionPhaseView(
      key: ValueKey('phase-${run.index}'),
      run: run,
      onStop: _stop,
    );
  }
}

/// What a timer block's live screen shows of the session.
class _TimerBlockFrame implements LiveSessionFrame {
  const _TimerBlockFrame({required this.run, required this.onStop});

  final WodRun run;
  final VoidCallback onStop;

  @override
  LiveHeader header(TimerNotifierState state) => SessionHeader(
    blocks: run.session.blocks,
    current: run.index,
    line: SessionHeader.lineFor(run, skippable: state is TimerPreparing),
  );

  @override
  (String, Color) get gettingReadyFor =>
      ('NEXT · ${run.block.title}', run.block.kind.color);

  @override
  void stop() => onStop();
}

/// A Sets block's get-ready, a set, the rest after it, or a Rest block, in
/// the timer's live slots: the phase word, the clock at the size the
/// block's longest value sets, one second line, the block's timeline, the
/// slab. Tap above the slab to skip a get-ready or a rest, or to resume.
class SessionPhaseView extends ConsumerStatefulWidget {
  const SessionPhaseView({required this.run, required this.onStop, super.key});

  final WodRun run;
  final VoidCallback onStop;

  @override
  ConsumerState<SessionPhaseView> createState() => _SessionPhaseViewState();
}

class _SessionPhaseViewState extends ConsumerState<SessionPhaseView>
    with SingleTickerProviderStateMixin {
  /// Pulses the digits while paused, as on a timer.
  late final AnimationController _pausedPulse;
  bool _showHoldHint = false;

  WodRun get run => widget.run;
  TodaysWodController get _controller => ref.read(todaysWodProvider.notifier);

  @override
  void initState() {
    super.initState();
    _pausedPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 0.9,
    );
  }

  @override
  void dispose() {
    _pausedPulse.dispose();
    super.dispose();
  }

  void _flashHoldHint() {
    setState(() => _showHoldHint = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showHoldHint = false);
    });
  }

  bool get _skippable =>
      run.phase == WodPhase.getReady ||
      run.phase == WodPhase.rest ||
      run.phase == WodPhase.setRest;

  void _onCanvasTap() {
    if (run.paused) {
      _controller.resume();
    } else if (_skippable) {
      _controller.skip();
    }
  }

  void _onPopAttempt() {
    if (run.phase == WodPhase.getReady) {
      widget.onStop();
    } else if (run.paused) {
      _flashHoldHint();
    }
    // Mid-set or mid-rest: pause first, then hold Stop.
  }

  // The block's numbers.

  SessionBlock get _block => run.block;

  /// A countdown the way the timer shows one: bare seconds under a minute
  /// and in a phase of a minute or less, M:SS otherwise.
  static String _countdown(int seconds, int phaseSeconds) =>
      seconds < 60 || phaseSeconds <= 60 ? '$seconds' : setupClock(seconds);

  static String _phaseDisplay(int seconds) =>
      seconds <= 60 ? '$seconds' : setupClock(seconds);

  /// The longest value this block's clock shows, so it never refits: a
  /// Rest its length; a Sets block the longer of "5/5" and its rest.
  String get _clockReference => switch (_block) {
    RestBlock(:final seconds) => _phaseDisplay(seconds),
    SetsBlock(:final sets, :final restSeconds) => _longer(
      '$sets/$sets',
      _phaseDisplay(restSeconds),
    ),
    _ => '0',
  };

  static String _longer(String a, String b) => b.length > a.length ? b : a;

  String get _clockText => switch (run.phase) {
    WodPhase.setWork => '${run.set}/${(_block as SetsBlock).sets}',
    WodPhase.getReady => '${run.remainingSeconds}',
    _ => _countdown(run.remainingSeconds, run.phaseSeconds),
  };

  Color get _digitColor => switch (run.phase) {
    WodPhase.getReady => AppColors.prepare,
    WodPhase.setWork => AppColors.setsAccent,
    _ => AppColors.rest,
  };

  (String, Color) get _phaseWord {
    if (run.paused) return ('PAUSED', AppColors.paused);
    return switch (run.phase) {
      WodPhase.getReady => ('GET READY', AppColors.prepare),
      WodPhase.setWork => ('SET', AppColors.setsAccent),
      WodPhase.setRest => ('REST · SET ${run.set + 1} NEXT', AppColors.rest),
      _ => ('REST', AppColors.rest),
    };
  }

  /// The block's timeline as progress. A set has no clock: the set under
  /// way is drawn whole, its rest fills as it counts.
  double get _elapsedSeconds {
    final block = _block;
    if (block is! SetsBlock) return run.phaseElapsedMs / 1000;
    const set = SetsBlock.setSeconds;
    final before = (run.set - 1) * (set + block.restSeconds);
    return switch (run.phase) {
      WodPhase.getReady => 0,
      WodPhase.setWork => before + set.toDouble(),
      _ => before + set + run.phaseElapsedMs / 1000,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (run.paused) {
      if (!_pausedPulse.isAnimating) _pausedPulse.repeat(reverse: true);
    } else if (_pausedPulse.isAnimating) {
      _pausedPulse
        ..stop()
        ..value = _pausedPulse.upperBound;
    }
    final canvasTaps = run.paused || _skippable;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          bottom: false,
          child: Semantics(
            label: _accessibilityLabel,
            liveRegion: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canvasTaps ? _onCanvasTap : null,
              child: OrientationBuilder(
                builder: (context, orientation) =>
                    _buildLive(landscape: orientation == Orientation.landscape),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _accessibilityLabel {
    final (word, _) = _phaseWord;
    final hint = run.paused
        ? '. Tap anywhere to resume. Hold the stop button to end.'
        : _skippable
        ? '. Tap to skip.'
        : '. Tap set done when the set is done.';
    final value = run.phase == WodPhase.setWork
        ? 'set ${run.set} of ${(_block as SetsBlock).sets}'
        : '${run.remainingSeconds} seconds remaining';
    return "Today's WOD, block ${run.index + 1} of ${run.blockCount}. "
        '$word, $value$hint';
  }

  Widget _buildLive({required bool landscape}) {
    return LiveFrame(
      landscape: landscape,
      header: SessionHeader(
        blocks: run.session.blocks,
        current: run.index,
        line: SessionHeader.lineFor(
          run,
          skippable:
              run.phase == WodPhase.getReady || run.phase == WodPhase.rest,
        ),
      ),
      clockReference: _clockReference,
      phaseWord: (fontSize) {
        final (text, color) = _phaseWord;
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: LiveStyles.phase(color, fontSize),
            ),
          ),
        );
      },
      clock: _buildClock,
      secondLine: (context, big) => _secondLine(context, landscape: landscape),
      timeline: WorkoutTimeline(
        shape: _block.shape,
        height: LiveFrame.timelineHeight,
        elapsedSeconds: _elapsedSeconds,
      ),
      slab: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: _buildSlab(),
      ),
    );
  }

  Widget _buildClock(ClockSpec clock) {
    final text = _clockText;
    final pulsing =
        run.phase == WodPhase.getReady &&
        run.remainingSeconds <= 3 &&
        run.remainingSeconds > 0;
    Widget digits = Text(
      text,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: clock.style.copyWith(color: _digitColor),
    );
    digits = AnimatedScale(
      scale: pulsing ? 1.08 : 1,
      duration: const Duration(milliseconds: 200),
      child: digits,
    );
    if (run.paused) {
      digits = FadeTransition(opacity: _pausedPulse, child: digits);
    }
    final wash = run.paused ? AppColors.paused : _digitColor;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // The live screen's wash: fades out by the slot's nearest edge.
              gradient: RadialGradient(
                colors: [
                  wash.withValues(alpha: run.paused ? 0.08 : 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(child: digits),
      ],
    );
  }

  /// The second line: what comes next (a get-ready, a Rest block), what
  /// follows the set, or TAP TO SKIP in a set's rest. Always one, so the
  /// timeline under it never moves between a set and its rest.
  LiveSecondLine _secondLine(BuildContext context, {required bool landscape}) {
    final width = MediaQuery.sizeOf(context).width - 2 * LiveFrame.sidePad;
    LiveSecondLine word(String text, Color color) {
      final style = fitPhaseStyle(
        context,
        text,
        color,
        landscape ? 20 : 26,
        width,
      );
      return (
        widget: Text(text, maxLines: 1, style: style),
        text: text,
        style: style,
      );
    }

    LiveSecondLine hint(String text) {
      final style = GlyphInk.resolve(
        context,
        LiveStyles.hint(landscape ? 20 : 26),
      );
      return (
        widget: Text(text, maxLines: 1, style: style),
        text: text,
        style: style,
      );
    }

    final block = _block;
    switch (run.phase) {
      case WodPhase.getReady:
        return word('NEXT · ${block.title}', block.kind.color);
      case WodPhase.rest:
        final next = run.next;
        return next == null
            ? hint('LAST BLOCK')
            : word('NEXT · ${next.title}', next.kind.color);
      case WodPhase.setWork:
        final sets = block as SetsBlock;
        return hint(
          run.set >= sets.sets
              ? 'LAST SET'
              : 'THEN REST ${setupClock(sets.restSeconds)}',
        );
      case WodPhase.setRest || WodPhase.timer || WodPhase.finished:
        return hint('TAP TO SKIP');
    }
  }

  Widget _buildSlab() {
    final stop = HoldToStopCell(
      enabled: true,
      showHint: _showHoldHint,
      onConfirmed: widget.onStop,
      onShortPress: _flashHoldHint,
    );
    final pause = SlabCell(
      label: 'PAUSE',
      background: AppColors.soft,
      foreground: Colors.white,
      onTap: _controller.pause,
      semanticsLabel: 'Pause button',
    );
    if (run.phase == WodPhase.getReady) return BottomSlab(cells: [stop]);
    if (run.paused) {
      return BottomSlab(
        cells: [
          stop,
          SlabCell(
            label: 'RESUME',
            background: _block.kind.clockColor,
            foreground: Colors.black,
            onTap: _controller.resume,
            semanticsLabel: 'Resume button',
          ),
        ],
      );
    }
    if (run.phase == WodPhase.setWork) {
      return BottomSlab(
        cells: [
          SlabCell(
            label: 'SET DONE',
            background: AppColors.setsAccent,
            foreground: Colors.black,
            onTap: () {
              ref.read(hapticServiceProvider).mediumImpact();
              _controller.setDone();
            },
            semanticsLabel: 'Set done. Starts the rest.',
          ),
          pause,
        ],
      );
    }
    return BottomSlab(cells: [pause]);
  }
}
