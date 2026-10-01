import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

/// Every key a real 1.1.3 install can hold, with non-default values, as
/// SharedPreferences stores them. 1.2.0 must load, save and reload around
/// these without changing a single one (app updates never remove data).
const _v113Prefs = <String, Object>{
  'app_orientation_lock': 1,
  'app_haptic_enabled': false,
  'app_sound_enabled': true,
  'app_keep_screen_on': false,
  'app_voice': 2,
  'review_value_moments': 3,
  'review_ask_count': 1,
  'review_last_asked_ms': 1726531200000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SetupMemory> memoryWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SetupMemory(await SharedPreferences.getInstance());
  }

  group('SetupMemory defaults', () {
    test('a fresh install opens every mode on its classic defaults', () async {
      final memory = await memoryWith({});

      expect(memory.amrap, const AmrapSetup());
      expect(memory.forTime, const ForTimeSetup());
      expect(memory.emom, const EmomSetup());
      expect(memory.tabata, TabataSetup.classic);
      expect(memory.amrap.durationSeconds, 600);
      expect(memory.forTime.capSeconds, 1200);
      expect(memory.forTime.countUp, isTrue);
      expect(memory.emom.intervalSeconds, 60);
      expect(memory.emom.rounds, 10);
    });
  });

  group('SetupMemory round trip', () {
    test('each mode reads back exactly what was last started', () async {
      final memory = await memoryWith({});

      await memory.saveAmrap(const AmrapSetup(durationSeconds: 720));
      await memory.saveForTime(
        const ForTimeSetup(capSeconds: 900, countUp: false),
      );
      await memory.saveEmom(const EmomSetup(intervalSeconds: 90, rounds: 12));
      await memory.saveTabata(
        const TabataSetup(workSeconds: 40, restSeconds: 20, rounds: 6),
      );

      final reloaded = SetupMemory(await SharedPreferences.getInstance());
      expect(reloaded.amrap, const AmrapSetup(durationSeconds: 720));
      expect(
        reloaded.forTime,
        const ForTimeSetup(capSeconds: 900, countUp: false),
      );
      expect(reloaded.emom, const EmomSetup(intervalSeconds: 90, rounds: 12));
      expect(
        reloaded.tabata,
        const TabataSetup(workSeconds: 40, restSeconds: 20, rounds: 6),
      );
    });
  });

  group('SetupMemory golden fixture (1.1.3 prefs)', () {
    test('loads a 1.1.3 file as defaults and never touches its keys', () async {
      final memory = await memoryWith(Map.of(_v113Prefs));

      // Nothing remembered yet: defaults, no crash on the foreign keys.
      expect(memory.emom, const EmomSetup());
      expect(memory.tabata, TabataSetup.classic);

      // Save every mode, then reload.
      await memory.saveAmrap(const AmrapSetup(durationSeconds: 900));
      await memory.saveForTime(const ForTimeSetup(capSeconds: 600));
      await memory.saveEmom(const EmomSetup(intervalSeconds: 45, rounds: 20));
      await memory.saveTabata(TabataSetup.classic);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // Every pre-existing key is still there, same type, same value.
      for (final entry in _v113Prefs.entries) {
        final stored = prefs.get(entry.key);
        expect(stored, entry.value, reason: entry.key);
        expect(stored.runtimeType, entry.value.runtimeType, reason: entry.key);
      }

      // The only additions are the setup_* keys.
      final added = prefs.getKeys().difference(_v113Prefs.keys.toSet());
      expect(added, {
        SetupMemory.amrapDurationKey,
        SetupMemory.forTimeCapKey,
        SetupMemory.forTimeCountUpKey,
        SetupMemory.emomIntervalKey,
        SetupMemory.emomRoundsKey,
        SetupMemory.tabataWorkKey,
        SetupMemory.tabataRestKey,
        SetupMemory.tabataRoundsKey,
      });
      expect(
        SetupMemory(prefs).emom,
        const EmomSetup(intervalSeconds: 45, rounds: 20),
      );
    });
  });

  group('SetupMemory defensive reads', () {
    test('a mistyped value reads as the default and is left in place', () async {
      final memory = await memoryWith({
        SetupMemory.emomRoundsKey: 'twelve',
        SetupMemory.forTimeCountUpKey: 7,
      });

      expect(memory.emom.rounds, SetupRanges.emomRounds.fallback);
      expect(memory.forTime.countUp, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(SetupMemory.emomRoundsKey), 'twelve');
      expect(prefs.get(SetupMemory.forTimeCountUpKey), 7);
    });

    test('out-of-range and off-step values land on a legal value', () async {
      final memory = await memoryWith({
        SetupMemory.amrapDurationKey: 99999,
        SetupMemory.forTimeCapKey: 0,
        SetupMemory.emomIntervalKey: 70,
        SetupMemory.tabataRoundsKey: -3,
      });

      expect(memory.amrap.durationSeconds, 3600);
      expect(memory.forTime.capSeconds, 60);
      expect(memory.emom.intervalSeconds, 75);
      expect(memory.tabata.rounds, 1);
    });
  });

  group('SetupRange', () {
    const range = SetupRanges.emomInterval;

    test('steps by its step and stops at its bounds', () {
      expect(range.increment(60), 75);
      expect(range.decrement(60), 45);
      expect(range.canDecrement(15), isFalse);
      expect(range.canIncrement(600), isFalse);
      expect(range.decrement(15), 15);
      expect(range.increment(600), 600);
    });

    test('AMRAP and For Time move in whole minutes', () {
      expect(SetupRanges.amrapDuration.increment(600), 660);
      expect(SetupRanges.forTimeCap.decrement(1200), 1140);
    });

    test('classic Tabata is 20/10 x 8 and totals 4:00', () {
      expect(TabataSetup.classic.isClassic, isTrue);
      expect(TabataSetup.classic.totalSeconds, 240);
      expect(TabataSetup.classic.copyWith(rounds: 9).isClassic, isFalse);
    });
  });
}
