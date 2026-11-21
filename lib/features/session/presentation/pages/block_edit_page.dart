import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// A block opened from the builder (2.6.0): its setup screen, with the
/// block's values, DONE in place of START and REMOVE BLOCK in place of
/// "+ THEN". Back leaves the block as it was.
@immutable
class BlockEdit {
  const BlockEdit({
    required this.block,
    required this.onDone,
    required this.onRemove,
    required this.onCancel,
  });

  final SessionBlock block;
  final ValueChanged<SessionBlock> onDone;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  static const String doneLabel = 'DONE';

  SetupCapsule get removeCapsule => SetupCapsule(
    label: 'REMOVE BLOCK',
    semanticsLabel: 'Remove this block',
    onTap: onRemove,
  );
}

/// Shows "SETS REMOVED" with UNDO, which puts the block back where it was.
/// [messenger] is the builder's own, so the bar never outlives the builder:
/// leaving it (START, back, an edit screen) takes the bar with it.
void showBlockRemoved(
  ScaffoldMessengerState messenger,
  SessionDraft draft,
  int index,
  DraftBlock removed,
) {
  final generation = draft.generation;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${removed.block.kind.label} REMOVED'),
        // A bar with an action stays up by default: this one times out
        // after the default four seconds, long enough to take back a swipe.
        persist: false,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () =>
              draft.restore(index, removed, generation: generation),
        ),
      ),
    );
}

/// The edit screen for the builder's block [id]: the same wheels its setup
/// screen uses (a Rest one duration wheel, Sets a count and a rest wheel).
/// It goes by the block's id, so an undo or a reorder in the meantime can
/// never make DONE write over another block.
class BlockEditPage extends ConsumerWidget {
  const BlockEditPage({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(sessionDraftProvider.notifier);
    final entry = draft.entryOf(id);
    if (entry == null) {
      // A stale link (the block went): back to the builder.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.todaysWod);
      });
      return const Scaffold(backgroundColor: AppColors.backgroundDark);
    }
    void back() => context.go(AppRoutes.todaysWod);
    final edit = BlockEdit(
      block: entry.block,
      onCancel: back,
      onDone: (block) {
        draft.replaceById(id, block);
        unawaited(ref.read(sessionStoreProvider).rememberBlock(block));
        back();
      },
      onRemove: () {
        ref.read(hapticServiceProvider).mediumImpact();
        final removed = draft.removeById(id);
        // The builder offers it back (UNDO) when it opens.
        if (removed != null) draft.noteRemoved(removed.index, removed.entry);
        back();
      },
    );
    return switch (edit.block.kind) {
      BlockKind.forTime => ForTimeSetupPage(edit: edit),
      BlockKind.emom => EmomSetupPage(edit: edit),
      BlockKind.amrap => AmrapSetupPage(edit: edit),
      BlockKind.tabata => TabataSetupPage(edit: edit),
      BlockKind.rest => RestSetupPage(edit: edit),
      BlockKind.sets => SetsSetupPage(edit: edit),
    };
  }
}

/// A Rest block's screen: one duration wheel, the rest drawn as a bar.
class RestSetupPage extends ConsumerStatefulWidget {
  const RestSetupPage({required this.edit, super.key});

  final BlockEdit edit;

  @override
  ConsumerState<RestSetupPage> createState() => _RestSetupPageState();
}

class _RestSetupPageState extends ConsumerState<RestSetupPage> {
  late RestBlock _block = widget.edit.block as RestBlock;

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'REST',
      onStart: () => widget.edit.onDone(_block),
      startLabel: BlockEdit.doneLabel,
      capsule: widget.edit.removeCapsule,
      onBack: widget.edit.onCancel,
      body: (context, {required landscape}) => WheelsSetupBody(
        landscape: landscape,
        shape: _block.shape,
        wheels: (rowHeight) => [
          SetupWheel(
            label: 'Rest',
            labelColor: AppColors.rest,
            range: SessionRanges.rest,
            value: _block.seconds,
            format: setupClock,
            spoken: setupSpokenDuration,
            rowHeight: rowHeight,
            onChanged: (v) {
              ref.read(hapticServiceProvider).selectionClick();
              setState(() => _block = RestBlock(seconds: v));
            },
          ),
        ],
      ),
    );
  }
}

/// A Sets block's screen: the set count and the rest between sets.
class SetsSetupPage extends ConsumerStatefulWidget {
  const SetsSetupPage({required this.edit, super.key});

  final BlockEdit edit;

  @override
  ConsumerState<SetsSetupPage> createState() => _SetsSetupPageState();
}

class _SetsSetupPageState extends ConsumerState<SetsSetupPage> {
  late SetsBlock _block = widget.edit.block as SetsBlock;

  void _update(SetsBlock next) {
    ref.read(hapticServiceProvider).selectionClick();
    setState(() => _block = next);
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'SETS',
      onStart: () => widget.edit.onDone(_block),
      startLabel: BlockEdit.doneLabel,
      capsule: widget.edit.removeCapsule,
      onBack: widget.edit.onCancel,
      body: (context, {required landscape}) => WheelsSetupBody(
        landscape: landscape,
        shape: _block.shape,
        midTicks: false,
        wheels: (rowHeight) => [
          SetupWheel(
            label: 'Sets',
            labelColor: AppColors.setsAccent,
            range: SessionRanges.sets,
            value: _block.sets,
            format: (v) => '$v',
            spoken: (v) => '$v',
            rowHeight: rowHeight,
            onChanged: (v) =>
                _update(SetsBlock(sets: v, restSeconds: _block.restSeconds)),
          ),
          SetupWheel(
            label: 'Rest',
            labelColor: AppColors.rest,
            range: SessionRanges.setsRest,
            value: _block.restSeconds,
            format: setupClock,
            spoken: setupSpokenDuration,
            rowHeight: rowHeight,
            onChanged: (v) =>
                _update(SetsBlock(sets: _block.sets, restSeconds: v)),
          ),
        ],
      ),
    );
  }
}
