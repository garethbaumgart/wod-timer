// End-screen mocks (15 Nov 2026). Web only: ?mock=N&end=<mode> opens a
// finished workout of that mode; N picks the layout (0 = today). Not for main.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

final Map<String, String> _q = kIsWeb
    ? Uri.base.queryParameters
    : const <String, String>{};

/// 0 = today's end screen; 1 Stat row, 2 Two numbers, 3 Result card,
/// 4 Receipt, 5 Round chart.
final int mockEndVariant = int.tryParse(_q['mock'] ?? '') ?? 0;

/// The mode whose finished workout the mock opens, or null.
final String? mockEndMode = _q['end'];

/// Simulated iPhone insets so the web render matches the phone.
final bool mockPhoneInsets = kIsWeb;

final DateTime _start = DateTime(2026, 11, 15, 6, 32, 10);

/// A finished workout for [mode], with believable numbers.
TimerSession mockEndSession(String mode) {
  Workout workout(TimerType type, WorkoutName name) => Workout(
    id: UniqueId(),
    name: name,
    timerType: type,
    prepCountdown: TimerDuration.fromSeconds(10),
    createdAt: _start,
  );
  final (w, round, seconds) = switch (mode) {
    'fortime' => (
      workout(
        ForTimeTimer(timeCap: TimerDuration.fromSeconds(1200), countUp: true),
        WorkoutName.defaultForTime,
      ),
      1,
      872,
    ),
    'emom' => (
      workout(
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        ),
        WorkoutName.defaultEmom,
      ),
      10,
      600,
    ),
    'tabata' => (
      workout(
        TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(8),
        ),
        WorkoutName.defaultTabata,
      ),
      8,
      240,
    ),
    _ => (
      workout(
        AmrapTimer(duration: TimerDuration.fromSeconds(600)),
        WorkoutName.defaultAmrap,
      ),
      8,
      600,
    ),
  };
  return TimerSession(
    id: UniqueId(),
    workout: w,
    state: domain.TimerState.completed,
    currentRound: round,
    elapsed: TimerDuration.fromSeconds(seconds),
    currentIntervalElapsed: TimerDuration.zero,
    startedAt: _start,
    completedAt: _start.add(Duration(seconds: seconds)),
  );
}

/// Opens straight onto a finished workout (the mock's only state).
class MockEndNotifier extends TimerNotifier {
  @override
  TimerNotifierState build() =>
      TimerNotifierState.completed(session: mockEndSession(mockEndMode!));
}

String _clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

String _day(DateTime t) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${days[t.weekday - 1]} ${t.day} ${months[t.month - 1]}';
}

/// What a finished workout can say, from what the session already holds.
class EndFacts {
  EndFacts(this.session);

  final TimerSession session;

  int get elapsed => session.elapsed.seconds;
  String get time => setupClock(elapsed);
  DateTime get finishedAt =>
      session.completedAt ?? _start.add(Duration(seconds: elapsed));
  String get finished => _clockTime(finishedAt);
  String get started => _clockTime(session.startedAt ?? _start);
  String get day => _day(finishedAt);
  int get amrapRounds => session.currentRound - 1;

  /// The hero value and its label.
  (String, String) hero(String mode) => switch (mode) {
    'fortime' => (time, 'TIME'),
    'amrap' => ('$amrapRounds', 'ROUNDS'),
    _ => ('${session.currentRound}/${session.totalRounds}', 'ROUNDS'),
  };

  String get perRound =>
      amrapRounds == 0 ? '-' : setupClock((elapsed / amrapRounds).round());

  String get underCap => session.workout.timerType.maybeWhen(
    forTime: (t) => setupClock(math.max(0, t.timeCap.seconds - elapsed)),
    orElse: () => '-',
  );

  String get cap => session.workout.timerType.maybeWhen(
    forTime: (t) => setupClock(t.timeCap.seconds),
    orElse: () => '-',
  );

