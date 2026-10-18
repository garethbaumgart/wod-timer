import 'dart:io';

import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/review/review_prompter.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

import 'fixture_io.dart';

const _prefsPrefixes = <String>[
  'app_',
  'setup_',
  'review_',
  'hint_',
  'watch_',
  'wear_',
  'recent_workouts',
];

bool _isPersistedKey(String value) =>
    _prefsPrefixes.any((prefix) => value == prefix || value.startsWith(prefix));

/// SharedPreferences keys HEAD's phone writers read/write, with types.
///
/// Public production constants are used where they exist. Private
/// `AppSettingsNotifier` keys are recovered from that file's `static const`
/// + `getInt`/`setInt`/`getBool`/`setBool` usage so this map cannot drift
/// from source without the guard failing.
Map<String, String> headPhoneKeyTypes() {
  final root = packageRoot();
  final scanned = dartPrefsKeyTypes(
    File(
      '${root.path}/lib/core/application/providers/app_settings_provider.dart',
    ).readAsStringSync(),
  );
  return {
    ...scanned,
    AppSettingsNotifier.keySilentMigrated: 'bool',
    SetupMemory.amrapDurationKey: 'int',
    SetupMemory.forTimeCapKey: 'int',
    SetupMemory.forTimeCountUpKey: 'bool',
    SetupMemory.emomIntervalKey: 'int',
    SetupMemory.emomRoundsKey: 'int',
    SetupMemory.tabataWorkKey: 'int',
    SetupMemory.tabataRestKey: 'int',
    SetupMemory.tabataRoundsKey: 'int',
    SetupMemory.lastModeKey: 'string',
    LiveHints.countedRoundKey: 'bool',
    ReviewPrompter.momentsKey: 'int',
    ReviewPrompter.asksKey: 'int',
    ReviewPrompter.lastAskedKey: 'int',
  };
}

/// Watch UserDefaults scalar keys HEAD writes (JSON blobs are separate).
Map<String, String> headWatchScalarKeyTypes() {
  final root = packageRoot();
  return <String, String>{
      ...swiftDefaultsKeyTypes(
        File(
          '${root.path}/ios/WODTimerWatch/Services/WatchAudioService.swift',
        ).readAsStringSync(),
      ),
      ...swiftDefaultsKeyTypes(
        File(
          '${root.path}/ios/WODTimerWatch/Services/WatchWorkoutTracker.swift',
        ).readAsStringSync(),
      ),
      ...swiftDefaultsKeyTypes(
        File(
          '${root.path}/ios/WODTimerWatch/Application/TimerViewModel.swift',
        ).readAsStringSync(),
      ),
    }
    ..remove('recent_workouts')
    ..removeWhere((key, _) => key.startsWith('watch_setup_'));
}

Set<String> headWatchSetupKeys() => {
  for (final code in ['amrap', 'fortime', 'emom', 'tabata'])
    'watch_setup_$code',
};

Set<String> headWatchWorkoutJsonKeys() {
  final text = File(
    '${packageRoot().path}/ios/WODTimerWatch/Domain/Workout.swift',
  ).readAsStringSync();
  const fields = ['id', 'name', 'timerType', 'prepCountdown', 'createdAt'];
  for (final field in fields) {
    if (!text.contains(' $field:') && !text.contains('let $field:')) {
      throw StateError('Workout.swift is missing Codable field $field');
    }
  }
  return {...fields};
}

Set<String> headWatchTimerTypeJsonCases() => {
  'amrap',
  'forTime',
  'emom',
  'tabata',
};

/// Wear OS `"wharfwod"` prefs keys HEAD writes.
Map<String, String> headWearKeyTypes() {
  final root = packageRoot();
  final types = <String, String>{
    ...kotlinPrefsKeyTypes(
      File(
        '${root.path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/application/SetupMemory.kt',
      ).readAsStringSync(),
    ),
    ...kotlinPrefsKeyTypes(
      File(
        '${root.path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/services/CueFiles.kt',
      ).readAsStringSync(),
    ),
    ...kotlinPrefsKeyTypes(
      File(
        '${root.path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/services/ExerciseTracker.kt',
      ).readAsStringSync(),
    ),
    ...kotlinPrefsKeyTypes(
      File(
        '${root.path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/application/TimerViewModel.kt',
      ).readAsStringSync(),
    ),
    ...kotlinPrefsKeyTypes(
      File(
        '${root.path}/android/wear/src/main/java/app/mentalmetal/wharfwod/wear/MainActivity.kt',
      ).readAsStringSync(),
    ),
  };
  for (final code in ['amrap', 'fortime', 'emom', 'tabata']) {
    types['wear_setup_$code'] = 'string';
  }
  return types;
}

