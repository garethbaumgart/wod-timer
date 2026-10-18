@Tags(['data-safety'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/persistence/storage_catalog.dart';

import 'fixture_io.dart';

void main() {
  test('pubspec version matches StorageCatalog.currentAppVersion', () {
    expect(
      pubspecVersion(),
      StorageCatalog.currentAppVersion,
      reason:
          'Bump StorageCatalog.currentAppVersion in the same PR as pubspec. '
          'See docs/data-safety.md.',
    );
  });

  test('current app version has a committed phone fixture', () {
    final current = StorageCatalog.phoneVersions.where(
      (v) => v.appVersion == StorageCatalog.currentAppVersion,
    );
    expect(
      current,
      isNotEmpty,
      reason:
          'Add ${StorageCatalog.currentAppVersion} to '
          'StorageCatalog.phoneVersions and a fixture under '
          'test/fixtures/data_safety/phone/. See docs/data-safety.md.',
    );
    final file = phonePrefsFile(current.first);
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'Current version ${StorageCatalog.currentAppVersion} has no fixture '
          'at ${file.path}. See docs/data-safety.md.',
    );
  });

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
}
