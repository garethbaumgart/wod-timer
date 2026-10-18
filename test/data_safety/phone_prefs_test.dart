@Tags(['data-safety'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/review/review_prompter.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

import 'fixture_io.dart';
import 'head_shape.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final version in StorageCatalog.phoneVersions) {
    group('phone ${version.appVersion}', () {
      late PhoneFixture fixture;
      late SharedPreferences prefs;
      late ProviderContainer container;

      setUp(() async {
        fixture = PhoneFixture.load(version);
        SharedPreferences.setMockInitialValues(Map.of(fixture.mockValues));
        prefs = await SharedPreferences.getInstance();
        container = ProviderContainer();
      });

      tearDown(() => container.dispose());

      test('HEAD readers load every stored value', () async {
        final settings = await _loadSettings(container);
        _expectSettings(settings, fixture.expect);
        _expectMemory(SetupMemory(prefs), fixture.expect);
        expect(
          LiveHints(prefs).hasCountedRound,
          fixture.expect['hasCountedRound'],
        );

        const store = PrefsReviewStore();
        expect(
          await store.readInt(ReviewPrompter.momentsKey),
          fixture.expect['reviewMoments'],
        );
        expect(
          await store.readInt(ReviewPrompter.asksKey),
          fixture.expect['reviewAsks'],
        );
        expect(
          await store.readInt(ReviewPrompter.lastAskedKey),
          fixture.expect['reviewLastAskedMs'],
        );

        await prefs.reload();
        _expectOriginalKeysPreserved(
          prefs,
          fixture.mockValues,
          voiceAfterLoad: fixture.expect['voiceIndexAfterLoad'] as int,
          migratedAfterLoad: fixture.expect['silentMigratedAfterLoad'] as bool,
        );
      });

      test('second load is a no-op and data still equal', () async {
        await _loadSettings(container);
        await prefs.reload();
        final afterFirst = _snapshot(prefs);

        container.dispose();
        container = ProviderContainer();
        final settings = await _loadSettings(container);
        await prefs.reload();

        expect(_snapshot(prefs), afterFirst);
        _expectSettings(settings, fixture.expect);
        _expectMemory(SetupMemory(prefs), fixture.expect);
        expect(
          prefs.getInt('app_voice'),
          fixture.expect['voiceIndexAfterLoad'],
        );
        expect(prefs.getBool(AppSettingsNotifier.keySilentMigrated), isTrue);
        expect(
          prefs.get('some_plugin_key'),
          fixture.mockValues['some_plugin_key'],
        );
      });
    });
  }

  test(
    '1.3.0 silent migration runs once and never resets a later choice',
    () async {
      final from112 = PhoneFixture.load(
        StorageCatalog.phoneVersions.firstWhere((v) => v.appVersion == '1.1.2'),
      );
      SharedPreferences.setMockInitialValues(Map.of(from112.mockValues));
      var prefs = await SharedPreferences.getInstance();
      var container = ProviderContainer();
      var settings = await _loadSettings(container);
      expect(settings.voice, VoiceOption.silent);
      await prefs.reload();
      expect(prefs.getInt('app_voice'), VoiceOption.silent.index);
      expect(prefs.getBool('app_sound_enabled'), isFalse);
      expect(prefs.getBool(AppSettingsNotifier.keySilentMigrated), isTrue);
      expect(
        prefs.get('some_plugin_key'),
        from112.mockValues['some_plugin_key'],
      );
      container.dispose();

      container = ProviderContainer();
      settings = await _loadSettings(container);
      expect(settings.voice, VoiceOption.silent);
      container.dispose();

      final from200 = PhoneFixture.load(
        StorageCatalog.phoneVersions.firstWhere((v) => v.appVersion == '2.0.0'),
      );
      SharedPreferences.setMockInitialValues(Map.of(from200.mockValues));
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer();
      settings = await _loadSettings(container);
      expect(
        settings.voice,
        VoiceOption.major,
        reason: 'sound-off + migrated flag must not rewrite a later voice',
      );
      await prefs.reload();
      expect(prefs.getInt('app_voice'), VoiceOption.major.index);
      expect(prefs.getBool('app_sound_enabled'), isFalse);
      container.dispose();
    },
  );

  test('HEAD writers emit the newest phone fixture keys and types', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _loadSettings(container);
    final notifier = container.read(appSettingsNotifierProvider.notifier);
    await notifier.setOrientationLock(OrientationLockMode.portrait);
    await notifier.setHapticEnabled(enabled: false);
    await notifier.setVoice(VoiceOption.off);

    final memory = SetupMemory(prefs);
    await memory.saveAmrap(const AmrapSetup(durationSeconds: 720));
    await memory.saveForTime(
      const ForTimeSetup(capSeconds: 900, countUp: false),
    );
    await memory.saveEmom(const EmomSetup(intervalSeconds: 90, rounds: 12));
    await memory.saveTabata(
      const TabataSetup(workSeconds: 40, restSeconds: 20, rounds: 6),
    );
    await LiveHints(prefs).markCountedRound();

    const store = PrefsReviewStore();
    await store.writeInt(ReviewPrompter.momentsKey, 1);
    await store.writeInt(ReviewPrompter.asksKey, 1);
    await store.writeInt(ReviewPrompter.lastAskedKey, 1);
    await prefs.reload();

    final written = <String, String>{
      for (final key in prefs.getKeys()) key: prefsRuntimeType(prefs.get(key)),
    };
    expect(
      written,
      headPhoneKeyTypes(),
      reason: 'HEAD writers must emit every current phone key+type',
    );

    final newest = PhoneFixture.load(StorageCatalog.newestPhone);
    final want = typedKeyTypes(newest.keys)..remove(foreignPluginKey);
    expect(
      written,
      want,
      reason:
          'A new or changed phone key needs a new fixture directory. '
          'See docs/data-safety.md.',
    );
  });
}

