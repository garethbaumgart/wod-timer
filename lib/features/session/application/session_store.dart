import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

/// The ranges a Rest and a Sets block move in, alongside [SetupRanges]
/// for the four timers. Rests go in 15s like an EMOM's interval.
abstract class SessionRanges {
  static const rest = SetupRange(min: 15, max: 600, step: 15, fallback: 120);
  static const sets = SetupRange(min: 1, max: 20, step: 1, fallback: 5);
  static const setsRest = SetupRange(
    min: 15,
    max: 600,
    step: 15,
    fallback: 120,
  );
}

/// The block JSON (version [SessionCodec.version]): one object per block,
/// its kind code and its settings in seconds and counts.
abstract class SessionCodec {
  static const int version = 1;

  static String encode(WodSession session) => jsonEncode({
    'v': version,
    'blocks': [for (final block in session.blocks) blockToJson(block)],
  });

  static Map<String, Object> blockToJson(SessionBlock block) => {
    'kind': block.kind.code,
    ...switch (block) {
      ForTimeBlock(:final capSeconds, :final countUp) => {
        'cap_s': capSeconds,
        'count_up': countUp,
      },
      EmomBlock(:final intervalSeconds, :final rounds) => {
        'interval_s': intervalSeconds,
        'rounds': rounds,
      },
      AmrapBlock(:final durationSeconds) => {'duration_s': durationSeconds},
      TabataBlock(:final workSeconds, :final restSeconds, :final rounds) => {
        'work_s': workSeconds,
        'rest_s': restSeconds,
        'rounds': rounds,
      },
      RestBlock(:final seconds) => {'rest_s': seconds},
      SetsBlock(:final sets, :final restSeconds) => {
        'sets': sets,
        'rest_s': restSeconds,
      },
    },
  };

  /// The session in [raw], or null for anything this build cannot read
  /// whole: not JSON, another version, an unknown kind, a missing or
  /// mistyped value, no blocks or too many. Values are snapped into range,
  /// as setup memory does.
  static WodSession? decode(Object? raw) {
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      if (json['v'] != version) return null;
      final list = json['blocks'];
      if (list is! List<Object?>) return null;
      if (list.isEmpty || list.length > WodSession.maxBlocks) return null;
      final blocks = <SessionBlock>[];
      for (final item in list) {
        final block = blockFromJson(item);
        if (block == null) return null;
        blocks.add(block);
      }
      return WodSession(blocks);
    } on Object {
      return null;
    }
  }

  static SessionBlock? blockFromJson(Object? item) {
    if (item is! Map<String, Object?>) return null;
    int? number(String key, SetupRange range) {
      final value = item[key];
      return value is int ? range.normalize(value) : null;
    }

    switch (BlockKind.fromCode(item['kind'])) {
      case BlockKind.forTime:
        final cap = number('cap_s', SetupRanges.forTimeCap);
        final up = item['count_up'];
        if (cap == null || up is! bool) return null;
        return ForTimeBlock(capSeconds: cap, countUp: up);
      case BlockKind.emom:
        final interval = number('interval_s', SetupRanges.emomInterval);
        final rounds = number('rounds', SetupRanges.emomRounds);
        if (interval == null || rounds == null) return null;
        return EmomBlock(intervalSeconds: interval, rounds: rounds);
      case BlockKind.amrap:
        final duration = number('duration_s', SetupRanges.amrapDuration);
        if (duration == null) return null;
        return AmrapBlock(durationSeconds: duration);
      case BlockKind.tabata:
        final work = number('work_s', SetupRanges.tabataWork);
        final rest = number('rest_s', SetupRanges.tabataRest);
        final rounds = number('rounds', SetupRanges.tabataRounds);
        if (work == null || rest == null || rounds == null) return null;
        return TabataBlock(
          workSeconds: work,
          restSeconds: rest,
          rounds: rounds,
        );
      case BlockKind.rest:
        final seconds = number('rest_s', SessionRanges.rest);
        if (seconds == null) return null;
        return RestBlock(seconds: seconds);
      case BlockKind.sets:
        final sets = number('sets', SessionRanges.sets);
        final rest = number('rest_s', SessionRanges.setsRest);
        if (sets == null || rest == null) return null;
        return SetsBlock(sets: sets, restSeconds: rest);
      case null:
        return null;
    }
  }
}

