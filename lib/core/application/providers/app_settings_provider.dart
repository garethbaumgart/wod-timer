import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/injection.dart';

part 'app_settings_provider.g.dart';

/// Orientation lock mode options.
enum OrientationLockMode {
  /// Follow device orientation (no lock).
  auto,

  /// Lock to portrait mode.
  portrait,

  /// Lock to landscape mode.
  landscape,
}

/// App-wide settings and preferences.
class AppSettings {
  const AppSettings({
    this.orientationLock = OrientationLockMode.auto,
    this.hapticEnabled = true,
    this.soundEnabled = true,
    this.keepScreenOn = true,
  });

  /// Orientation lock preference.
  final OrientationLockMode orientationLock;

  /// Whether haptic feedback is enabled.
  final bool hapticEnabled;

  /// Whether sound is enabled.
  final bool soundEnabled;

  /// Whether to keep screen on during workouts.
  final bool keepScreenOn;

  AppSettings copyWith({
    OrientationLockMode? orientationLock,
    bool? hapticEnabled,
    bool? soundEnabled,
    bool? keepScreenOn,
  }) {
    return AppSettings(
      orientationLock: orientationLock ?? this.orientationLock,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }
}

/// Provider for managing app settings.
@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const _keyOrientationLock = 'app_orientation_lock';
  static const _keyHapticEnabled = 'app_haptic_enabled';
  static const _keySoundEnabled = 'app_sound_enabled';
  static const _keyKeepScreenOn = 'app_keep_screen_on';

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final orientationIndex = prefs.getInt(_keyOrientationLock) ?? 0;
      final safeOrientationIndex =
          orientationIndex.clamp(0, OrientationLockMode.values.length - 1);
      final hapticEnabled = prefs.getBool(_keyHapticEnabled) ?? true;
      final soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      final keepScreenOn = prefs.getBool(_keyKeepScreenOn) ?? true;

      state = AppSettings(
        orientationLock: OrientationLockMode.values[safeOrientationIndex],
        hapticEnabled: hapticEnabled,
        soundEnabled: soundEnabled,
        keepScreenOn: keepScreenOn,
      );

      // Apply orientation lock
      _applyOrientationLock(state.orientationLock);

      // Sync haptic setting with service
      _syncHapticService(hapticEnabled);
    } catch (e) {
      // Use defaults on error
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyOrientationLock, state.orientationLock.index);
      await prefs.setBool(_keyHapticEnabled, state.hapticEnabled);
      await prefs.setBool(_keySoundEnabled, state.soundEnabled);
      await prefs.setBool(_keyKeepScreenOn, state.keepScreenOn);
    } catch (e) {
      // Ignore save errors
    }
  }

  void _applyOrientationLock(OrientationLockMode mode) {
    switch (mode) {
      case OrientationLockMode.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      case OrientationLockMode.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      case OrientationLockMode.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
    }
  }

  /// Set orientation lock mode.
  Future<void> setOrientationLock(OrientationLockMode mode) async {
    state = state.copyWith(orientationLock: mode);
    _applyOrientationLock(mode);
    await _saveSettings();
  }

  void _syncHapticService(bool enabled) {
    try {
      getIt<IHapticService>().setEnabled(enabled: enabled);
    } catch (_) {
      // Ignore if service not available (e.g., in tests)
    }
  }

  /// Toggle haptic feedback.
  Future<void> setHapticEnabled({required bool enabled}) async {
    state = state.copyWith(hapticEnabled: enabled);
    _syncHapticService(enabled);
    await _saveSettings();
  }

  /// Toggle sound.
  Future<void> setSoundEnabled({required bool enabled}) async {
    state = state.copyWith(soundEnabled: enabled);
    await _saveSettings();
  }

  /// Toggle keep screen on.
  Future<void> setKeepScreenOn({required bool enabled}) async {
    state = state.copyWith(keepScreenOn: enabled);
    await _saveSettings();
  }
}
