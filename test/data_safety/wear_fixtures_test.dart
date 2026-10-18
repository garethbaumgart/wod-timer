@Tags(['data-safety'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/persistence/storage_catalog.dart';

import 'fixture_io.dart';

/// Flutter-side record of Wear OS fixtures. Production decode is Kotlin
/// (`SetupMemory.decode`, `VoiceSettings`); JUnit covers that path.
void main() {
  for (final version in StorageCatalog.wearVersions) {
    test(
      'wear ${version.appVersion} fixture has every key that version wrote',
      () {
        final json = decodeJsonFile(wearPrefsFile(version));
        final keys = mockValuesFromTypedKeys(
          json['keys']! as Map<String, dynamic>,
        );
        final expectMap = json['expect']! as Map<String, dynamic>;
        expect(keys['wear_setup_amrap'], expectMap['amrap']);
        expect(keys['wear_setup_fortime'], expectMap['fortime']);
        expect(keys['wear_setup_emom'], expectMap['emom']);
        expect(keys['wear_setup_tabata'], expectMap['tabata']);
        expect(keys['wear_voice_pack'], expectMap['voicePack']);
        expect(keys['wear_voice_random'], expectMap['random']);
        expect(keys['wear_voice_muted'], expectMap['muted']);
        expect(keys['wear_voice_beeps'], expectMap['beeps']);
        expect(keys['wear_health_track'], expectMap['healthTrack']);
        expect(keys['wear_hint_amrap_counted'], expectMap['hintCounted']);
        expect(keys['wear_perm_asked'], expectMap['permAsked']);
        expect(keys['some_plugin_key'], isA<String>());
        expect((keys['some_plugin_key']! as String).contains('💪'), isTrue);
      },
    );
  }
}
