import 'package:json_annotation/json_annotation.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/timer_type_dto.dart';

part 'workout_dto.g.dart';

/// DTO for serializing [Workout] to/from JSON.
@JsonSerializable(explicitToJson: true)
class WorkoutDto {
  WorkoutDto({
    required this.id,
    required this.name,
    required this.timerType,
    required this.prepCountdownSeconds,
    required this.createdAt,
  });

  factory WorkoutDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDtoFromJson(json);

  /// Create DTO from domain entity.
  factory WorkoutDto.fromDomain(Workout workout) => WorkoutDto(
    id: workout.id.value,
    name: workout.name.value,
    timerType: TimerTypeDto.fromDomain(workout.timerType),
    prepCountdownSeconds: workout.prepCountdown.seconds,
    createdAt: workout.createdAt.toIso8601String(),
  );

  /// Unique identifier.
  final String id;

  /// Workout name.
  final String name;

  /// Timer configuration.
  final TimerTypeDto timerType;

  /// Prep countdown in seconds.
  final int prepCountdownSeconds;

  /// Creation timestamp as ISO8601 string.
  final String createdAt;

  Map<String, dynamic> toJson() => _$WorkoutDtoToJson(this);

  /// Convert to domain entity.
  Workout toDomain() => Workout(
    id: UniqueId.fromString(id),
    name: WorkoutName.fromString(name),
    timerType: timerType.toDomain(),
    prepCountdown: TimerDuration.fromSeconds(prepCountdownSeconds),
    createdAt: DateTime.parse(createdAt),
  );
}
