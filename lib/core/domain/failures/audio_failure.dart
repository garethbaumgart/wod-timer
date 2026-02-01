import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_failure.freezed.dart';

/// Failures that can occur during audio operations.
@freezed
sealed class AudioFailure with _$AudioFailure {
  /// Failed to load the audio file.
  const factory AudioFailure.loadError({String? fileName}) = _LoadError;

  /// Failed to play the audio.
  const factory AudioFailure.playbackError({String? message}) = _PlaybackError;

  /// The audio file was not found.
  const factory AudioFailure.fileNotFound({required String fileName}) =
      _FileNotFound;

  /// The audio format is not supported.
  const factory AudioFailure.unsupportedFormat({String? format}) =
      _UnsupportedFormat;

  /// Audio permission was denied (e.g., microphone for recording).
  const factory AudioFailure.permissionDenied() = _PermissionDenied;

  /// The audio device is not available or busy.
  const factory AudioFailure.deviceUnavailable() = _DeviceUnavailable;

  /// An unexpected audio error occurred.
  const factory AudioFailure.unexpected({String? message}) = _Unexpected;
}

/// Extension to get user-friendly error messages from AudioFailure.
extension AudioFailureMessage on AudioFailure {
  String get message => when(
    loadError: (fileName) => fileName != null
        ? 'Failed to load audio: $fileName'
        : 'Failed to load audio',
    playbackError: (msg) => msg ?? 'Audio playback failed',
    fileNotFound: (fileName) => 'Audio file not found: $fileName',
    unsupportedFormat: (format) => format != null
        ? 'Unsupported audio format: $format'
        : 'Unsupported audio format',
    permissionDenied: () => 'Audio permission denied',
    deviceUnavailable: () => 'Audio device is unavailable',
    unexpected: (msg) => msg ?? 'An unexpected audio error occurred',
  );
}
