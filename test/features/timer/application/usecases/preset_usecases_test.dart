import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/application/usecases/delete_preset.dart';
import 'package:wod_timer/features/timer/application/usecases/get_presets.dart';
import 'package:wod_timer/features/timer/application/usecases/save_preset.dart';
import 'package:wod_timer/features/timer/application/usecases/watch_presets.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';

class MockWorkoutRepository extends Mock implements IWorkoutRepository {}

class FakeUniqueId extends Fake implements UniqueId {}

class FakeWorkout extends Fake implements Workout {}

void main() {
  late MockWorkoutRepository mockRepository;
  late GetPresets getPresets;
  late SavePreset savePreset;
  late DeletePreset deletePreset;
  late WatchPresets watchPresets;

  setUpAll(() {
    registerFallbackValue(FakeUniqueId());
    registerFallbackValue(FakeWorkout());
  });

  setUp(() {
    mockRepository = MockWorkoutRepository();
    getPresets = GetPresets(mockRepository);
    savePreset = SavePreset(mockRepository);
    deletePreset = DeletePreset(mockRepository);
    watchPresets = WatchPresets(mockRepository);
  });

  group('GetPresets', () {
    test('should return list of presets on success', () async {
      final presets = [
        Workout.defaultAmrap(),
        Workout.defaultForTime(),
      ];
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => right(presets));

      final result = await getPresets();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (list) {
          expect(list.length, 2);
        },
      );
      verify(() => mockRepository.getAll()).called(1);
    });

    test('should return empty list when no presets exist', () async {
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => right(<Workout>[]));

      final result = await getPresets();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (list) => expect(list.isEmpty, isTrue),
      );
    });

    test('should return failure on error', () async {
      when(() => mockRepository.getAll()).thenAnswer(
        (_) async => left(const StorageFailure.readError(message: 'Read failed')),
      );

      final result = await getPresets();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should be left'),
      );
    });
  });

  group('SavePreset', () {
    test('should save preset successfully', () async {
      final workout = Workout.defaultAmrap();
      when(() => mockRepository.save(any())).thenAnswer((_) async => right(unit));

      final result = await savePreset(workout);

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.save(workout)).called(1);
    });

    test('should return failure when save fails', () async {
      final workout = Workout.defaultAmrap();
      when(() => mockRepository.save(any())).thenAnswer(
        (_) async => left(const StorageFailure.writeError(message: 'Write failed')),
      );

      final result = await savePreset(workout);

      expect(result.isLeft(), isTrue);
    });
  });

  group('DeletePreset', () {
    test('should delete preset successfully', () async {
      final id = UniqueId();
      when(() => mockRepository.delete(any())).thenAnswer((_) async => right(unit));

      final result = await deletePreset(id);

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.delete(id)).called(1);
    });

    test('should return failure when delete fails', () async {
      final id = UniqueId();
      when(() => mockRepository.delete(any())).thenAnswer(
        (_) async => left(const StorageFailure.deleteError(message: 'Delete failed')),
      );

      final result = await deletePreset(id);

      expect(result.isLeft(), isTrue);
    });
  });

  group('WatchPresets', () {
    test('should return stream of presets', () async {
      final presets1 = [Workout.defaultAmrap()];
      final presets2 = [
        Workout.defaultAmrap(),
        Workout.defaultForTime(),
      ];

      when(() => mockRepository.watchAll()).thenAnswer(
        (_) => Stream.fromIterable([
          right<StorageFailure, List<Workout>>(presets1),
          right<StorageFailure, List<Workout>>(presets2),
        ]),
      );

      final stream = watchPresets();
      final results = await stream.toList();

      expect(results.length, 2);
      expect(results[0].getRight().toNullable()!.length, 1);
      expect(results[1].getRight().toNullable()!.length, 2);
    });

    test('should emit failure on error', () async {
      when(() => mockRepository.watchAll()).thenAnswer(
        (_) => Stream.value(
          left<StorageFailure, List<Workout>>(
            const StorageFailure.readError(message: 'Stream error'),
          ),
        ),
      );

      final stream = watchPresets();
      final results = await stream.toList();

      expect(results.length, 1);
      expect(results[0].isLeft(), isTrue);
    });
  });
}