  String get every => session.workout.timerType.maybeWhen(
    emom: (t) => setupClock(t.intervalDuration.seconds),
    orElse: () => '-',
  );

  (String, String) get workRest => session.workout.timerType.maybeWhen(
    tabata: (t) => (
      setupClock(t.workDuration.seconds * session.currentRound),
      setupClock(t.restDuration.seconds * session.currentRound),
    ),
    orElse: () => ('-', '-'),
  );

  /// The second number for "Two numbers": the next most useful fact.
  (String, String) second(String mode) => switch (mode) {
    'amrap' => (perRound, 'PER ROUND'),
    'fortime' => (underCap, 'UNDER THE CAP'),
    _ => (time, 'TIME'),
  };

  /// Three facts for the stat row.
  List<(String, String)> three(String mode) => switch (mode) {
    'amrap' => [('TIME', time), ('PER ROUND', perRound), ('FINISHED', finished)],
    'fortime' => [('CAP', cap), ('UNDER CAP', underCap), ('FINISHED', finished)],
    'emom' => [('TIME', time), ('EVERY', every), ('FINISHED', finished)],
    _ => [('TIME', time), ('WORK', workRest.$1), ('FINISHED', finished)],
  };

  /// Four facts for the card and the receipt.
  List<(String, String)> four(String mode) => switch (mode) {
    'amrap' => [
      ('Time', time),
      ('Per round', perRound),
      ('Started', started),
      ('Finished', finished),
    ],
    'fortime' => [
      ('Time cap', cap),
      ('Under the cap', underCap),
      ('Started', started),
      ('Finished', finished),
    ],
    'emom' => [
      ('Time', time),
      ('Every', every),
      ('Started', started),
      ('Finished', finished),
    ],
    _ => [
      ('Time', time),
      ('Work', workRest.$1),
      ('Rest', workRest.$2),
      ('Finished', finished),
    ],
  };
}

/// The five layouts. The page hands in its own header strings, styles,
/// wheel and slab so everything shared stays exactly as the app draws it.
class MockEndBody extends StatelessWidget {
  const MockEndBody({
    required this.variant,
    required this.mode,
    required this.session,
    required this.word,
    required this.configText,
    required this.modeColor,
    required this.heroStyle,
    required this.unitStyle,
    required this.elapsedSeconds,
    required this.onRoundsChanged,
    required this.slab,
    super.key,
  });

  final int variant;
  final String mode;
  final TimerSession session;
  final String word;
  final String configText;
  final Color modeColor;
  final TextStyle Function(double size) heroStyle;
  final TextStyle Function(double size) unitStyle;
  final double elapsedSeconds;
  final ValueChanged<int> onRoundsChanged;
  final Widget slab;

  EndFacts get f => EndFacts(session);

  TextStyle get _wordStyle => AppTypography.heroTitle.copyWith(
    color: Colors.white,
    fontSize: 30,
    letterSpacing: -0.3,
  );

  TextStyle _num(double size, {Color color = Colors.white}) =>
      AppTypography.timerDisplay.copyWith(
        color: color,
        fontSize: size,
        letterSpacing: -size * 0.02,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  TextStyle _label(double size, {Color color = AppColors.textSecondaryDark}) =>
      AppTypography.labelSmall.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.14,
        height: 1.1,
      );