/// What Today's WOD keeps (2.6.0): the last session started, so Home can
/// repeat it, and each block kind's last values for the add sheet. No
/// history: nothing else is kept.
///
/// New additive keys only. The four timers' last values are setup memory's
/// own keys, written without moving the tablet hero. A session this build
/// cannot read reads as none and its key is left exactly as found until
/// the next session is started.
class SessionStore {
  SessionStore(this._prefs, this._memory);

  final SharedPreferences _prefs;
  final SetupMemory _memory;

  static const lastSessionKey = 'wod_last_session';
  static const restKey = 'wod_block_rest_s';
  static const setsKey = 'wod_block_sets';
  static const setsRestKey = 'wod_block_sets_rest_s';

  /// The last session started, or null (none yet, or unreadable).
  WodSession? get lastSession {
    try {
      return SessionCodec.decode(_prefs.get(lastSessionKey));
    } on Object {
      return null;
    }
  }

  Future<void> saveLastSession(WodSession session) async {
    if (!session.isRunnable) return;
    try {
      await _prefs.setString(lastSessionKey, SessionCodec.encode(session));
    } on Object {
      // Repeating is a convenience; never block a workout on it.
    }
  }

  /// The block the add sheet offers for [kind]: what that kind was set to
  /// last, on its own setup screen or in a session.
  SessionBlock lastBlockOf(BlockKind kind) => switch (kind) {
    BlockKind.forTime => ForTimeBlock(
      capSeconds: _memory.forTime.capSeconds,
      countUp: _memory.forTime.countUp,
    ),
    BlockKind.emom => EmomBlock(
      intervalSeconds: _memory.emom.intervalSeconds,
      rounds: _memory.emom.rounds,
    ),
    BlockKind.amrap => AmrapBlock(
      durationSeconds: _memory.amrap.durationSeconds,
    ),
    BlockKind.tabata => TabataBlock(
      workSeconds: _memory.tabata.workSeconds,
      restSeconds: _memory.tabata.restSeconds,
      rounds: _memory.tabata.rounds,
    ),
    BlockKind.rest => RestBlock(seconds: _readInt(restKey, SessionRanges.rest)),
    BlockKind.sets => SetsBlock(
      sets: _readInt(setsKey, SessionRanges.sets),
      restSeconds: _readInt(setsRestKey, SessionRanges.setsRest),
    ),
  };

  /// Remembers [block]'s values as its kind's last.
  Future<void> rememberBlock(SessionBlock block) async {
    try {
      switch (block) {
        case ForTimeBlock(:final capSeconds, :final countUp):
          await _memory.saveForTime(
            ForTimeSetup(capSeconds: capSeconds, countUp: countUp),
            markLastMode: false,
          );
        case EmomBlock(:final intervalSeconds, :final rounds):
          await _memory.saveEmom(
            EmomSetup(intervalSeconds: intervalSeconds, rounds: rounds),
            markLastMode: false,
          );
        case AmrapBlock(:final durationSeconds):
          await _memory.saveAmrap(
            AmrapSetup(durationSeconds: durationSeconds),
            markLastMode: false,
          );
        case TabataBlock(:final workSeconds, :final restSeconds, :final rounds):
          await _memory.saveTabata(
            TabataSetup(
              workSeconds: workSeconds,
              restSeconds: restSeconds,
              rounds: rounds,
            ),
            markLastMode: false,
          );
        case RestBlock(:final seconds):
          await _prefs.setInt(restKey, seconds);
        case SetsBlock(:final sets, :final restSeconds):
          await _prefs.setInt(setsKey, sets);
          await _prefs.setInt(setsRestKey, restSeconds);
      }
    } on Object {
      // Remembering is a convenience; never block a workout on it.
    }
  }

  int _readInt(String key, SetupRange range) {
    try {
      final value = _prefs.getInt(key);
      return value == null ? range.fallback : range.normalize(value);
    } on Object {
      return range.fallback;
    }
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(
    ref.watch(sharedPreferencesProvider),
    ref.watch(setupMemoryProvider),
  ),
);
