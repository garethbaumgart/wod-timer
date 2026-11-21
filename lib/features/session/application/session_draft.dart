import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
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
/// the builder for an edit screen and coming back keeps it.
///
/// Every change she makes (add, edit, remove, undo, reorder) is also kept
/// as the last session (2.6.1), so Home's card and the next launch show
/// the session as she left it, START or no START. Opening the builder is
/// not a change: "+ NEW" or "+ THEN" and straight back leaves Home's card
/// as it was.
class SessionDraft extends Notifier<List<DraftBlock>> {
  int _nextId = 0;

  /// Bumped by [open]: an UNDO from an earlier session never lands in a
  /// new one.
  int _generation = 0;
  int get generation => _generation;

  @override
  List<DraftBlock> build() => const [];

  DraftBlock _entry(SessionBlock block) => DraftBlock(_nextId++, block);

  /// A change she made: the new blocks, kept as the last session.
  void _change(List<DraftBlock> next) {
    state = List.unmodifiable(next);
    unawaited(ref.read(sessionStoreProvider).saveBuilt(session));
  }

  /// The blocks, in order.
  List<SessionBlock> get blocks => [for (final e in state) e.block];

  WodSession get session => WodSession(blocks);

  /// Opens the builder on [blocks], noting where from.
  void open(List<SessionBlock> blocks, BuilderSource source) {
    _removed = null;
    _generation++;
    state = List.unmodifiable([
      for (final block in blocks.take(WodSession.maxBlocks)) _entry(block),
    ]);
    trackEvent('session_builder_opened', {'source': source.name});
  }

  bool get isFull => state.length >= WodSession.maxBlocks;

  void add(SessionBlock block) {
    if (isFull) return;
    _change([...state, _entry(block)]);
  }

  /// Where the block with [id] is now, or -1 when it has gone. Edits,
  /// removals and undos go by a block's id, never by a position that a
  /// reorder, an undo or a removal elsewhere may have moved.
  int indexOfId(int id) => state.indexWhere((e) => e.id == id);

  DraftBlock? entryOf(int id) {
    final i = indexOfId(id);
    return i < 0 ? null : state[i];
  }

  /// Gives the block with [id] new values; nothing if it has gone.
  void replaceById(int id, SessionBlock block) {
    final index = indexOfId(id);
    if (index < 0) return;
    _change([...state]..[index] = DraftBlock(id, block));
  }

  /// Removes the block at [index] and returns it, for an undo.
  DraftBlock? removeAt(int index) {
    if (index < 0 || index >= state.length) return null;
    final next = [...state];
    final removed = next.removeAt(index);
    _change(next);
    return removed;
  }

  /// Removes the block with [id]; returns where it was and the block.
  ({int index, DraftBlock entry})? removeById(int id) {
    final index = indexOfId(id);
    final removed = removeAt(index);
    return removed == null ? null : (index: index, entry: removed);
  }

  /// A block removed from its edit screen, for the builder to offer back
  /// (UNDO) when it opens again: taken by [takeRemoved].
  ({int index, DraftBlock entry})? _removed;

  void noteRemoved(int index, DraftBlock entry) =>
      _removed = (index: index, entry: entry);

  ({int index, DraftBlock entry})? takeRemoved() {
    final removed = _removed;
    _removed = null;
    return removed;
  }

  /// Puts a removed block back (UNDO) near where it was: never twice,
  /// never into a session opened since ([generation]), never past twelve.
  void restore(int index, DraftBlock entry, {required int generation}) {
    if (generation != _generation || isFull) return;
    if (indexOfId(entry.id) >= 0) return;
    final at = index.clamp(0, state.length);
    _change([...state]..insert(at, entry));
  }

  /// Moves the block at [from] so it ends up at [to].
  void move(int from, int to) {
    if (from < 0 || from >= state.length) return;
    final next = [...state];
    final entry = next.removeAt(from);
    next.insert(to.clamp(0, next.length), entry);
    _change(next);
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final sessionDraftProvider = NotifierProvider<SessionDraft, List<DraftBlock>>(
  SessionDraft.new,
);
