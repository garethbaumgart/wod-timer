import 'dart:io';

import 'fixture_io.dart';

final _constString = RegExp(
  r'''(?:static\s+)?const\s+(?:String\s+)?([a-z_][A-Za-z0-9_]*)\s*=\s*(?:'([^']*)'|"([^"]*)")''',
);

final _prefsCall = RegExp(
  r'''\b(getInt|setInt|getBool|setBool|getString|setString|getDouble|setDouble|getStringList|setStringList|writeInt|readInt|_readInt|_readBool)\s*\(\s*(?:'([^']+)'|"([^"]+)"|([a-z_][A-Za-z0-9_]*))''',
);

final _writeMap = RegExp(r'_write\(\s*\{([^}]+)\}');

final _writeEntry = RegExp(
  r'''(?:'([^']+)'|"([^"]+)"|([a-z_][A-Za-z0-9_]*))\s*:\s*('[^']*'|"[^"]*"|true|false|[^,\n]+)''',
);

const _callType = <String, String>{
  'getInt': 'int',
  'setInt': 'int',
  'writeInt': 'int',
  'readInt': 'int',
  '_readInt': 'int',
  'getBool': 'bool',
  'setBool': 'bool',
  '_readBool': 'bool',
  'getString': 'string',
  'setString': 'string',
  'getDouble': 'double',
  'setDouble': 'double',
  'getStringList': 'stringList',
  'setStringList': 'stringList',
};

/// SharedPreferences keys HEAD's phone writers read/write, with types.
///
/// Walks every non-generated Dart file under `lib/` for prefs get/set calls
/// and the const strings those calls use. A new key in an existing file or
/// a brand-new library file fails the shape guard unless a new fixture is
/// added. No hand-kept key list.
Map<String, String> headPhoneKeyTypes() {
  return scanLibPrefsKeyTypes(packageRoot());
}

Map<String, String> scanLibPrefsKeyTypes(Directory root) {
  final files = libProductionDartFiles(root);
  final types = <String, String>{};
  for (final file in files) {
    final source = file.readAsStringSync();
    _collectPrefsTypes(source, _constBindings(source), types);
  }
  if (types.isEmpty) {
    throw StateError('scanLibPrefsKeyTypes found no SharedPreferences keys');
  }
  return types;
}

List<File> libProductionDartFiles(Directory root) {
  final lib = Directory('${root.path}/lib');
  final files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))
          .where((file) => !file.path.endsWith('.freezed.dart'))
          .where((file) => !file.path.endsWith('injection.config.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Map<String, String> _constBindings(String text) {
  final out = <String, String>{};
  for (final match in _constString.allMatches(text)) {
    final value = match.group(2) ?? match.group(3)!;
    if (value.contains('.') || value.contains('/') || value.contains('\n')) {
      continue;
    }
    out[match.group(1)!] = value;
  }
  return out;
}

void _collectPrefsTypes(
  String text,
  Map<String, String> constToKey,
  Map<String, String> types,
) {
  for (final match in _prefsCall.allMatches(text)) {
    final method = match.group(1)!;
    final key = match.group(2) ?? match.group(3) ?? constToKey[match.group(4)];
    if (key == null || key.isEmpty) {
      continue;
    }
    _putType(types, key, _callType[method]!);
  }

  for (final mapMatch in _writeMap.allMatches(text)) {
    for (final entry in _writeEntry.allMatches(mapMatch.group(1)!)) {
      final key =
          entry.group(1) ?? entry.group(2) ?? constToKey[entry.group(3)!];
      if (key == null || key.isEmpty || types.containsKey(key)) {
        continue;
      }
      _putType(types, key, _typeFromWriteValue(entry.group(4)!.trim()));
    }
  }
}

String _typeFromWriteValue(String value) {
  if (value == 'true' || value == 'false' || value.endsWith('.countUp')) {
    return 'bool';
  }
  if (value.startsWith("'") || value.startsWith('"')) {
    return 'string';
  }
  return 'int';
}

void _putType(Map<String, String> types, String key, String type) {
  final existing = types[key];
  if (existing != null && existing != type) {
    throw StateError('prefs key $key has both $existing and $type');
  }
  types[key] = type;
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
