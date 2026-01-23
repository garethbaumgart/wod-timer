import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/application/blocs/presets_state.dart';
import 'package:wod_timer/features/timer/application/usecases/delete_preset.dart';
import 'package:wod_timer/features/timer/application/usecases/get_presets.dart';
import 'package:wod_timer/features/timer/application/usecases/save_preset.dart';
import 'package:wod_timer/features/timer/application/usecases/watch_presets.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

part 'presets_notifier.g.dart';

/// Notifier for managing workout presets.
///
/// Handles loading, adding, deleting, and reordering presets.
/// Call [initialize] before using any other methods.
@riverpod
class PresetsNotifier extends _$PresetsNotifier {
  late final GetPresets _getPresets;
  late final SavePreset _savePreset;
  late final DeletePreset _deletePreset;
  late final WatchPresets _watchPresets;

  bool _isInitialized = false;
  StreamSubscription<Either<StorageFailure, List<Workout>>>? _watchSubscription;

  @override
  PresetsState build() {
    ref.onDispose(_dispose);
    return const PresetsState.initial();
  }

  /// Initialize the notifier with dependencies.
  ///
  /// Must be called before using any other methods.
  void initialize({
    required GetPresets getPresets,
    required SavePreset savePreset,
    required DeletePreset deletePreset,
    required WatchPresets watchPresets,
  }) {
    _getPresets = getPresets;
    _savePreset = savePreset;
    _deletePreset = deletePreset;
    _watchPresets = watchPresets;
    _isInitialized = true;
  }

  void _assertInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PresetsNotifier.initialize() must be called before use',
      );
    }
  }

  /// Load all presets.
  Future<void> loadPresets() async {
    _assertInitialized();
    state = const PresetsState.loading();

    final result = await _getPresets();

    result.fold(
      (failure) => state = PresetsState.error(failure: failure),
      (presets) => state = PresetsState.loaded(presets: presets),
    );
  }

  /// Start watching for preset changes.
  void watchPresets() {
    _assertInitialized();
    _watchSubscription?.cancel();
    _watchSubscription = _watchPresets().listen(
      (result) {
        result.fold(
          (failure) => state = PresetsState.error(
            failure: failure,
            presets: state.presetsOrEmpty,
          ),
          (presets) => state = PresetsState.loaded(presets: presets),
        );
      },
    );
  }

  /// Add a new preset.
  Future<void> addPreset(Workout workout) async {
    _assertInitialized();
    final currentPresets = state.presetsOrEmpty;

    final result = await _savePreset(workout);

    result.fold(
      (failure) => state = PresetsState.error(
        failure: failure,
        presets: currentPresets,
      ),
      (_) {
        // Optimistically update the list
        // The actual update will come through the watch stream
        if (_watchSubscription == null) {
          state = PresetsState.loaded(
            presets: [workout, ...currentPresets],
          );
        }
      },
    );
  }

  /// Delete a preset by ID.
  Future<void> deletePreset(UniqueId id) async {
    _assertInitialized();
    final currentPresets = state.presetsOrEmpty;

    final result = await _deletePreset(id);

    result.fold(
      (failure) => state = PresetsState.error(
        failure: failure,
        presets: currentPresets,
      ),
      (_) {
        // Optimistically update the list
        // The actual update will come through the watch stream
        if (_watchSubscription == null) {
          state = PresetsState.loaded(
            presets: currentPresets.where((p) => p.id != id).toList(),
          );
        }
      },
    );
  }

  /// Reorder presets by moving an item from one index to another.
  ///
  /// Uses Flutter's ReorderableListView semantics where [newIndex] can be
  /// equal to [length] when moving to the end.
  Future<void> reorderPresets(int oldIndex, int newIndex) async {
    _assertInitialized();
    final currentPresets = List<Workout>.from(state.presetsOrEmpty);

    // Validate bounds - newIndex can equal length (move to end)
    if (oldIndex < 0 ||
        oldIndex >= currentPresets.length ||
        newIndex < 0 ||
        newIndex > currentPresets.length) {
      return;
    }

    // No-op if same position
    if (oldIndex == newIndex) return;

    // Adjust index for Flutter's ReorderableListView semantics
    var targetIndex = newIndex;
    if (oldIndex < newIndex) {
      targetIndex -= 1;
    }

    // Perform the reorder
    final item = currentPresets.removeAt(oldIndex);
    currentPresets.insert(targetIndex, item);

    // Update state optimistically
    state = PresetsState.loaded(presets: currentPresets);

    // Save all presets with updated order
    // In a real implementation, you might want to save order indices
    // For now, we just re-save to maintain the order
    for (final preset in currentPresets) {
      final result = await _savePreset(preset);
      if (result.isLeft()) {
        // Revert on error
        await loadPresets();
        return;
      }
    }
  }

  void _dispose() {
    _watchSubscription?.cancel();
  }
}
