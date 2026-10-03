// Golden fixture for every key the app has ever written (app updates
// never remove stored data). A 1.3.1 prefs file with a non-default value
// under every key is read by every reader, written through every writer,
// then reloaded: every original key must still be there with the same
// type, nothing extra may appear, and the readers must read what the
// writers wrote.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/review/review_prompter.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

/// Every key a 1.3.1 install can hold, non-default, typed as stored.
const _v131Prefs = <String, Object>{
  // Settings (1.0 onwards).
  'app_orientation_lock': 2,
  'app_haptic_enabled': false,
  'app_sound_enabled': false,
  'app_keep_screen_on': false,
  'app_voice': 3,
  // 1.3.0 migration marker.
  'app_sound_silent_migrated_v130': true,
  // Review prompter (1.2.1).
  'review_value_moments': 7,
  'review_ask_count': 1,
  'review_last_asked_ms': 1790000000000,
  // Setup memory (1.2.0) and the tablet hero (1.3.1).
  'setup_amrap_duration_s': 720,
  'setup_fortime_cap_s': 900,
  'setup_fortime_count_up': false,
  'setup_emom_interval_s': 90,
  'setup_emom_rounds': 12,
  'setup_tabata_work_s': 40,
  'setup_tabata_rest_s': 20,
  'setup_tabata_rounds': 6,
  'setup_last_mode': 'tabata',
  // Live-screen hint (1.3.0).
  'hint_amrap_counted_round': true,
  // Something no build of ours wrote: must survive too.
  'some_plugin_key': 'keep me',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(Map.of(_v131Prefs));
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  Future<AppSettings> loadSettings() async {
    container.read(appSettingsNotifierProvider);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(appSettingsNotifierProvider);
  }

  test('every reader reads the 1.3.1 file as written', () async {
    final settings = await loadSettings();
    expect(settings.orientationLock, OrientationLockMode.landscape);
    expect(settings.hapticEnabled, isFalse);
    expect(settings.soundEnabled, isFalse);
    expect(settings.keepScreenOn, isFalse);
    // Migrated already: Sound Effects off no longer forces Silent.
    expect(settings.voice, VoiceOption.random);

    final memory = SetupMemory(prefs);
    expect(memory.amrap, const AmrapSetup(durationSeconds: 720));
    expect(memory.forTime, const ForTimeSetup(capSeconds: 900, countUp: false));
    expect(memory.emom, const EmomSetup(intervalSeconds: 90, rounds: 12));
    expect(
      memory.tabata,
      const TabataSetup(workSeconds: 40, restSeconds: 20, rounds: 6),
    );
    expect(memory.lastMode, 'tabata');

    expect(LiveHints(prefs).hasCountedRound, isTrue);

    const store = PrefsReviewStore();
    expect(await store.readInt(ReviewPrompter.momentsKey), 7);
    expect(await store.readInt(ReviewPrompter.asksKey), 1);
    expect(await store.readInt(ReviewPrompter.lastAskedKey), 1790000000000);
    expect(await store.readInt('review_never_written'), 0);
  });

  test(
    'every writer leaves every key in place, same type, nothing extra',
    () async {
      await loadSettings();
      final notifier = container.read(appSettingsNotifierProvider.notifier);
      await notifier.setVoice(VoiceOption.holly);
      await notifier.setHapticEnabled(enabled: true);
      await notifier.setOrientationLock(OrientationLockMode.portrait);

      final memory = SetupMemory(prefs);
      await memory.saveAmrap(const AmrapSetup(durationSeconds: 300));
      await memory.saveForTime(const ForTimeSetup(capSeconds: 600));
      await memory.saveEmom(const EmomSetup(intervalSeconds: 45, rounds: 20));
      await memory.saveTabata(TabataSetup.classic);

      await LiveHints(prefs).markCountedRound();
      await const PrefsReviewStore().writeInt(ReviewPrompter.asksKey, 2);

      await prefs.reload();
      for (final entry in _v131Prefs.entries) {
        final stored = prefs.get(entry.key);
        expect(stored, isNotNull, reason: '${entry.key} was removed');
        expect(
          stored.runtimeType,
          entry.value.runtimeType,
          reason: '${entry.key} changed type',
        );
      }
      expect(prefs.getKeys(), _v131Prefs.keys.toSet(), reason: 'no new keys');

      // Untouched keys keep their values exactly.
      expect(prefs.get('app_sound_enabled'), false);
      expect(prefs.get('app_keep_screen_on'), false);
      expect(prefs.get('app_sound_silent_migrated_v130'), true);
      expect(prefs.get('review_value_moments'), 7);
      expect(prefs.get('review_last_asked_ms'), 1790000000000);
      expect(prefs.get('hint_amrap_counted_round'), true);
      expect(prefs.get('some_plugin_key'), 'keep me');

      // And the written ones read back through their readers.
      final again = SetupMemory(prefs);
      expect(again.amrap.durationSeconds, 300);
      expect(again.forTime, const ForTimeSetup(capSeconds: 600));
      expect(again.emom, const EmomSetup(intervalSeconds: 45, rounds: 20));
      expect(again.tabata, TabataSetup.classic);
      expect(again.lastMode, 'tabata', reason: 'the last save was Tabata');
      expect(await const PrefsReviewStore().readInt(ReviewPrompter.asksKey), 2);
      expect(prefs.getInt('app_voice'), VoiceOption.holly.index);
      expect(prefs.getBool('app_haptic_enabled'), isTrue);
      expect(
        prefs.getInt('app_orientation_lock'),
        OrientationLockMode.portrait.index,
      );
    },
  );

  test(
    'mistyped values read as defaults and are left exactly as found',
    () async {
      SharedPreferences.setMockInitialValues({
        'setup_emom_interval_s': 'ninety',
        'setup_fortime_count_up': 1,
        'setup_last_mode': 4,
        'hint_amrap_counted_round': 'yes',
        'app_voice': 'holly',
        'app_haptic_enabled': 'no',
      });
      prefs = await SharedPreferences.getInstance();

      final memory = SetupMemory(prefs);
      expect(memory.emom, const EmomSetup());
      expect(memory.forTime.countUp, isTrue);
      expect(memory.lastMode, 'fortime');
      expect(LiveHints(prefs).hasCountedRound, isFalse);

      final settings = await loadSettings();
      expect(settings.voice, VoiceOption.major);
      expect(settings.hapticEnabled, isTrue);

      await LiveHints(prefs).markCountedRound();
      await prefs.reload();
      expect(prefs.get('setup_emom_interval_s'), 'ninety');
      expect(prefs.get('setup_fortime_count_up'), 1);
      expect(prefs.get('setup_last_mode'), 4);
      expect(prefs.get('app_voice'), 'holly');
      expect(prefs.get('app_haptic_enabled'), 'no');
    },
  );

  test('a fresh install reads defaults and writes only what it uses', () async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final settings = await loadSettings();
    expect(settings.voice, VoiceOption.major);
    expect(SetupMemory(prefs).lastMode, 'fortime');
    expect(LiveHints(prefs).hasCountedRound, isFalse);
    expect(
      await const PrefsReviewStore().readInt(ReviewPrompter.momentsKey),
      0,
    );

    await LiveHints(prefs).markCountedRound();
    await prefs.reload();
    // The load wrote the migration marker, the hint wrote its key.
    expect(prefs.getKeys(), {
      AppSettingsNotifier.keySilentMigrated,
      LiveHints.countedRoundKey,
    });
  });
}
