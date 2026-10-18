@Tags(['data-safety'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'fixture_io.dart';

/// Flutter-side check that each watch fixture is the Codable JSON HEAD's
/// `JSONDecoder` is expected to read. The production decoder is Swift
/// (`RecentWorkoutsStore`); XCTest covers that path. These tests must not
/// skip — they document the bytes, they do not replace the watch suite.
void main() {
  for (final version in StorageCatalog.watchVersions) {
    test(
      'watch ${version.appVersion} recent_workouts JSON matches expected',
      () {
        final raw = jsonDecode(watchRecentFile(version).readAsStringSync());
        expect(raw, isA<List<dynamic>>());
        final workouts = List<Map<String, dynamic>>.from(
          (raw as List<dynamic>).map((e) => e as Map<String, dynamic>),
        );
        final expected = decodeJsonFile(watchExpectedFile(version));
        final want = List<Map<String, dynamic>>.from(
          (expected['workouts']! as List<dynamic>).map(
            (e) => e as Map<String, dynamic>,
          ),
        );
        expect(workouts.length, want.length);
        for (var i = 0; i < workouts.length; i++) {
          final got = workouts[i];
          final exp = want[i];
          expect(got['id'], exp['id']);
          expect(got['name'], exp['name']);
          expect(got['prepCountdown'], {'seconds': exp['prep']});
          expect(got['createdAt'], isA<num>());
          final type = got['timerType']! as Map<String, dynamic>;
          expect(timerTypeCode(type), exp['code']);
          switch (exp['code'] as String) {
            case 'amrap':
              expect(
                _nestedInt(type, ['amrap', 'duration', 'seconds']),
                exp['seconds'],
              );
            case 'fortime':
              expect(
                _nestedInt(type, ['forTime', 'timeCap', 'seconds']),
                exp['cap'],
              );
              expect(_nestedBool(type, ['forTime', 'countUp']), exp['countUp']);
            case 'emom':
              expect(
                _nestedInt(type, ['emom', 'intervalDuration', 'seconds']),
                exp['interval'],
              );
              expect(
                _nestedInt(type, ['emom', 'rounds', 'value']),
                exp['rounds'],
              );
            case 'tabata':
              expect(
                _nestedInt(type, ['tabata', 'workDuration', 'seconds']),
                exp['work'],
              );
              expect(
                _nestedInt(type, ['tabata', 'restDuration', 'seconds']),
                exp['rest'],
              );
              expect(
                _nestedInt(type, ['tabata', 'rounds', 'value']),
                exp['rounds'],
              );
          }
        }

        if (expected['setup'] is Map) {
          for (final code in ['amrap', 'fortime', 'emom', 'tabata']) {
            expect(watchSetupFile(version, code).existsSync(), isTrue);
          }
          expect(watchPrefsFile(version).existsSync(), isTrue);
        }
      },
    );
  }
}

int _nestedInt(Map<String, dynamic> root, List<String> path) {
  Object? current = root;
  for (final key in path) {
    current = (current! as Map<String, dynamic>)[key];
  }
  return current! as int;
}

bool _nestedBool(Map<String, dynamic> root, List<String> path) {
  Object? current = root;
  for (final key in path) {
    current = (current! as Map<String, dynamic>)[key];
  }
  return current! as bool;
}
