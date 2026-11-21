import 'package:meta/meta.dart';

/// What a block of Today's WOD can be (2.6.0): one of the four timers, a
/// rest, or sets. [code] is what is stored and what analytics send; the
/// four timers share the route codes, so a timer block opens the same live
/// screen as the timer on its own.
enum BlockKind {
  forTime('fortime'),
  emom('emom'),
  amrap('amrap'),
  tabata('tabata'),
  rest('rest'),
  sets('sets');

  const BlockKind(this.code);

  final String code;

  /// One of the four timers, run by the timer engine as it is today.
  bool get isTimer => this != rest && this != sets;

  static BlockKind? fromCode(Object? code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// One block of a session: exactly the settings its setup screen has.
///
/// [estimatedSeconds] is how long the block itself runs, without the
/// get-ready in front of it: a For Time at its cap, a Sets block at one
/// minute of work per set plus the rests between sets.
@immutable
sealed class SessionBlock {
  const SessionBlock();

  BlockKind get kind;

  int get estimatedSeconds;

  /// Every block but a Rest starts with the standard GET READY.
  bool get hasGetReady => kind != BlockKind.rest;
}

final class ForTimeBlock extends SessionBlock {
  const ForTimeBlock({required this.capSeconds, required this.countUp});

  final int capSeconds;
  final bool countUp;

  @override
  BlockKind get kind => BlockKind.forTime;

  @override
  int get estimatedSeconds => capSeconds;

  @override
  bool operator ==(Object other) =>
      other is ForTimeBlock &&
      other.capSeconds == capSeconds &&
      other.countUp == countUp;

  @override
  int get hashCode => Object.hash(kind, capSeconds, countUp);
}

final class EmomBlock extends SessionBlock {
  const EmomBlock({required this.intervalSeconds, required this.rounds});

  final int intervalSeconds;
  final int rounds;

  @override
  BlockKind get kind => BlockKind.emom;

  @override
  int get estimatedSeconds => intervalSeconds * rounds;

  @override
  bool operator ==(Object other) =>
      other is EmomBlock &&
      other.intervalSeconds == intervalSeconds &&
      other.rounds == rounds;

  @override
  int get hashCode => Object.hash(kind, intervalSeconds, rounds);
}

final class AmrapBlock extends SessionBlock {
  const AmrapBlock({required this.durationSeconds});

  final int durationSeconds;

  @override
  BlockKind get kind => BlockKind.amrap;

  @override
  int get estimatedSeconds => durationSeconds;

  @override
  bool operator ==(Object other) =>
      other is AmrapBlock && other.durationSeconds == durationSeconds;

  @override
  int get hashCode => Object.hash(kind, durationSeconds);
}

final class TabataBlock extends SessionBlock {
  const TabataBlock({
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
  });

  final int workSeconds;
  final int restSeconds;
  final int rounds;

  @override
  BlockKind get kind => BlockKind.tabata;

  @override
  int get estimatedSeconds => (workSeconds + restSeconds) * rounds;

  @override
  bool operator ==(Object other) =>
      other is TabataBlock &&
      other.workSeconds == workSeconds &&
      other.restSeconds == restSeconds &&
      other.rounds == rounds;

  @override
  int get hashCode => Object.hash(kind, workSeconds, restSeconds, rounds);
}

/// A rest between blocks: counts its duration down and hands over.
final class RestBlock extends SessionBlock {
  const RestBlock({required this.seconds});

  final int seconds;

  @override
  BlockKind get kind => BlockKind.rest;

  @override
  int get estimatedSeconds => seconds;

  @override
  bool operator ==(Object other) =>
      other is RestBlock && other.seconds == seconds;

  @override
  int get hashCode => Object.hash(kind, seconds);
}

/// Strength: [sets] sets with no work clock (SET DONE ends one) and a
/// counted rest of [restSeconds] between them. There is no rest after the
/// last set.
final class SetsBlock extends SessionBlock {
  const SetsBlock({required this.sets, required this.restSeconds});

  final int sets;
  final int restSeconds;

  /// What a set counts as in the estimate and the strip: it has no clock.
  static const int setSeconds = 60;

  @override
  BlockKind get kind => BlockKind.sets;

  @override
  int get estimatedSeconds => sets * setSeconds + (sets - 1) * restSeconds;

  @override
  bool operator ==(Object other) =>
      other is SetsBlock &&
      other.sets == sets &&
      other.restSeconds == restSeconds;

  @override
  int get hashCode => Object.hash(kind, sets, restSeconds);
}

/// Today's WOD: a plain ordered list of 1 to [maxBlocks] blocks.
@immutable
class WodSession {
  WodSession(Iterable<SessionBlock> blocks)
    : blocks = List.unmodifiable(blocks);

  final List<SessionBlock> blocks;

  static const int maxBlocks = 12;

  bool get isEmpty => blocks.isEmpty;

  /// What START accepts.
  bool get isRunnable => blocks.isNotEmpty && blocks.length <= maxBlocks;

  /// The whole session in seconds: every block's own length and one
  /// get-ready of [getReadySeconds] in front of each block that has one.
  int estimatedSeconds({required int getReadySeconds}) => blocks.fold(
    0,
    (sum, b) =>
        sum + b.estimatedSeconds + (b.hasGetReady ? getReadySeconds : 0),
  );

  /// "About N min": the estimate to the nearest minute, never under one.
  int aboutMinutes({required int getReadySeconds}) {
    final minutes = (estimatedSeconds(getReadySeconds: getReadySeconds) / 60)
        .round();
    return minutes < 1 ? 1 : minutes;
  }

  /// The distinct kinds, sorted by code ("amrap,emom,rest,sets"), for
  /// analytics.
  String get kindCodes =>
      ({for (final b in blocks) b.kind.code}.toList()..sort()).join(',');

  @override
  bool operator ==(Object other) =>
      other is WodSession &&
      other.blocks.length == blocks.length &&
      [
        for (var i = 0; i < blocks.length; i++) other.blocks[i] == blocks[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hashAll(blocks);
}
