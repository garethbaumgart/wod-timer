import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';

/// Implementation of [IHapticService] using Flutter's HapticFeedback.
@LazySingleton(as: IHapticService)
class HapticService implements IHapticService {
  bool _isEnabled = true;

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> setEnabled({required bool enabled}) async {
    _isEnabled = enabled;
  }

  @override
  Future<Either<HapticFailure, Unit>> lightImpact() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      await HapticFeedback.lightImpact();
      return right(unit);
    } catch (e) {
      return right(unit); // Fail silently - haptic is non-critical
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> mediumImpact() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      await HapticFeedback.mediumImpact();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> heavyImpact() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      await HapticFeedback.heavyImpact();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> selectionClick() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      await HapticFeedback.selectionClick();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> success() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      // Success pattern: light-medium-heavy
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> warning() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      // Warning pattern: two medium impacts
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  @override
  Future<Either<HapticFailure, Unit>> error() async {
    if (!_isEnabled) return left(const HapticFailure.disabled());

    try {
      // Error pattern: three quick heavy impacts
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }
}
