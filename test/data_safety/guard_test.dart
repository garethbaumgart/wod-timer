@Tags(['data-safety'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'fixture_io.dart';
import 'head_shape.dart';

void main() {
  test('HEAD phone prefs keys and types match the newest committed fixture', () {
    final newest = PhoneFixture.load(StorageCatalog.newestPhone);
    final fixtureShape = typedKeyTypes(newest.keys)..remove(foreignPluginKey);
    expect(
      headPhoneKeyTypes(),
      fixtureShape,
      reason:
          'HEAD read/writes a different SharedPreferences shape than '
          'test/fixtures/data_safety/phone/${StorageCatalog.newestPhone.directory}/. '
          'Add a new fixture directory (never edit an old one). '
          'See docs/data-safety.md.',
    );
  });

  test(
    'HEAD watch UserDefaults keys and payload shapes match the newest fixture',
    () {
      final version = StorageCatalog.newestWatch;
      final prefs = decodeJsonFile(watchPrefsFile(version));
      expect(
        jsonScalarTypes(prefs),
        headWatchScalarKeyTypes(),
        reason:
            'HEAD watch scalar keys/types drifted from '
            'watch/${version.directory}/prefs.json. Add a new fixture.',
      );

      final recents = jsonDecode(watchRecentFile(version).readAsStringSync());
      expect(recents, isA<List<dynamic>>());
      final first = (recents as List<dynamic>).first as Map<String, dynamic>;
      expect(first.keys.toSet(), headWatchWorkoutJsonKeys());
      final prep = first['prepCountdown']! as Map<String, dynamic>;
      expect(prep.keys.toSet(), {'seconds'});
      expect(prep['seconds'], isA<int>());
      expect(first['createdAt'], isA<num>());
      final timerType = first['timerType']! as Map<String, dynamic>;
      expect(
        timerType.keys.toSet().intersection(headWatchTimerTypeJsonCases()),
        isNotEmpty,
      );

      for (final code in ['amrap', 'fortime', 'emom', 'tabata']) {
        expect(watchSetupFile(version, code).existsSync(), isTrue);
      }
      expect(headWatchSetupKeys(), {
        for (final code in ['amrap', 'fortime', 'emom', 'tabata'])
          'watch_setup_$code',
      });
    },
  );

  test(
    'HEAD Wear prefs keys, types, and encode shapes match the newest fixture',
    () {
      final version = StorageCatalog.newestWear;
      final json = decodeJsonFile(wearPrefsFile(version));
      final fixtureShape = typedKeyTypes(json['keys']! as Map<String, dynamic>)
        ..remove(foreignPluginKey);
      expect(
        headWearKeyTypes(),
        fixtureShape,
        reason:
            'HEAD Wear keys/types drifted from wear/${version.directory}/. '
            'Add a new fixture. See docs/data-safety.md.',
      );

      final encodeSource = File(
        '${packageRoot().path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/application/SetupMemory.kt',
      ).readAsStringSync();
      for (final prefix in headWearEncodePrefixes()) {
        expect(encodeSource.contains('"$prefix'), isTrue);
      }
      final keys = json['keys']! as Map<String, dynamic>;
      for (final code in ['amrap', 'fortime', 'emom', 'tabata']) {
        final spec = keys['wear_setup_$code']! as Map<String, dynamic>;
        expect(spec['string'], startsWith('$code:'));
      }
    },
  );

  test('every shipped phone version has a prefs fixture', () {
    for (final version in StorageCatalog.phoneVersions) {
      final file = phonePrefsFile(version);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Missing phone fixture for ${version.appVersion} at ${file.path}. '
            'See docs/data-safety.md.',
      );
    }
  });

  test('every shipped watch version has a recent_workouts fixture', () {
    for (final version in StorageCatalog.watchVersions) {
      final file = watchRecentFile(version);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Missing watch fixture for ${version.appVersion} at ${file.path}. '
            'See docs/data-safety.md.',
      );
    }
  });

  test('every shipped wear version has a prefs fixture', () {
    for (final version in StorageCatalog.wearVersions) {
      final file = wearPrefsFile(version);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Missing wear fixture for ${version.appVersion} at ${file.path}. '
            'See docs/data-safety.md.',
      );
    }
  });

  test(
    'fixture checksums and git-show key lists match committed source',
    () async {
      final script = File(
        '${packageRoot().path}/tool/data_safety/verify_fixtures.py',
      );
      expect(script.existsSync(), isTrue);
      final result = await Process.run('python3', [
        script.path,
      ], workingDirectory: packageRoot().path);
      final output = '${result.stdout}${result.stderr}';
      expect(result.exitCode, 0, reason: 'verify_fixtures.py failed:\n$output');
    },
  );
}
