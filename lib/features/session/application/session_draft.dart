import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';

/// Where the builder was opened from, for analytics.
enum BuilderSource {
  /// "+ NEW" on Home's card (or the empty card).
  home,

  /// "+ THEN" on a setup screen.
  then,

  /// Home's card with a last session: repeat it.
  repeat,
}

/// One block in the builder, with an id that follows it through reorders
/// (two identical rests are still two rows).
@immutable
class DraftBlock {
  const DraftBlock(this.id, this.block);

  final int id;
  final SessionBlock block;
}

/// The session being built (2.6.0). Lives while the app does, so leaving
/// the builder for an edit screen and coming back keeps it; it is only
/// stored once START saves it as the last session.
class SessionDraft extends Notifier<List<DraftBlock>> {
  int _nextId = 0;

  @override
  List<DraftBlock> build() => const [];

  DraftBlock _entry(SessionBlock block) => DraftBlock(_nextId++, block);

  /// The blocks, in order.
  List<SessionBlock> get blocks => [for (final e in state) e.block];

  WodSession get session => WodSession(blocks);

  /// Opens the builder on [blocks], noting where from.
  void open(List<SessionBlock> blocks, BuilderSource source) {
    state = List.unmodifiable([
      for (final block in blocks.take(WodSession.maxBlocks)) _entry(block),
    ]);
    trackEvent('session_builder_opened', {'source': source.name});
  }

  bool get isFull => state.length >= WodSession.maxBlocks;

  void add(SessionBlock block) {
    if (isFull) return;
    state = List.unmodifiable([...state, _entry(block)]);
  }

  void replace(int index, SessionBlock block) {
    if (index < 0 || index >= state.length) return;
    state = List.unmodifiable(
      [...state]..[index] = DraftBlock(state[index].id, block),
    );
  }

  /// Removes the block at [index] and returns it, for an undo.
  DraftBlock? removeAt(int index) {
    if (index < 0 || index >= state.length) return null;
    final next = [...state];
    final removed = next.removeAt(index);
    state = List.unmodifiable(next);
    return removed;
  }

  /// Puts a removed block back (UNDO).
  void restore(int index, DraftBlock entry) {
    if (isFull) return;
    final at = index.clamp(0, state.length);
    state = List.unmodifiable([...state]..insert(at, entry));
  }

  /// Moves the block at [from] so it ends up at [to].
  void move(int from, int to) {
    if (from < 0 || from >= state.length) return;
    final next = [...state];
    final entry = next.removeAt(from);
    next.insert(to.clamp(0, next.length), entry);
    state = List.unmodifiable(next);
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final sessionDraftProvider = NotifierProvider<SessionDraft, List<DraftBlock>>(
  SessionDraft.new,
);
