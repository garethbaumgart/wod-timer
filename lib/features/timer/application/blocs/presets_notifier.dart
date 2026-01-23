import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
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
@riverpod
class PresetsNotifier extends _$PresetsNotifier {
  late final GetPresets _getPresets;
  late final SavePreset _savePreset;
  late final DeletePreset _deletePreset;
  late final WatchPresets _watchPresets;

  StreamSubscription<dynamic>? _watchSubscription;

  @override
  PresetsState build() {
    ref.onDispose(_dispose);
    return const PresetsState.initial();
  }

  /// Initialize the notifier with dependencies.
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
  }

  /// Load all presets.
  Future<void> loadPresets() async {
    state = const PresetsState.loading();

    final result = await _getPresets();

    result.fold(
      (failure) => state = PresetsState.error(failure: failure),
      (presets) => state = PresetsState.loaded(presets: presets),
    );
  }

  /// Start watching for preset changes.
  void watchPresets() {
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
  Future<void> reorderPresets(int oldIndex, int newIndex) async {
    final currentPresets = List<Workout>.from(state.presetsOrEmpty);

    if (oldIndex < 0 ||
        oldIndex >= currentPresets.length ||
        newIndex < 0 ||
        newIndex >= currentPresets.length) {
      return;
    }

    // Perform the reorder
    final item = currentPresets.removeAt(oldIndex);
    currentPresets.insert(newIndex, item);

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
