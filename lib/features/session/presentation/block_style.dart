import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// How a block kind looks: its name and its colours (2.6.0). The four
/// timers wear their mode colours as everywhere else.
extension BlockKindStyle on BlockKind {
  String get label => switch (this) {
    BlockKind.forTime => 'FOR TIME',
    BlockKind.emom => 'EMOM',
    BlockKind.amrap => 'AMRAP',
    BlockKind.tabata => 'TABATA',
    BlockKind.rest => 'REST',
    BlockKind.sets => 'SETS',
  };

  /// Bars and strip segments.
  Color get color => switch (this) {
    BlockKind.forTime => AppColors.forTimeAccent,
    BlockKind.emom => AppColors.emomAccent,
    BlockKind.amrap => AppColors.amrapAccent,
    BlockKind.tabata => AppColors.tabataAccent,
    BlockKind.rest => AppColors.restBlock,
    BlockKind.sets => AppColors.setsAccent,
  };

  /// The name as text: [color], lifted where that is too dim to read.
  Color get textColor =>
      this == BlockKind.rest ? AppColors.restBlockText : color;

  /// The clock's colour while the block counts: a Rest is full rest pink.
  Color get clockColor => this == BlockKind.rest ? AppColors.rest : color;
}

/// A block in the app's words.
extension BlockText on SessionBlock {
  /// Its setup, as a row shows it: "10 × 1:00", "5 · REST 2:00".
  String get detail => switch (this) {
    ForTimeBlock(:final capSeconds, :final countUp) =>
      'CAP ${setupClock(capSeconds)} · ${countUp ? 'UP' : 'DOWN'}',
    EmomBlock(:final intervalSeconds, :final rounds) =>
      '$rounds × ${setupClock(intervalSeconds)}',
    AmrapBlock(:final durationSeconds) => setupClock(durationSeconds),
    TabataBlock(:final workSeconds, :final restSeconds, :final rounds) =>
      '$rounds × ${setupPhase(workSeconds)} / ${setupPhase(restSeconds)}',
    RestBlock(:final seconds) => setupClock(seconds),
    SetsBlock(:final sets, :final restSeconds) =>
      '$sets · REST ${setupClock(restSeconds)}',
  };

  /// Named on its own, where the next block is announced: "EMOM 10 × 1:00",
  /// "REST 2:00", "SETS 5".
  String get title => switch (this) {
    ForTimeBlock(:final capSeconds) => 'FOR TIME ${setupClock(capSeconds)}',
    SetsBlock(:final sets) => 'SETS $sets',
    _ => '${kind.label} $detail',
  };

  /// How Home's repeat line names it ("EMOM 10"); null for a rest.
  String? get summary => switch (this) {
    ForTimeBlock(:final capSeconds) => 'For Time ${capSeconds ~/ 60}',
    EmomBlock(:final rounds) => 'EMOM $rounds',
    AmrapBlock(:final durationSeconds) => 'AMRAP ${durationSeconds ~/ 60}',
    TabataBlock(:final rounds) => 'Tabata $rounds',
    RestBlock() => null,
    SetsBlock(:final sets) => 'Sets $sets',
  };

  /// What a screen reader says for it.
  String get spoken => switch (this) {
    ForTimeBlock(:final capSeconds, :final countUp) =>
      'For Time, cap ${setupSpokenDuration(capSeconds)}, '
          'counts ${countUp ? 'up' : 'down'}',
    EmomBlock(:final intervalSeconds, :final rounds) =>
      'EMOM, $rounds ${rounds == 1 ? 'round' : 'rounds'} of '
          '${setupSpokenDuration(intervalSeconds)}',
    AmrapBlock(:final durationSeconds) =>
      'AMRAP, ${setupSpokenDuration(durationSeconds)}',
    TabataBlock(:final workSeconds, :final restSeconds, :final rounds) =>
      'Tabata, $rounds ${rounds == 1 ? 'round' : 'rounds'}, '
          '${setupSpokenDuration(workSeconds)} work, '
          '${setupSpokenDuration(restSeconds)} rest',
    RestBlock(:final seconds) => 'Rest, ${setupSpokenDuration(seconds)}',
    SetsBlock(:final sets, :final restSeconds) =>
      'Sets, $sets ${sets == 1 ? 'set' : 'sets'}, '
          '${setupSpokenDuration(restSeconds)} rest between',
  };

  /// The block as a timeline: the timers as on Home, a rest as one bar, a
  /// Sets block as a minute per set with its rests between.
  WorkoutShape get shape => switch (this) {
    ForTimeBlock(:final capSeconds) => WorkoutShape.forTime(capSeconds),
    EmomBlock(:final intervalSeconds, :final rounds) => WorkoutShape.emom(
      intervalSeconds: intervalSeconds,
      rounds: rounds,
    ),
    AmrapBlock(:final durationSeconds) => WorkoutShape.amrap(durationSeconds),
    TabataBlock(:final workSeconds, :final restSeconds, :final rounds) =>
      WorkoutShape.tabata(
        workSeconds: workSeconds,
        restSeconds: restSeconds,
        rounds: rounds,
      ),
    RestBlock(:final seconds) => WorkoutShape(
      parts: [TimelinePart(seconds, rest: true)],
      accent: AppColors.rest,
    ),
    SetsBlock(:final sets, :final restSeconds) => WorkoutShape(
      parts: [
        for (var i = 0; i < sets; i++) ...[
          if (i > 0) TimelinePart(restSeconds, rest: true),
          const TimelinePart(SetsBlock.setSeconds),
        ],
      ],
      accent: AppColors.setsAccent,
    ),
  };
}
