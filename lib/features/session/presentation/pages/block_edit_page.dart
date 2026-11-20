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
void showBlockRemoved(
  ScaffoldMessengerState messenger,
  SessionDraft draft,
  int index,
  DraftBlock removed,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${removed.block.kind.label} REMOVED'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => draft.restore(index, removed),
        ),
      ),
    );
}

/// The edit screen for block [index] of the builder's session: the same
/// wheels its setup screen uses (a Rest one duration wheel, Sets a count
/// and a rest wheel).
class BlockEditPage extends ConsumerWidget {
  const BlockEditPage({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.read(sessionDraftProvider);
    if (index < 0 || index >= entries.length) {
      // A stale link (the block went): back to the builder.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.todaysWod);
      });
      return const Scaffold(backgroundColor: AppColors.backgroundDark);
    }
    final draft = ref.read(sessionDraftProvider.notifier);
    void back() => context.go(AppRoutes.todaysWod);
    final edit = BlockEdit(
      block: entries[index].block,
      onCancel: back,
      onDone: (block) {
        draft.replace(index, block);
        unawaited(ref.read(sessionStoreProvider).rememberBlock(block));
        back();
      },
      onRemove: () {
        ref.read(hapticServiceProvider).mediumImpact();
        final messenger = ScaffoldMessenger.of(context);
        final removed = draft.removeAt(index);
        back();
        if (removed != null) {
          showBlockRemoved(messenger, draft, index, removed);
        }
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
