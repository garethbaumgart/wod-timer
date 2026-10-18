import 'dart:convert';
import 'dart:io';

import 'storage_catalog.dart';

export 'storage_catalog.dart';

/// A key no Wharf WOD build wrote. HEAD must leave it in place; it is not
/// part of the HEAD ↔ newest-fixture shape comparison.
const foreignPluginKey = 'some_plugin_key';

/// Package root (the directory that holds pubspec.yaml).
Directory packageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return Directory.current;
}

Directory fixturesRoot() =>
    Directory('${packageRoot().path}/test/fixtures/data_safety');

File fixtureManifestFile() => File('${fixturesRoot().path}/MANIFEST.sha256');

File phonePrefsFile(ShippedStorageVersion version) => File(
  '${packageRoot().path}/test/fixtures/data_safety/phone/${version.directory}/prefs.json',
);

File watchRecentFile(ShippedStorageVersion version) => File(
  '${packageRoot().path}/test/fixtures/data_safety/watch/${version.directory}/recent_workouts.json',
);

File watchExpectedFile(ShippedStorageVersion version) => File(
  '${packageRoot().path}/test/fixtures/data_safety/watch/${version.directory}/expected.json',
);

File watchPrefsFile(ShippedStorageVersion version) => File(
  '${packageRoot().path}/test/fixtures/data_safety/watch/${version.directory}/prefs.json',
);

File watchSetupFile(ShippedStorageVersion version, String code) => File(
  '${packageRoot().path}/test/fixtures/data_safety/watch/${version.directory}/setup_$code.json',
);

File wearPrefsFile(ShippedStorageVersion version) => File(
  '${packageRoot().path}/test/fixtures/data_safety/wear/${version.directory}/prefs.json',
);

Map<String, dynamic> decodeJsonFile(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  throw StateError('${file.path} is not a JSON object');
}

/// SharedPreferences.setMockInitialValues map from a typed fixture object.
Map<String, Object> mockValuesFromTypedKeys(Map<String, dynamic> keys) {
  final out = <String, Object>{};
  for (final entry in keys.entries) {
    final spec = entry.value;
    if (spec is! Map) {
      throw StateError('${entry.key} is not a typed value');
    }
    if (spec.containsKey('int')) {
      out[entry.key] = spec['int'] as int;
    } else if (spec.containsKey('bool')) {
      out[entry.key] = spec['bool'] as bool;
    } else if (spec.containsKey('string')) {
      out[entry.key] = spec['string'] as String;
    } else {
      throw StateError('${entry.key} has no int/bool/string');
    }
  }
  return out;
}

Map<String, String> typedKeyTypes(Map<String, dynamic> keys) {
  final out = <String, String>{};
  for (final entry in keys.entries) {
    final spec = entry.value;
    if (spec is! Map) {
      throw StateError('${entry.key} is not a typed value');
    }
    if (spec.containsKey('int')) {
      out[entry.key] = 'int';
    } else if (spec.containsKey('bool')) {
      out[entry.key] = 'bool';
    } else if (spec.containsKey('string')) {
      out[entry.key] = 'string';
    } else {
      throw StateError('${entry.key} has no int/bool/string');
    }
  }
  return out;
}

Map<String, String> jsonScalarTypes(Map<String, dynamic> values) {
  final out = <String, String>{};
  for (final entry in values.entries) {
    final value = entry.value;
    if (value is int) {
      out[entry.key] = 'int';
    } else if (value is bool) {
      out[entry.key] = 'bool';
    } else if (value is String) {
      out[entry.key] = 'string';
    } else if (value is double) {
      out[entry.key] = 'double';
    } else {
      throw StateError(
        '${entry.key} has unsupported scalar ${value.runtimeType}',
      );
    }
  }
  return out;
}

String prefsRuntimeType(Object? value) {
  if (value is int) {
    return 'int';
  }
  if (value is bool) {
    return 'bool';
  }
  if (value is String) {
    return 'string';
  }
  if (value is double) {
    return 'double';
  }
  throw StateError('unsupported prefs type ${value.runtimeType}');
}

class PhoneFixture {
  PhoneFixture({
    required this.version,
    required this.keys,
    required this.expect,
    required this.mockValues,
  });

  factory PhoneFixture.load(ShippedStorageVersion version) {
    final json = decodeJsonFile(phonePrefsFile(version));
    final keys = json['keys']! as Map<String, dynamic>;
    return PhoneFixture(
      version: version,
      keys: keys,
      expect: json['expect']! as Map<String, dynamic>,
      mockValues: mockValuesFromTypedKeys(keys),
    );
  }

  final ShippedStorageVersion version;
  final Map<String, dynamic> keys;
  final Map<String, dynamic> expect;
  final Map<String, Object> mockValues;
}

String timerTypeCode(Map<String, dynamic> timerType) {
  if (timerType.containsKey('amrap')) {
    return 'amrap';
  }
  if (timerType.containsKey('forTime')) {
    return 'fortime';
  }
  if (timerType.containsKey('emom')) {
    return 'emom';
  }
  if (timerType.containsKey('tabata')) {
    return 'tabata';
  }
  throw StateError('unknown TimerType $timerType');
}
