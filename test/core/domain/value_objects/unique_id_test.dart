import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';

void main() {
  group('UniqueId', () {
    test('should generate unique IDs', () {
      final id1 = UniqueId();
      final id2 = UniqueId();

      expect(id1.value, isNot(equals(id2.value)));
    });

    test('should create from string', () {
      const testId = '123e4567-e89b-12d3-a456-426614174000';
      final id = UniqueId.fromString(testId);

      expect(id.value, testId);
    });

    test('should be equal for same value', () {
      const testId = '123e4567-e89b-12d3-a456-426614174000';
      final id1 = UniqueId.fromString(testId);
      final id2 = UniqueId.fromString(testId);

      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));
    });

    test('should not be equal for different values', () {
      final id1 = UniqueId();
      final id2 = UniqueId();

      expect(id1, isNot(equals(id2)));
    });

    test('toString should return the value', () {
      const testId = '123e4567-e89b-12d3-a456-426614174000';
      final id = UniqueId.fromString(testId);

      expect(id.toString(), testId);
    });
  });
}
