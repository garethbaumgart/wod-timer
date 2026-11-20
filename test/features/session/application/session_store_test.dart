// Today's WOD persistence (2.6.0): one new key holding versioned JSON for
// the last session, three for the Rest and Sets add-sheet values. The
// golden fixture holds every key an existing install can have, non-default;
// saving and loading a session must leave every one of them exactly as it
// was, and a session this build cannot read must never crash, never show
// and never be overwritten until a new session starts.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

/// Every key a 2.5.2 install can hold, non-default, typed as stored.
const _v252Prefs = <String, Object>{
  'app_orientation_lock': 2,
  'app_haptic_enabled': false,
  'app_sound_enabled': false,
  'app_keep_screen_on': false,
  'app_voice': 3,
  'app_sound_silent_migrated_v130': true,
  'review_value_moments': 7,
  'review_ask_count': 1,
  'review_last_asked_ms': 1790000000000,
  'setup_amrap_duration_s': 720,
  'setup_fortime_cap_s': 900,
  'setup_fortime_count_up': false,
  'setup_emom_interval_s': 90,
  'setup_emom_rounds': 12,
  'setup_tabata_work_s': 40,
  'setup_tabata_rest_s': 20,
  'setup_tabata_rounds': 6,
  'setup_last_mode': 'tabata',
  'hint_amrap_counted_round': true,
  'some_plugin_key': 'keep me',
};

/// The approved mock's session: Sets 5, Rest 3:00, EMOM 10, Rest 2:00,
/// AMRAP 12.
final mockSession = WodSession(const [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  RestBlock(seconds: 120),
  AmrapBlock(durationSeconds: 720),
]);

