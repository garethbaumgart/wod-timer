import 'package:json_annotation/json_annotation.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

part 'timer_type_dto.g.dart';

/// DTO for serializing [TimerType] to/from JSON.
///
/// Uses a discriminator field `type` to determine the concrete type.
@JsonSerializable()
class TimerTypeDto {
  TimerTypeDto({
    required this.type,
    this.durationSeconds,
    this.timeCapSeconds,
    this.countUp,
    this.intervalDurationSeconds,
    this.rounds,
    this.workDurationSeconds,
    this.restDurationSeconds,
  });

  factory TimerTypeDto.fromJson(Map<String, dynamic> json) =>
      _$TimerTypeDtoFromJson(json);

  /// Create DTO from domain entity.
  factory TimerTypeDto.fromDomain(TimerType timerType) {
    return timerType.when(
      amrap: (t) => TimerTypeDto(
        type: 'amrap',
        durationSeconds: t.duration.seconds,
      ),
      forTime: (t) => TimerTypeDto(
        type: 'fortime',
        timeCapSeconds: t.timeCap.seconds,
        countUp: t.countUp,
      ),
      emom: (t) => TimerTypeDto(
        type: 'emom',
        intervalDurationSeconds: t.intervalDuration.seconds,
        rounds: t.rounds.value,
      ),
      tabata: (t) => TimerTypeDto(
        type: 'tabata',
        workDurationSeconds: t.workDuration.seconds,
        restDurationSeconds: t.restDuration.seconds,
        rounds: t.rounds.value,
      ),
    );
  }

  /// The timer type discriminator.
  final String type;

  /// Duration in seconds (for AMRAP).
  final int? durationSeconds;

  /// Time cap in seconds (for For Time).
  final int? timeCapSeconds;

  /// Whether to count up (for For Time).
  final bool? countUp;

  /// Interval duration in seconds (for EMOM).
  final int? intervalDurationSeconds;

  /// Number of rounds (for EMOM and Tabata).
  final int? rounds;

  /// Work duration in seconds (for Tabata).
  final int? workDurationSeconds;

  /// Rest duration in seconds (for Tabata).
  final int? restDurationSeconds;

  Map<String, dynamic> toJson() => _$TimerTypeDtoToJson(this);

  /// Convert to domain entity.
  TimerType toDomain() {
    return switch (type) {
      'amrap' => AmrapTimer(
          duration: TimerDuration.fromSeconds(durationSeconds ?? 600),
        ),
      'fortime' => ForTimeTimer(
          timeCap: TimerDuration.fromSeconds(timeCapSeconds ?? 1200),
          countUp: countUp ?? true,
        ),
      'emom' => EmomTimer(
          intervalDuration:
              TimerDuration.fromSeconds(intervalDurationSeconds ?? 60),
          rounds: RoundCount.fromInt(rounds ?? 10),
        ),
      'tabata' => TabataTimer(
          workDuration: TimerDuration.fromSeconds(workDurationSeconds ?? 20),
          restDuration: TimerDuration.fromSeconds(restDurationSeconds ?? 10),
          rounds: RoundCount.fromInt(rounds ?? 8),
        ),
      _ => AmrapTimer(
          duration: TimerDuration.fromSeconds(durationSeconds ?? 600),
        ),
    };
  }
}
