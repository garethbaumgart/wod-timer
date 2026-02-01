import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_failure.freezed.dart';

/// Failures that can occur during local storage operations.
@freezed
sealed class StorageFailure with _$StorageFailure {
  /// Failed to read data from storage.
  const factory StorageFailure.readError({String? message}) = _ReadError;

  /// Failed to write data to storage.
  const factory StorageFailure.writeError({String? message}) = _WriteError;

  /// Failed to delete data from storage.
  const factory StorageFailure.deleteError({String? message}) = _DeleteError;

  /// The requested data was not found in storage.
  const factory StorageFailure.notFound({String? key}) = _NotFound;

  /// The stored data is corrupted or has an invalid format.
  const factory StorageFailure.corrupted({String? message}) = _Corrupted;

  /// Storage permission was denied.
  const factory StorageFailure.permissionDenied() = _PermissionDenied;

  /// Storage is full or quota exceeded.
  const factory StorageFailure.storageFull() = _StorageFull;

  /// An unexpected storage error occurred.
  const factory StorageFailure.unexpected({String? message}) = _Unexpected;
}

/// Extension to get user-friendly error messages from StorageFailure.
extension StorageFailureMessage on StorageFailure {
  String get message => when(
    readError: (msg) => msg ?? 'Failed to read data',
    writeError: (msg) => msg ?? 'Failed to save data',
    deleteError: (msg) => msg ?? 'Failed to delete data',
    notFound: (key) => key != null ? 'Data not found: $key' : 'Data not found',
    corrupted: (msg) => msg ?? 'Data is corrupted',
    permissionDenied: () => 'Storage permission denied',
    storageFull: () => 'Storage is full',
    unexpected: (msg) => msg ?? 'An unexpected storage error occurred',
  );
}
