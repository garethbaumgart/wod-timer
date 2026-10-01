import 'package:flutter/foundation.dart';

/// The bounds and step for one setup value, in the unit it is stored in
/// (seconds for durations, a plain count for rounds).
@immutable
class SetupRange {
  const SetupRange({
    required this.min,
    required this.max,
    required this.step,
    required this.fallback,
  });

  final int min;
  final int max;
  final int step;

  /// Used when nothing is stored yet, or what is stored is unusable.
  final int fallback;

  int increment(int value) => normalize(value + step);

  int decrement(int value) => normalize(value - step);

  bool canIncrement(int value) => value + step <= max;

  bool canDecrement(int value) => value - step >= min;

  /// Clamps into range and snaps onto the step grid, so a value written by
  /// an older or newer build (different steps) still lands on a legal value.
  int normalize(int value) {
    final clamped = value.clamp(min, max);
    final snapped = min + ((clamped - min) / step).round() * step;
    return snapped.clamp(min, max);
  }
}

/// Allowed ranges for every setup value. AMRAP and For Time move in whole
/// minutes (nobody programs a 12:35 AMRAP); EMOM intervals in 15s (90s and
/// 45s EMOMs are common); Tabata phases in 5s.
abstract class SetupRanges {
  static const amrapDuration = SetupRange(
    min: 60,
    max: 3600,
    step: 60,
    fallback: 600,
  );
  static const forTimeCap = SetupRange(
    min: 60,
    max: 3600,
    step: 60,
    fallback: 1200,
  );
  static const emomInterval = SetupRange(
    min: 15,
    max: 600,
    step: 15,
    fallback: 60,
  );
  static const emomRounds = SetupRange(min: 1, max: 30, step: 1, fallback: 10);
  static const tabataWork = SetupRange(min: 5, max: 120, step: 5, fallback: 20);
  static const tabataRest = SetupRange(min: 5, max: 120, step: 5, fallback: 10);
  static const tabataRounds = SetupRange(min: 1, max: 20, step: 1, fallback: 8);
}

@immutable
class AmrapSetup {
  const AmrapSetup({this.durationSeconds = 600});

  final int durationSeconds;

  AmrapSetup copyWith({int? durationSeconds}) =>
      AmrapSetup(durationSeconds: durationSeconds ?? this.durationSeconds);

  @override
  bool operator ==(Object other) =>
      other is AmrapSetup && other.durationSeconds == durationSeconds;

  @override
  int get hashCode => durationSeconds.hashCode;
}

@immutable
class ForTimeSetup {
  const ForTimeSetup({this.capSeconds = 1200, this.countUp = true});

  final int capSeconds;
  final bool countUp;

  ForTimeSetup copyWith({int? capSeconds, bool? countUp}) => ForTimeSetup(
    capSeconds: capSeconds ?? this.capSeconds,
    countUp: countUp ?? this.countUp,
  );

  @override
  bool operator ==(Object other) =>
      other is ForTimeSetup &&
      other.capSeconds == capSeconds &&
      other.countUp == countUp;

  @override
  int get hashCode => Object.hash(capSeconds, countUp);
}

@immutable
class EmomSetup {
  const EmomSetup({this.intervalSeconds = 60, this.rounds = 10});

  final int intervalSeconds;
  final int rounds;

  int get totalSeconds => intervalSeconds * rounds;

  EmomSetup copyWith({int? intervalSeconds, int? rounds}) => EmomSetup(
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    rounds: rounds ?? this.rounds,
  );

  @override
  bool operator ==(Object other) =>
      other is EmomSetup &&
      other.intervalSeconds == intervalSeconds &&
      other.rounds == rounds;

  @override
  int get hashCode => Object.hash(intervalSeconds, rounds);
}

@immutable
class TabataSetup {
  const TabataSetup({
    this.workSeconds = 20,
    this.restSeconds = 10,
    this.rounds = 8,
  });

  /// The 20s work / 10s rest x 8 protocol.
  static const classic = TabataSetup();

  final int workSeconds;
  final int restSeconds;
  final int rounds;

  int get totalSeconds => (workSeconds + restSeconds) * rounds;

  bool get isClassic => this == classic;

  TabataSetup copyWith({int? workSeconds, int? restSeconds, int? rounds}) =>
      TabataSetup(
        workSeconds: workSeconds ?? this.workSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        rounds: rounds ?? this.rounds,
      );

  @override
  bool operator ==(Object other) =>
      other is TabataSetup &&
      other.workSeconds == workSeconds &&
      other.restSeconds == restSeconds &&
      other.rounds == rounds;

  @override
  int get hashCode => Object.hash(workSeconds, restSeconds, rounds);
}
