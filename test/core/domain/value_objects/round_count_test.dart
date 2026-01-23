import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';

void main() {
  group('RoundCount', () {
    group('create', () {
      test('should create valid round count', () {
        final result = RoundCount.create(5);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (roundCount) => expect(roundCount.value, 5),
        );
      });

      test('should create minimum round count', () {
        final result = RoundCount.create(1);

        expect(result.isRight(), true);
      });

      test('should create maximum round count', () {
        final result = RoundCount.create(100);

        expect(result.isRight(), true);
      });

      test('should reject zero rounds', () {
        final result = RoundCount.create(0);

        expect(result.isLeft(), true);
      });

      test('should reject negative rounds', () {
        final result = RoundCount.create(-1);

        expect(result.isLeft(), true);
      });

      test('should reject rounds exceeding max', () {
        final result = RoundCount.create(101);

        expect(result.isLeft(), true);
      });
    });

    group('increment/decrement', () {
      test('should increment round count', () {
        final count = RoundCount.fromInt(5);
        final incremented = count.increment();

        expect(incremented.value, 6);
      });

      test('should not increment beyond max', () {
        final count = RoundCount.fromInt(100);
        final incremented = count.increment();

        expect(incremented.value, 100);
      });

      test('should decrement round count', () {
        final count = RoundCount.fromInt(5);
        final decremented = count.decrement();

        expect(decremented.value, 4);
      });

      test('should not decrement below min', () {
        final count = RoundCount.fromInt(1);
        final decremented = count.decrement();

        expect(decremented.value, 1);
      });
    });

    group('constants', () {
      test('should have correct tabata default', () {
        expect(RoundCount.tabataDefault.value, 8);
      });

      test('should have correct one constant', () {
        expect(RoundCount.one.value, 1);
      });
    });

    group('equality', () {
      test('should be equal for same value', () {
        final a = RoundCount.fromInt(5);
        final b = RoundCount.fromInt(5);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should not be equal for different values', () {
        final a = RoundCount.fromInt(5);
        final b = RoundCount.fromInt(10);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
