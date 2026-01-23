import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';

void main() {
  group('TimerDuration', () {
    group('create', () {
      test('should create valid duration', () {
        final result = TimerDuration.create(60);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (duration) {
            expect(duration.seconds, 60);
            expect(duration.minutes, 1);
            expect(duration.remainingSeconds, 0);
          },
        );
      });

      test('should create zero duration', () {
        final result = TimerDuration.create(0);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (duration) => expect(duration.seconds, 0),
        );
      });

      test('should reject negative duration', () {
        final result = TimerDuration.create(-1);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure,
            isA<ValueFailure<int>>(),
          ),
          (duration) => fail('Should fail'),
        );
      });

      test('should reject duration exceeding max', () {
        final result = TimerDuration.create(7201);

        expect(result.isLeft(), true);
      });

      test('should accept max duration', () {
        final result = TimerDuration.create(7200);

        expect(result.isRight(), true);
      });
    });

    group('fromMinutesAndSeconds', () {
      test('should create from minutes and seconds', () {
        final result = TimerDuration.fromMinutesAndSeconds(2, 30);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (duration) => expect(duration.seconds, 150),
        );
      });
    });

    group('formatted', () {
      test('should format single digit minutes and seconds', () {
        final duration = TimerDuration.fromSeconds(65);
        expect(duration.formatted, '01:05');
      });

      test('should format double digit minutes and seconds', () {
        final duration = TimerDuration.fromSeconds(754);
        expect(duration.formatted, '12:34');
      });

      test('should format zero', () {
        expect(TimerDuration.zero.formatted, '00:00');
      });
    });

    group('operators', () {
      test('should add durations', () {
        final a = TimerDuration.fromSeconds(30);
        final b = TimerDuration.fromSeconds(45);
        final result = a + b;

        expect(result.seconds, 75);
      });

      test('should subtract durations', () {
        final a = TimerDuration.fromSeconds(60);
        final b = TimerDuration.fromSeconds(25);
        final result = a - b;

        expect(result.seconds, 35);
      });

      test('should clamp subtraction to zero', () {
        final a = TimerDuration.fromSeconds(10);
        final b = TimerDuration.fromSeconds(20);
        final result = a - b;

        expect(result.seconds, 0);
      });

      test('should compare durations', () {
        final a = TimerDuration.fromSeconds(30);
        final b = TimerDuration.fromSeconds(60);

        expect(a < b, true);
        expect(b > a, true);
        expect(a <= b, true);
        expect(b >= a, true);
      });
    });

    group('equality', () {
      test('should be equal for same seconds', () {
        final a = TimerDuration.fromSeconds(60);
        final b = TimerDuration.fromSeconds(60);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should not be equal for different seconds', () {
        final a = TimerDuration.fromSeconds(60);
        final b = TimerDuration.fromSeconds(90);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
