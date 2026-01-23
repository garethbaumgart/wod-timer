import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

part 'presets_state.freezed.dart';

/// State for the presets notifier.
///
/// Represents all possible states when managing workout presets.
@freezed
class PresetsState with _$PresetsState {
  /// Initial loading state.
  const factory PresetsState.initial() = PresetsInitial;

  /// Loading state while fetching presets.
  const factory PresetsState.loading() = PresetsLoading;

  /// Loaded state with the list of presets.
  const factory PresetsState.loaded({
    required List<Workout> presets,
  }) = PresetsLoaded;

  /// Error state when something goes wrong.
  const factory PresetsState.error({
    required StorageFailure failure,
    @Default([]) List<Workout> presets,
  }) = PresetsError;
}

/// Extension methods for [PresetsState].
extension PresetsStateX on PresetsState {
  /// Returns the current list of presets if available.
  List<Workout> get presetsOrEmpty => maybeMap(
        loaded: (s) => s.presets,
        error: (s) => s.presets,
        orElse: () => [],
      );

  /// Whether the state is loading.
  bool get isLoading => maybeMap(
        loading: (_) => true,
        orElse: () => false,
      );

  /// Whether presets have been loaded.
  bool get isLoaded => maybeMap(
        loaded: (_) => true,
        orElse: () => false,
      );
}