final everyKind = WodSession(const [
  ForTimeBlock(capSeconds: 600, countUp: false),
  EmomBlock(intervalSeconds: 45, rounds: 8),
  AmrapBlock(durationSeconds: 300),
  TabataBlock(workSeconds: 30, restSeconds: 15, rounds: 4),
  RestBlock(seconds: 90),
  SetsBlock(sets: 3, restSeconds: 60),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SharedPreferences, SessionStore)> storeWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(Map.of(values));
    final prefs = await SharedPreferences.getInstance();
    return (prefs, SessionStore(prefs, SetupMemory(prefs)));
  }

  group('the estimate', () {
    test('the mock session is about 41 min: blocks, rests, three '
        'get-readies, sets at a minute each with rests between', () {
      // Sets 5 x 1:00 + 4 x 2:00 = 13:00, rests 5:00, EMOM 10:00,
      // AMRAP 12:00, three 10s get-readies.
      expect(mockSession.estimatedSeconds(getReadySeconds: 10), 2430);
      expect(mockSession.aboutMinutes(getReadySeconds: 10), 41);
    });

    test('For Time counts at its cap, Tabata work and rest', () {
      expect(
        const ForTimeBlock(capSeconds: 600, countUp: true).estimatedSeconds,
        600,
      );
      expect(
        const TabataBlock(
          workSeconds: 20,
          restSeconds: 10,
          rounds: 8,
        ).estimatedSeconds,
        240,
      );
      expect(const SetsBlock(sets: 1, restSeconds: 120).estimatedSeconds, 60);
    });

    test('never under a minute, and kinds sorted and distinct', () {
      expect(
        WodSession(const [
          RestBlock(seconds: 15),
        ]).aboutMinutes(getReadySeconds: 10),
        1,
      );
      expect(mockSession.kindCodes, 'amrap,emom,rest,sets');
    });

    test('runnable with 1 to 12 blocks only', () {
      expect(WodSession(const []).isRunnable, isFalse);
      expect(
        WodSession(List.filled(12, const RestBlock(seconds: 60))).isRunnable,
        isTrue,
      );
      expect(
        WodSession(List.filled(13, const RestBlock(seconds: 60))).isRunnable,
        isFalse,
      );
    });
  });

  group('the codec', () {
    test('every kind round-trips', () {
      final json = SessionCodec.encode(everyKind);
      expect(SessionCodec.decode(json), everyKind);
    });

    test('values out of range snap into range', () {
      const raw =
          '{"v":1,"blocks":[{"kind":"rest","rest_s":7},'
          '{"kind":"emom","interval_s":50,"rounds":99}]}';
      expect(
        SessionCodec.decode(raw),
        WodSession(const [
          RestBlock(seconds: 15),
          EmomBlock(intervalSeconds: 45, rounds: 30),
        ]),
      );
    });

    for (final (name, raw) in <(String, Object?)>[
      ('null', null),
      ('not a string', 42),
      ('not JSON', '{oops'),
      ('a list', '[1,2]'),
      ('no version', '{"blocks":[{"kind":"rest","rest_s":60}]}'),
      ('a newer version', '{"v":2,"blocks":[{"kind":"rest","rest_s":60}]}'),
      ('no blocks', '{"v":1,"blocks":[]}'),
      ('blocks not a list', '{"v":1,"blocks":{"kind":"rest"}}'),
      ('an unknown kind', '{"v":1,"blocks":[{"kind":"yoga","rest_s":60}]}'),
      ('a mistyped value', '{"v":1,"blocks":[{"kind":"rest","rest_s":"60"}]}'),
      ('a missing value', '{"v":1,"blocks":[{"kind":"sets","sets":5}]}'),
      (
        'too many blocks',
        '{"v":1,"blocks":[${List.filled(13, '{"kind":"rest","rest_s":60}').join(',')}]}',
      ),
    ]) {
      test('$name reads as no session', () {
        expect(SessionCodec.decode(raw), isNull);
      });
    }
  });

  group('the store', () {
    test('golden fixture: saving and loading a session leaves every '
        'existing key exactly as it was', () async {
      final (prefs, store) = await storeWith(_v252Prefs);
      expect(store.lastSession, isNull);
      await store.saveLastSession(mockSession);
      await store.rememberBlock(const RestBlock(seconds: 45));
      await store.rememberBlock(const SetsBlock(sets: 4, restSeconds: 90));
      await prefs.reload();

      expect(store.lastSession, mockSession);
      for (final entry in _v252Prefs.entries) {
        expect(prefs.get(entry.key), entry.value, reason: entry.key);
      }
      expect(prefs.getKeys().difference(_v252Prefs.keys.toSet()), {
        SessionStore.lastSessionKey,
        SessionStore.restKey,
        SessionStore.setsKey,
        SessionStore.setsRestKey,
      });
    });

    test('a timer block remembers through setup memory without moving the '
        'tablet hero', () async {
      final (prefs, store) = await storeWith(_v252Prefs);
      await store.rememberBlock(
        const EmomBlock(intervalSeconds: 30, rounds: 20),
      );
      expect(prefs.getInt(SetupMemory.emomIntervalKey), 30);
      expect(prefs.getInt(SetupMemory.emomRoundsKey), 20);
      expect(prefs.getString(SetupMemory.lastModeKey), 'tabata');
      expect(
        store.lastBlockOf(BlockKind.emom),
        const EmomBlock(intervalSeconds: 30, rounds: 20),
      );
    });

    test(
      'the add sheet offers each kind its last values, defaults first',
      () async {
        final (_, store) = await storeWith(_v252Prefs);
        expect(
          store.lastBlockOf(BlockKind.amrap),
          const AmrapBlock(durationSeconds: 720),
        );
        expect(
          store.lastBlockOf(BlockKind.forTime),
          const ForTimeBlock(capSeconds: 900, countUp: false),
        );
        expect(
          store.lastBlockOf(BlockKind.rest),
          const RestBlock(seconds: 120),
        );
        expect(
          store.lastBlockOf(BlockKind.sets),
          const SetsBlock(sets: 5, restSeconds: 120),
        );
        expect(
          SessionRanges.rest.fallback,
          SetupRanges.emomInterval.fallback * 2,
        );
      },
    );

    test('a corrupt session reads as none and is left alone until a new '
        'session is saved', () async {
      const corrupt = '{"v":1,"blocks":[{"kind":"rest"';
      final (prefs, store) = await storeWith({
        ..._v252Prefs,
        SessionStore.lastSessionKey: corrupt,
      });
      expect(store.lastSession, isNull);
      await store.rememberBlock(const RestBlock(seconds: 30));
      await prefs.reload();
      expect(prefs.getString(SessionStore.lastSessionKey), corrupt);

      await store.saveLastSession(mockSession);
      expect(store.lastSession, mockSession);
    });

    test('a value of the wrong type reads as none, never throws', () async {
      final (prefs, store) = await storeWith({
        SessionStore.lastSessionKey: 12,
        SessionStore.restKey: 'two minutes',
      });
      expect(store.lastSession, isNull);
      expect(store.lastBlockOf(BlockKind.rest), const RestBlock(seconds: 120));
      expect(prefs.get(SessionStore.lastSessionKey), 12);
    });

    test('an empty session is never saved', () async {
      final (prefs, store) = await storeWith({});
      await store.saveLastSession(WodSession(const []));
      expect(prefs.getKeys(), isEmpty);
    });
  });
}
