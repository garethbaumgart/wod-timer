import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';

/// Remembers the last workout started in each mode, so setup opens on what
/// the athlete ran last time.
///
/// Storage is one additive SharedPreferences key per value (keys that 1.1.x
/// never wrote). A missing, mistyped or out-of-range value reads as the
/// default and its key is left exactly as found: nothing here deletes or
/// rewrites a key it didn't just set.
class SetupMemory {
  SetupMemory(this._prefs);

  final SharedPreferences _prefs;

  static const amrapDurationKey = 'setup_amrap_duration_s';
  static const forTimeCapKey = 'setup_fortime_cap_s';
  static const forTimeCountUpKey = 'setup_fortime_count_up';
  static const emomIntervalKey = 'setup_emom_interval_s';
  static const emomRoundsKey = 'setup_emom_rounds';
  static const tabataWorkKey = 'setup_tabata_work_s';
  static const tabataRestKey = 'setup_tabata_rest_s';
  static const tabataRoundsKey = 'setup_tabata_rounds';

  AmrapSetup get amrap => AmrapSetup(
    durationSeconds: _readInt(amrapDurationKey, SetupRanges.amrapDuration),
  );

  ForTimeSetup get forTime => ForTimeSetup(
    capSeconds: _readInt(forTimeCapKey, SetupRanges.forTimeCap),
    countUp: _readBool(forTimeCountUpKey, fallback: true),
  );

  EmomSetup get emom => EmomSetup(
    intervalSeconds: _readInt(emomIntervalKey, SetupRanges.emomInterval),
    rounds: _readInt(emomRoundsKey, SetupRanges.emomRounds),
  );

  TabataSetup get tabata => TabataSetup(
    workSeconds: _readInt(tabataWorkKey, SetupRanges.tabataWork),
    restSeconds: _readInt(tabataRestKey, SetupRanges.tabataRest),
    rounds: _readInt(tabataRoundsKey, SetupRanges.tabataRounds),
  );

  Future<void> saveAmrap(AmrapSetup setup) =>
      _write({amrapDurationKey: setup.durationSeconds});

  Future<void> saveForTime(ForTimeSetup setup) => _write({
    forTimeCapKey: setup.capSeconds,
    forTimeCountUpKey: setup.countUp,
  });

  Future<void> saveEmom(EmomSetup setup) => _write({
    emomIntervalKey: setup.intervalSeconds,
    emomRoundsKey: setup.rounds,
  });

  Future<void> saveTabata(TabataSetup setup) => _write({
    tabataWorkKey: setup.workSeconds,
    tabataRestKey: setup.restSeconds,
    tabataRoundsKey: setup.rounds,
  });

  int _readInt(String key, SetupRange range) {
    try {
      final value = _prefs.getInt(key);
      return value == null ? range.fallback : range.normalize(value);
    } on Object {
      // Wrong type under our key: use the default, leave the key alone.
      return range.fallback;
    }
  }

  bool _readBool(String key, {required bool fallback}) {
    try {
      return _prefs.getBool(key) ?? fallback;
    } on Object {
      return fallback;
    }
  }

  Future<void> _write(Map<String, Object> values) async {
    try {
      for (final entry in values.entries) {
        final value = entry.value;
        if (value is int) {
          await _prefs.setInt(entry.key, value);
        } else if (value is bool) {
          await _prefs.setBool(entry.key, value);
        }
      }
    } on Object {
      // Remembering is a convenience; never block a workout on it.
    }
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final setupMemoryProvider = Provider<SetupMemory>(
  (ref) => SetupMemory(ref.watch(sharedPreferencesProvider)),
);
