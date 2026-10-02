import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/injection.dart';

class MockAudioService extends Mock implements IAudioService {}

/// A real-shaped 1.2.x SharedPreferences file: every key the settings and
/// setup screens had written by then (and one key from somewhere else).
const _v12Prefs = <String, Object>{
  'app_orientation_lock': 2,
  'app_haptic_enabled': false,
  'app_sound_enabled': true,
  'app_keep_screen_on': false,
  'app_voice': 2,
  'setup_amrap_duration_s': 720,
  'setup_emom_rounds': 12,
  'review_prompt_last_shown_ms': 1790000000000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService audio;
  late ProviderContainer container;

  void boot(Map<String, Object> prefs) {
    SharedPreferences.setMockInitialValues(prefs);
    container = ProviderContainer();
  }

  Future<void> settle() async {
    container.read(appSettingsNotifierProvider);
    // _loadSettings is async fire-and-forget; let it complete.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    audio = MockAudioService();
    when(
      () => audio.setMuted(muted: any(named: 'muted')),
    ).thenAnswer((_) async {});
    getIt.registerSingleton<IAudioService>(audio);
  });

  tearDown(() {
    container.dispose();
    getIt.reset();
  });

  group('Silent voice replaces the Sound Effects switch (1.3.0)', () {
    test('choosing Silent mutes the audio service', () async {
      boot({});
      await settle();
      clearInteractions(audio);

      await container
          .read(appSettingsNotifierProvider.notifier)
          .setVoice(VoiceOption.silent);

      verify(() => audio.setMuted(muted: true)).called(1);
      expect(
        container.read(appSettingsNotifierProvider).voice,
        VoiceOption.silent,
      );
    });

    test('choosing a voice again unmutes', () async {
      boot({});
      await settle();
      final notifier = container.read(appSettingsNotifierProvider.notifier);
      await notifier.setVoice(VoiceOption.silent);
      clearInteractions(audio);

      await notifier.setVoice(VoiceOption.liam);

      verify(() => audio.setMuted(muted: false)).called(1);
    });

    test('Beeps only does not mute', () async {
      boot({});
      await settle();
      clearInteractions(audio);

      await container
          .read(appSettingsNotifierProvider.notifier)
          .setVoice(VoiceOption.off);

      verify(() => audio.setMuted(muted: false)).called(1);
    });

    test('a 1.2.x user with Sound Effects off becomes Silent, once', () async {
      boot({..._v12Prefs, 'app_sound_enabled': false});
      await settle();

      expect(
        container.read(appSettingsNotifierProvider).voice,
        VoiceOption.silent,
      );
      verify(() => audio.setMuted(muted: true)).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_voice'), VoiceOption.silent.index);
      expect(prefs.getBool(AppSettingsNotifier.keySilentMigrated), isTrue);
      // The old key is kept exactly as found.
      expect(prefs.getBool('app_sound_enabled'), isFalse);
    });

    test('after the migration the old key no longer mutes', () async {
      boot({
        ..._v12Prefs,
        'app_sound_enabled': false,
        'app_voice': VoiceOption.major.index,
        AppSettingsNotifier.keySilentMigrated: true,
      });
      await settle();

      expect(
        container.read(appSettingsNotifierProvider).voice,
        VoiceOption.major,
      );
      verify(() => audio.setMuted(muted: false)).called(1);
    });

    test('a 1.2.x user with sound on keeps their voice', () async {
      boot(_v12Prefs);
      await settle();

      expect(
        container.read(appSettingsNotifierProvider).voice,
        VoiceOption.holly,
      );
      verify(() => audio.setMuted(muted: false)).called(1);
    });
  });

  group('golden fixture: a 1.2.x prefs file survives 1.3.0', () {
    test('loads, saves and reloads with every pre-existing key intact',
        () async {
      boot(_v12Prefs);
      await settle();

      final settings = container.read(appSettingsNotifierProvider);
      expect(settings.orientationLock, OrientationLockMode.landscape);
      expect(settings.hapticEnabled, isFalse);
      expect(settings.soundEnabled, isTrue);
      expect(settings.keepScreenOn, isFalse);
      expect(settings.voice, VoiceOption.holly);

      // Save through the one setter the 1.3.0 UI still has for voice.
      await container
          .read(appSettingsNotifierProvider.notifier)
          .setVoice(VoiceOption.holly);

      final prefs = await SharedPreferences.getInstance();
      for (final entry in _v12Prefs.entries) {
        expect(
          prefs.get(entry.key),
          entry.value,
          reason: '${entry.key} must survive the update unchanged',
        );
      }
      // Only additive keys appear.
      final added = prefs.getKeys().difference(_v12Prefs.keys.toSet());
      expect(added, {AppSettingsNotifier.keySilentMigrated});

      // A second launch reads the same settings back.
      container.dispose();
      container = ProviderContainer();
      await settle();
      final again = container.read(appSettingsNotifierProvider);
      expect(again.voice, VoiceOption.holly);
      expect(again.keepScreenOn, isFalse);
      expect(again.orientationLock, OrientationLockMode.landscape);
    });

    test('a stored voice index from a newer build is clamped, not wiped',
        () async {
      boot({'app_voice': 99});
      await settle();

      expect(
        container.read(appSettingsNotifierProvider).voice,
        VoiceOption.values.last,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_voice'), 99);
    });
  });
}
