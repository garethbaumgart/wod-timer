import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/injection.dart';

class MockAudioService extends Mock implements IAudioService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService audio;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    audio = MockAudioService();
    when(
      () => audio.setMuted(muted: any(named: 'muted')),
    ).thenAnswer((_) async {});
    getIt.registerSingleton<IAudioService>(audio);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    getIt.reset();
  });

  group('AppSettingsNotifier sound toggle', () {
    // Regression: the Sound Effects switch wrote the setting but nothing
    // ever called IAudioService.setMuted — the toggle was decorative.
    test('turning sound off mutes the audio service', () async {
      final notifier = container.read(appSettingsNotifierProvider.notifier);
      // Let the async _loadSettings pass finish so it can't clobber the
      // toggle (it re-applies persisted values + syncs services).
      await Future<void>.delayed(Duration.zero);
      clearInteractions(audio);

      await notifier.setSoundEnabled(enabled: false);

      verify(() => audio.setMuted(muted: true)).called(1);
      expect(container.read(appSettingsNotifierProvider).soundEnabled, false);
    });

    test('turning sound back on unmutes the audio service', () async {
      final notifier = container.read(appSettingsNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      clearInteractions(audio);

      await notifier.setSoundEnabled(enabled: false);
      await notifier.setSoundEnabled(enabled: true);

      verify(() => audio.setMuted(muted: false)).called(1);
      expect(container.read(appSettingsNotifierProvider).soundEnabled, true);
    });

    test('persisted sound-off is applied to the audio service on load',
        () async {
      SharedPreferences.setMockInitialValues({'app_sound_enabled': false});

      container.read(appSettingsNotifierProvider);
      // _loadSettings is async fire-and-forget; let it complete.
      await Future<void>.delayed(Duration.zero);

      verify(() => audio.setMuted(muted: true)).called(1);
    });
  });
}
