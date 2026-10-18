@Tags(['data-safety'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'head_shape.dart';

void main() {
  test(
    'HEAD scan finds prefs keys from every production writer, not one file',
    () {
      final types = headPhoneKeyTypes();
      expect(types['app_voice'], 'int');
      expect(types['app_sound_silent_migrated_v130'], 'bool');
      expect(types['setup_last_mode'], 'string');
      expect(types['setup_fortime_count_up'], 'bool');
      expect(types['hint_amrap_counted_round'], 'bool');
      expect(types['review_value_moments'], 'int');
      expect(types.containsKey('some_plugin_key'), isFalse);
    },
  );

  test(
    'scanLibPrefsKeyTypes walks every lib dart file, including new ones',
    () {
      final root = Directory.systemTemp.createTempSync('prefs-scan');
      addTearDown(() => root.deleteSync(recursive: true));

      File(
          '${root.path}/lib/features/timer/application/setup/setup_memory.dart',
        )
        ..createSync(recursive: true)
        ..writeAsStringSync('''
class SetupMemory {
  static const extraSetupKey = 'setup_extra_from_memory';
  Future<void> save() => _prefs.setInt(extraSetupKey, 1);
}
''');
      File('${root.path}/lib/brand_new_prefs.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
class ExtraPrefs {
  static const optInKey = 'extra_feature_opt_in';
  Future<void> save() => _prefs.setBool(optInKey, true);
}
''');

      expect(scanLibPrefsKeyTypes(root), {
        'setup_extra_from_memory': 'int',
        'extra_feature_opt_in': 'bool',
      });
    },
  );
}