Set<String> headWearEncodePrefixes() => {
  'amrap:',
  'fortime:',
  'emom:',
  'tabata:',
};

Map<String, String> dartPrefsKeyTypes(String text) {
  final nameToKey = <String, String>{};
  for (final match in RegExp(
    r"static const (?:String )?(\w+) = '([^']+)';",
  ).allMatches(text)) {
    final name = match.group(1)!;
    final key = match.group(2)!;
    if (_isPersistedKey(key)) {
      nameToKey[name] = key;
    }
  }

  final types = <String, String>{};
  for (final entry in nameToKey.entries) {
    final name = entry.key;
    final key = entry.value;
    if (RegExp(
      '(getInt|setInt|writeInt|_readInt)\\(\\s*$name\\b',
    ).hasMatch(text)) {
      types[key] = 'int';
    } else if (RegExp(
      '(getBool|setBool|_readBool)\\(\\s*$name\\b',
    ).hasMatch(text)) {
      types[key] = 'bool';
    } else if (RegExp('(getString|setString)\\(\\s*$name\\b').hasMatch(text)) {
      types[key] = 'string';
    }
  }
  return types;
}

Map<String, String> swiftDefaultsKeyTypes(String text) {
  final nameToKey = <String, String>{};
  for (final match in RegExp(
    r'(?:(?:static|private|let|var)\s+)+(\w+)\s*=\s*"([^"]+)"',
  ).allMatches(text)) {
    final key = match.group(2)!;
    if (_isPersistedKey(key) || key.startsWith('watch_setup_')) {
      nameToKey[match.group(1)!] = key;
    }
  }

  final types = <String, String>{};
  for (final match in RegExp(
    '"((?:watch_|recent_workouts)[^"]*)"',
  ).allMatches(text)) {
    final raw = match.group(1)!;
    for (final key in _expandTemplatedKey(raw)) {
      types.putIfAbsent(key, () => _swiftTypeFor(text, raw));
    }
  }
  for (final entry in nameToKey.entries) {
    for (final key in _expandTemplatedKey(entry.value)) {
      types[key] = _swiftTypeFor(text, entry.key);
    }
  }
  return types;
}

String _swiftTypeFor(String text, String token) {
  if (RegExp('string\\(forKey:[^\\n]*$token').hasMatch(text) ||
      token.contains('pack')) {
    return 'string';
  }
  if (RegExp('data\\(forKey:[^\\n]*$token').hasMatch(text) ||
      token.startsWith('watch_setup_') ||
      token == 'recent_workouts') {
    return 'json';
  }
  return 'bool';
}

Map<String, String> kotlinPrefsKeyTypes(String text) {
  final types = <String, String>{};
  for (final match in RegExp(
    r'(?:const val \w+\s*=\s*)?"((?:wear_|watch_)[^"]+)"',
  ).allMatches(text)) {
    final raw = match.group(1)!;
    for (final key in _expandTemplatedKey(raw)) {
      if (RegExp(
        '(getString|putString)\\([^\\n]*${RegExp.escape(raw)}',
      ).hasMatch(text)) {
        types[key] = 'string';
      } else if (RegExp(
        '(getBoolean|putBoolean)\\([^\\n]*${RegExp.escape(raw)}',
      ).hasMatch(text)) {
        types[key] = 'bool';
      } else if (key.startsWith('wear_setup_')) {
        types[key] = 'string';
      } else if (key.contains('pack')) {
        types[key] = 'string';
      } else {
        types[key] = 'bool';
      }
    }
  }
  return types;
}

Set<String> _expandTemplatedKey(String raw) {
  if (raw.startsWith('watch_setup_') &&
      (raw.contains(r'$') || raw.contains(r'\(') || raw.endsWith('_'))) {
    return {
      for (final code in ['amrap', 'fortime', 'emom', 'tabata'])
        'watch_setup_$code',
    };
  }
  if (raw.startsWith('wear_setup_') &&
      (raw.contains(r'$') || raw.contains(r'\(') || raw.endsWith('_'))) {
    return {
      for (final code in ['amrap', 'fortime', 'emom', 'tabata'])
        'wear_setup_$code',
    };
  }
  if (_isPersistedKey(raw)) {
    return {raw};
  }
  return {};
}