Future<AppSettings> _loadSettings(ProviderContainer container) async {
  container.read(appSettingsNotifierProvider);
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(appSettingsNotifierProvider);
}

void _expectSettings(AppSettings settings, Map<String, dynamic> expectMap) {
  expect(settings.orientationLock.name, expectMap['orientationLock']);
  expect(settings.hapticEnabled, expectMap['hapticEnabled']);
  expect(settings.soundEnabled, expectMap['soundEnabled']);
  expect(settings.keepScreenOn, expectMap['keepScreenOn']);
  expect(settings.voice.name, expectMap['voice']);
}

void _expectMemory(SetupMemory memory, Map<String, dynamic> expectMap) {
  expect(memory.amrap.durationSeconds, expectMap['amrapDurationSeconds']);
  expect(memory.forTime.capSeconds, expectMap['forTimeCapSeconds']);
  expect(memory.forTime.countUp, expectMap['forTimeCountUp']);
  expect(memory.emom.intervalSeconds, expectMap['emomIntervalSeconds']);
  expect(memory.emom.rounds, expectMap['emomRounds']);
  expect(memory.tabata.workSeconds, expectMap['tabataWorkSeconds']);
  expect(memory.tabata.restSeconds, expectMap['tabataRestSeconds']);
  expect(memory.tabata.rounds, expectMap['tabataRounds']);
  expect(memory.lastMode, expectMap['lastMode']);
}

Map<String, Object?> _snapshot(SharedPreferences prefs) {
  final keys = prefs.getKeys().toList()..sort();
  return {for (final key in keys) key: prefs.get(key)};
}

void _expectOriginalKeysPreserved(
  SharedPreferences prefs,
  Map<String, Object> original, {
  required int voiceAfterLoad,
  required bool migratedAfterLoad,
}) {
  for (final entry in original.entries) {
    expect(prefs.get(entry.key), isNotNull, reason: '${entry.key} was removed');
    expect(
      prefs.get(entry.key).runtimeType,
      entry.value.runtimeType,
      reason: '${entry.key} changed type',
    );
    if (entry.key == 'app_voice') {
      expect(prefs.get(entry.key), voiceAfterLoad, reason: entry.key);
    } else {
      expect(prefs.get(entry.key), entry.value, reason: entry.key);
    }
  }
  expect(
    prefs.getBool(AppSettingsNotifier.keySilentMigrated),
    migratedAfterLoad,
  );
  final extra = prefs.getKeys().difference(original.keys.toSet())
    ..remove(AppSettingsNotifier.keySilentMigrated);
  expect(extra, isEmpty, reason: 'unexpected keys $extra');
}
