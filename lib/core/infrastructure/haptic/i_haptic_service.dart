import 'package:fpdart/fpdart.dart';

/// Interface for haptic feedback service.
///
/// Provides tactile feedback for timer events and user interactions.
abstract class IHapticService {
  /// Light impact for button taps and selection changes.
  Future<Either<HapticFailure, Unit>> lightImpact();

  /// Medium impact for important state changes.
  Future<Either<HapticFailure, Unit>> mediumImpact();

  /// Heavy impact for major events (workout complete, phase change).
  Future<Either<HapticFailure, Unit>> heavyImpact();

  /// Selection feedback for picker scrolling.
  Future<Either<HapticFailure, Unit>> selectionClick();

  /// Success pattern for workout completion.
  Future<Either<HapticFailure, Unit>> success();

  /// Warning pattern for countdown warnings.
  Future<Either<HapticFailure, Unit>> warning();

  /// Error pattern for failures.
  Future<Either<HapticFailure, Unit>> error();

  /// Whether haptic feedback is enabled.
  bool get isEnabled;

  /// Enable or disable haptic feedback.
  Future<void> setEnabled({required bool enabled});
}

/// Failures that can occur during haptic feedback.
sealed class HapticFailure {
  const HapticFailure();

  /// Haptic feedback is not supported on this device.
  const factory HapticFailure.notSupported() = HapticNotSupported;

  /// Haptic feedback is disabled by user.
  const factory HapticFailure.disabled() = HapticDisabled;

  /// Unexpected error during haptic feedback.
  const factory HapticFailure.unexpected({String? message}) = HapticUnexpected;
}

class HapticNotSupported extends HapticFailure {
  const HapticNotSupported();
}

class HapticDisabled extends HapticFailure {
  const HapticDisabled();
}

class HapticUnexpected extends HapticFailure {
  const HapticUnexpected({this.message});
  final String? message;
}
