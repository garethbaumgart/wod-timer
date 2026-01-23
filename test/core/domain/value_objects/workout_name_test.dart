import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';

void main() {
  group('WorkoutName', () {
    group('create', () {
      test('should create valid workout name', () {
        final result = WorkoutName.create('My Workout');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (name) => expect(name.value, 'My Workout'),
        );
      });

      test('should trim whitespace', () {
        final result = WorkoutName.create('  My Workout  ');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (name) => expect(name.value, 'My Workout'),
        );
      });

      test('should reject empty string', () {
        final result = WorkoutName.create('');

        expect(result.isLeft(), true);
      });

      test('should reject whitespace-only string', () {
        final result = WorkoutName.create('   ');

        expect(result.isLeft(), true);
      });

      test('should reject name exceeding max length', () {
        final longName = 'A' * 51;
        final result = WorkoutName.create(longName);

        expect(result.isLeft(), true);
      });

      test('should accept name at max length', () {
        final maxName = 'A' * 50;
        final result = WorkoutName.create(maxName);

        expect(result.isRight(), true);
      });
    });

    group('defaults', () {
      test('should have correct default names', () {
        expect(WorkoutName.defaultAmrap.value, 'AMRAP Workout');
        expect(WorkoutName.defaultForTime.value, 'For Time');
        expect(WorkoutName.defaultEmom.value, 'EMOM');
        expect(WorkoutName.defaultTabata.value, 'Tabata');
      });
    });

    group('equality', () {
      test('should be equal for same value', () {
        final a = WorkoutName.fromString('Test');
        final b = WorkoutName.fromString('Test');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should not be equal for different values', () {
        final a = WorkoutName.fromString('Test A');
        final b = WorkoutName.fromString('Test B');

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('should return the value', () {
        final name = WorkoutName.fromString('My Workout');

        expect(name.toString(), 'My Workout');
      });
    });
  });
}
