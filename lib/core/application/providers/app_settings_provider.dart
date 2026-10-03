import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/injection.dart';

part 'app_settings_provider.g.dart';

/// Voice option for audio cues.
enum VoiceOption {
  /// Major - CrossFit coach voice.
  major,

  /// Liam - male coach voice (shown as "Male Coach" since 1.3.1).
  liam,

  /// Holly - female voice.
  holly,

  /// Random - randomly pick a different voice for each cue.
  random,

  /// Off - no spoken cues; timing-critical moments fall back to beeps.
  /// Shown as "Beeps only".
  off,

  /// Silent - no voice and no beeps. Replaces the old Sound Effects switch
  /// (1.3.0). New values go LAST: settings persist the enum index.
  silent,
}

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
    this.voice = VoiceOption.major,
  });

  /// Orientation lock preference.
  final OrientationLockMode orientationLock;

  /// Whether haptic feedback is enabled.
  final bool hapticEnabled;

  /// Legacy Sound Effects switch (removed from the UI in 1.3.0; muting is
  /// now the [VoiceOption.silent] voice). Still read once for the 1.3.0
  /// migration and written back unchanged, never deleted.
  final bool soundEnabled;

  /// Legacy Keep Screen On switch (removed from the UI in 1.3.0: the timer
  /// screen always holds the wakelock). Persisted unchanged, never deleted.
  final bool keepScreenOn;

  /// Selected voice for audio cues.
  final VoiceOption voice;

  AppSettings copyWith({
    OrientationLockMode? orientationLock,
    bool? hapticEnabled,
    bool? soundEnabled,
    bool? keepScreenOn,
    VoiceOption? voice,
  }) {
    return AppSettings(
      orientationLock: orientationLock ?? this.orientationLock,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      voice: voice ?? this.voice,
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
  static const _keyVoice = 'app_voice';

  /// Set once the 1.3.0 Sound Effects -> Silent migration has run (additive).
  static const keySilentMigrated = 'app_sound_silent_migrated_v130';

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final orientationIndex = prefs.getInt(_keyOrientationLock) ?? 0;
      final safeOrientationIndex = orientationIndex.clamp(
        0,
        OrientationLockMode.values.length - 1,
      );
      final hapticEnabled = prefs.getBool(_keyHapticEnabled) ?? true;
      final soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      final keepScreenOn = prefs.getBool(_keyKeepScreenOn) ?? true;
      final voiceIndex = prefs.getInt(_keyVoice) ?? 0;
      final safeVoiceIndex = voiceIndex.clamp(0, VoiceOption.values.length - 1);
      var voice = VoiceOption.values[safeVoiceIndex];

      // 1.3.0: the Sound Effects switch is gone and silence is a voice.
      // Anyone who had it off stays silent, once; the old key is kept as
      // found and never read for muting again.
      if (!(prefs.getBool(keySilentMigrated) ?? false)) {
        if (!soundEnabled) {
          voice = VoiceOption.silent;
          await prefs.setInt(_keyVoice, voice.index);
        }
        await prefs.setBool(keySilentMigrated, true);
      }

      state = AppSettings(
        orientationLock: OrientationLockMode.values[safeOrientationIndex],
        hapticEnabled: hapticEnabled,
        soundEnabled: soundEnabled,
        keepScreenOn: keepScreenOn,
        voice: voice,
      );

      // Apply orientation lock
      _applyOrientationLock(state.orientationLock);

      // Sync haptic setting with service
      _syncHapticService(hapticEnabled);

      // Silent mutes everything; any other voice plays.
      _syncAudioService(voice);
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
      await prefs.setInt(_keyVoice, state.voice.index);
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

  void _syncAudioService(VoiceOption voice) {
    try {
      getIt<IAudioService>().setMuted(muted: voice == VoiceOption.silent);
    } catch (_) {
      // Ignore if service not available (e.g., in tests)
    }
  }

  /// Set voice for audio cues. [VoiceOption.silent] mutes all sound.
  Future<void> setVoice(VoiceOption voice) async {
    state = state.copyWith(voice: voice);
    _syncAudioService(voice);
    await _saveSettings();
  }
}
