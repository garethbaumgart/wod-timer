import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/features/timer/application/blocs/presets_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

void main() {
  group('PresetsState', () {
    group('factory constructors', () {
      test('should create initial state', () {
        const state = PresetsState.initial();
        expect(state, isA<PresetsInitial>());
      });

      test('should create loading state', () {
        const state = PresetsState.loading();
        expect(state, isA<PresetsLoading>());
      });

      test('should create loaded state with presets', () {
        final presets = [
          Workout.defaultAmrap(),
          Workout.defaultForTime(),
        ];
        final state = PresetsState.loaded(presets: presets);
        expect(state, isA<PresetsLoaded>());
        expect((state as PresetsLoaded).presets.length, 2);
      });

      test('should create loaded state with empty presets', () {
        const state = PresetsState.loaded(presets: []);
        expect(state, isA<PresetsLoaded>());
        expect((state as PresetsLoaded).presets.isEmpty, isTrue);
      });

      test('should create error state with failure', () {
        const failure = StorageFailure.readError(message: 'Test error');
        const state = PresetsState.error(failure: failure);
        expect(state, isA<PresetsError>());
        expect((state as PresetsError).failure, failure);
      });

      test('should create error state with failure and presets', () {
        const failure = StorageFailure.readError(message: 'Test error');
        final presets = [Workout.defaultAmrap()];
        final state = PresetsState.error(failure: failure, presets: presets);
        expect(state, isA<PresetsError>());
        expect((state as PresetsError).failure, failure);
        expect((state).presets.length, 1);
      });
    });
  });

  group('PresetsStateX extension', () {
    group('presetsOrEmpty', () {
      test('should return empty list for initial state', () {
        const state = PresetsState.initial();
        expect(state.presetsOrEmpty, isEmpty);
      });

      test('should return empty list for loading state', () {
        const state = PresetsState.loading();
        expect(state.presetsOrEmpty, isEmpty);
      });

      test('should return presets for loaded state', () {
        final presets = [
          Workout.defaultAmrap(),
          Workout.defaultForTime(),
        ];
        final state = PresetsState.loaded(presets: presets);
        expect(state.presetsOrEmpty.length, 2);
      });

      test('should return presets for error state with presets', () {
        const failure = StorageFailure.readError(message: 'Test');
        final presets = [Workout.defaultAmrap()];
        final state = PresetsState.error(failure: failure, presets: presets);
        expect(state.presetsOrEmpty.length, 1);
      });

      test('should return empty list for error state without presets', () {
        const failure = StorageFailure.readError(message: 'Test');
        const state = PresetsState.error(failure: failure);
        expect(state.presetsOrEmpty, isEmpty);
      });
    });

    group('isLoading', () {
      test('should be false for initial state', () {
        const state = PresetsState.initial();
        expect(state.isLoading, isFalse);
      });

      test('should be true for loading state', () {
        const state = PresetsState.loading();
        expect(state.isLoading, isTrue);
      });

      test('should be false for loaded state', () {
        const state = PresetsState.loaded(presets: []);
        expect(state.isLoading, isFalse);
      });

      test('should be false for error state', () {
        const failure = StorageFailure.readError(message: 'Test');
        const state = PresetsState.error(failure: failure);
        expect(state.isLoading, isFalse);
      });
    });

    group('isLoaded', () {
      test('should be false for initial state', () {
        const state = PresetsState.initial();
        expect(state.isLoaded, isFalse);
      });

      test('should be false for loading state', () {
        const state = PresetsState.loading();
        expect(state.isLoaded, isFalse);
      });

      test('should be true for loaded state', () {
        const state = PresetsState.loaded(presets: []);
        expect(state.isLoaded, isTrue);
      });

      test('should be false for error state', () {
        const failure = StorageFailure.readError(message: 'Test');
        const state = PresetsState.error(failure: failure);
        expect(state.isLoaded, isFalse);
      });
    });
  });
}
