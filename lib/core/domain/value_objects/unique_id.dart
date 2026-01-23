import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// A unique identifier value object.
///
/// Wraps a UUID string and provides type safety for entity identity.
@immutable
class UniqueId {
  /// Create a new unique identifier with a generated UUID.
  factory UniqueId() => UniqueId._(const Uuid().v4());

  /// Create a unique identifier from an existing string.
  ///
  /// Use this when loading from persistence.
  factory UniqueId.fromString(String id) => UniqueId._(id);

  const UniqueId._(this.value);

  /// The underlying UUID string value.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