  /// The font size at which [text] fills [maxWidth], capped at [cap].
  double _fit(String text, TextStyle Function(double) style, double maxWidth,
      double cap) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style(100)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return math.min(cap, 100 * maxWidth / painter.width);
  }

  Widget _header({double top = 28}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(height: top),
      Text(word, style: _wordStyle),
      const SizedBox(height: 4),
      Text(configText, maxLines: 1, style: unitStyle(14)),
    ],
  );

  /// The hero: AMRAP's wheel, or the big number, with its label.
  Widget _hero(double width, {double cap = 170, bool label = true}) {
    final (value, unit) = f.hero(mode);
    if (mode == 'amrap') {
      // Smaller than today's wheel: the facts below need the room.
      final size = _fit('0/00', heroStyle, width * 0.86, cap * 0.56);
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          RoundsWheel(
            rounds: f.amrapRounds,
            fontSize: size,
            onChanged: onRoundsChanged,
          ),
          if (label) Text(unit, style: unitStyle(16)),
          Text(
            'Scroll to fix the count',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textDisabledDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    final size = _fit(value, heroStyle, width * 0.86, cap);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(value, maxLines: 1, style: heroStyle(size).copyWith(height: 1)),
        if (label) Text(unit, style: unitStyle(16)),
      ],
    );
  }

  Widget _timeline() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: WorkoutTimeline(
      shape: WorkoutShape.ofTimerType(session.workout.timerType),
      height: 14,
      elapsedSeconds: elapsedSeconds,
    ),
  );

  Widget _finishedLine() => Text(
    'Finished ${f.finished}  ·  ${f.day}',
    style: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondaryDark,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        return switch (variant) {
          1 => _statRow(width),
          2 => _twoNumbers(width),
          3 => _card(width),
          4 => _receipt(width),
          _ => _chart(width),
        };
      },
    );
  }

  // 1. Stat row: the hero lifted under the header, three tiles under it.
  Widget _statRow(double width) {
    final stats = f.three(mode);
    return Column(
      children: [
        _header(),
        const SizedBox(height: 36),
        _hero(width, cap: 180),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              for (final (label, value) in stats)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(label, maxLines: 1, style: _label(11)),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(value, maxLines: 1, style: _num(28)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: Center(child: _timeline())),
        slab,
      ],
    );
  }

  // 2. Two numbers: the result, then the next most useful number in white.
  Widget _twoNumbers(double width) {
    final (value, label) = f.second(mode);
    final size = _fit('00:00', (s) => _num(s), width * 0.6, 92);
    return Column(
      children: [
        _header(),
        const SizedBox(height: 32),
        _hero(width, cap: 170),
        const SizedBox(height: 30),
        Text(value, maxLines: 1, style: _num(size)),
        const SizedBox(height: 8),
        Text(label, style: unitStyle(16)),
        const SizedBox(height: 22),
        _finishedLine(),
        Expanded(child: Center(child: _timeline())),
        slab,
      ],
    );
  }

  // 3. Result card: the workout as one log entry, ready to screenshot.
  Widget _card(double width) {
    final facts = f.four(mode);
    Widget cell((String, String) fact) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fact.$1.toUpperCase(), style: _label(11)),
            const SizedBox(height: 6),
            Text(fact.$2, maxLines: 1, style: _num(26)),
          ],
        ),
      ),
    );
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: modeColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(word, style: _wordStyle.copyWith(fontSize: 26)),
                    const Spacer(),
                    Text(f.day.toUpperCase(), style: _label(12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(configText, maxLines: 1, style: unitStyle(13)),
                const SizedBox(height: 22),
                Center(child: _hero(width - 72, cap: 150)),
                const SizedBox(height: 18),
                Container(height: 1, color: AppColors.track),
                Row(children: [cell(facts[0]), cell(facts[1])]),
                Container(height: 1, color: AppColors.track),
                Row(children: [cell(facts[2]), cell(facts[3])]),
              ],
            ),
          ),
        ),
        Expanded(child: Center(child: _timeline())),
        slab,
      ],
    );
  }

  // 4. Receipt: the hero, then the facts as label / value lines.
  Widget _receipt(double width) {
    final facts = f.four(mode);
    return Column(
      children: [
        _header(),
        const SizedBox(height: 32),
        _hero(width, cap: 170),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (final (i, (label, value)) in facts.indexed) ...[
                if (i == 0) Container(height: 1, color: AppColors.track),
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondaryDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(value, style: _num(24)),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.track),
              ],
            ],
          ),
        ),
        Expanded(child: Center(child: _timeline())),
        slab,
      ],
    );
  }

  // 5. Round chart: the timeline grows into the workout's shape, rounds
  // labelled; AMRAP shows each round's split (new tracking).
  Widget _chart(double width) {
    return Column(
      children: [
        _header(),
        const SizedBox(height: 32),
        _hero(width, cap: 160),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(
                mode: mode,
                session: session,
                color: modeColor,
                label: _label(11),
                value: _num(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _finishedLine(),
        const Spacer(),
        slab,
      ],
    );
  }
}

/// AMRAP splits for the mock (seconds per completed round, then the part
/// round). Real ones need the app to record when each round is tapped.
const List<int> mockAmrapSplits = [74, 77, 79, 80, 82, 83, 85];

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.mode,
    required this.session,
    required this.color,
    required this.label,
    required this.value,
  });

  final String mode;
  final TimerSession session;
  final Color color;
  final TextStyle label;
  final TextStyle value;

  void _text(Canvas canvas, String s, TextStyle style, Offset centre,
      {double maxWidth = 200}) {
    final p = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    p.paint(canvas, centre - Offset(p.width / 2, p.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const gap = 6.0;
    const labelH = 22.0;
    final chartH = size.height - labelH - 22;
    final base = 22 + chartH;

    if (mode == 'fortime') {
      // One bar: the time against the cap.
      final cap = session.workout.timerType.maybeWhen(
        forTime: (t) => t.timeCap.seconds,
        orElse: () => 1,
      );
      final done = session.elapsed.seconds / cap;
      final top = base - 64;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, size.width, 64),
        const Radius.circular(12),
      );
      canvas.drawRRect(bar, paint..color = AppColors.track);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width * done, 64),
          const Radius.circular(12),
        ),
        paint..color = color,
      );
      final x = size.width * done;
      _text(canvas, setupClock(session.elapsed.seconds),
          value.copyWith(fontSize: 22), Offset(x, top - 20));
      _text(canvas, 'START', label, Offset(22, base + 14));
      _text(canvas, 'CAP ${setupClock(cap)}', label,
          Offset(size.width - 44, base + 14));
      return;
    }

    late final List<(double, Color, String?, String?)> bars;
    if (mode == 'amrap') {
      final maxS = mockAmrapSplits.reduce(math.max).toDouble();
      final part = session.elapsed.seconds - mockAmrapSplits.reduce((a, b) => a + b);
      bars = [
        for (final (i, s) in mockAmrapSplits.indexed)
          (s / maxS, color, '${i + 1}', setupClock(s)),
        (part / maxS, AppColors.track, '${mockAmrapSplits.length + 1}', null),
      ];
    } else if (mode == 'emom') {
      bars = [
        for (var i = 1; i <= (session.totalRounds ?? 0); i++)
          (i <= session.currentRound ? 1.0 : 0.25,
              i <= session.currentRound ? color : AppColors.track, '$i', null),
      ];
    } else {
      final rounds = session.totalRounds ?? 0;
      bars = [
        for (var i = 1; i <= rounds; i++) ...[
          (1.0, AppColors.work, '$i', null),
          (0.5, AppColors.rest, null, null),
        ],
      ];
    }
    final w = (size.width - gap * (bars.length - 1)) / bars.length;
    for (final (i, (h, c, under, over)) in bars.indexed) {
      final x = i * (w + gap);
      final top = base - chartH * h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, w, base - top),
          const Radius.circular(6),
        ),
        paint..color = c,
      );
      if (under != null) {
        _text(canvas, under, label, Offset(x + w / 2, base + 14));
      }
      if (over != null) {
        _text(canvas, over, value.copyWith(fontSize: 12),
            Offset(x + w / 2, top - 11));
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => false;
}
