import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/pages/block_edit_page.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_scaffold.dart';

/// Today's WOD's builder (2.6.0), in the setup screens' frame: the blocks
/// as rows (colour bar, name in its colour, setup, drag handle), "+ ADD
/// BLOCK", the session's strip, and START carrying the total. Tap a row to
/// edit it, drag its handle to move it, swipe it away to remove it.
class SessionBuilderPage extends ConsumerStatefulWidget {
  const SessionBuilderPage({super.key, this.openAddSheet = false});

  /// Opens with the add sheet up ("+ THEN", "+ NEW").
  final bool openAddSheet;

  static const double rowSpacing = 8;
  static const double stripHeight = 12;

  /// The capsule under the rows, with its gap.
  static const double _capsuleBlock = 16 + SessionCapsule.defaultHeight;

  /// The least room the strip keeps under the capsule.
  static const double _minStripZone = stripHeight + 2 * 12;

  @override
  ConsumerState<SessionBuilderPage> createState() => _SessionBuilderPageState();
}

class _SessionBuilderPageState extends ConsumerState<SessionBuilderPage> {
  bool _starting = false;

  /// The builder's own messenger: the removed bar lives and dies with the
  /// builder, so it never rides onto an edit screen, Home or a live screen.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A block removed on its edit screen: offer it back here.
      final removed = ref.read(sessionDraftProvider.notifier).takeRemoved();
      final messenger = _messenger.currentState;
      if (removed != null && messenger != null && mounted) {
        showBlockRemoved(
          messenger,
          ref.read(sessionDraftProvider.notifier),
          removed.index,
          removed.entry,
        );
      }
    });
    if (widget.openAddSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAddSheet(context);
      });
    }
  }

  Future<void> _onStart() async {
    if (_starting) return;
    final session = ref.read(sessionDraftProvider.notifier).session;
    if (!session.isRunnable) return;
    _starting = true;
    try {
      await ref.read(sessionStoreProvider).saveLastSession(session);
      await ref.read(todaysWodProvider.notifier).start(session);
      if (!mounted) return;
      context.go(AppRoutes.todaysWodActive);
    } finally {
      _starting = false;
    }
  }

  void _remove(int index) {
    final draft = ref.read(sessionDraftProvider.notifier);
    final removed = draft.removeAt(index);
    if (removed == null) return;
    ref.read(hapticServiceProvider).mediumImpact();
    final messenger = _messenger.currentState;
    if (messenger != null) showBlockRemoved(messenger, draft, index, removed);
  }

  /// The add sheet takes the removed bar down first.
  void _openAddSheet(BuildContext context) {
    _messenger.currentState?.removeCurrentSnackBar();
    showAddBlockSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(sessionDraftProvider);
    final session = WodSession([for (final e in entries) e.block]);
    final minutes = session.aboutMinutes(
      getReadySeconds: TodaysWodController.getReadySeconds,
    );
    return ScaffoldMessenger(
      key: _messenger,
      child: SetupScaffold(
        title: "TODAY'S WOD",
        onStart: _onStart,
        startEnabled: session.isRunnable,
        startSubtitle: session.isEmpty ? null : 'About $minutes min',
        body: (context, {required landscape}) =>
            _buildBody(context, entries, session, landscape: landscape),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DraftBlock> entries,
    WodSession session, {
    required bool landscape,
  }) {
    final full = entries.length >= WodSession.maxBlocks;
    final list = _BlockList(
      entries: entries,
      onEdit: (index) =>
          context.go(AppRoutes.todaysWodBlockPath(entries[index].id)),
      onRemove: _remove,
    );
    final capsule = full
        ? const SizedBox(height: SessionCapsule.defaultHeight)
        : SessionCapsule(
            label: '+ ADD BLOCK',
            semanticsLabel: 'Add a block',
            onTap: () => _openAddSheet(context),
          );
    if (landscape) {
      // Held sideways the rows get the whole height (three or more on a
      // phone); "+ ADD BLOCK" and the strip sit beside them.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: list),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  capsule,
                  if (!session.isEmpty)
                    SessionStrip(
                      blocks: session.blocks,
                      height: SessionBuilderPage.stripHeight,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowsMax = math.max(
          BlockRow.height,
          constraints.maxHeight -
              SessionBuilderPage._capsuleBlock -
              SessionBuilderPage._minStripZone,
        );
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: rowsMax),
              child: list,
            ),
            const SizedBox(height: 16),
            capsule,
            Expanded(
              child: session.isEmpty
                  ? const SizedBox.shrink()
                  : CentredTimeline(
                      // The capsule's filled box is the lowest ink above.
                      aboveInkInset: 0,
                      height: SessionBuilderPage.stripHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SessionStrip(
                          blocks: session.blocks,
                          height: SessionBuilderPage.stripHeight,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The rows: drag a handle to move one, swipe one away to remove it.
class _BlockList extends ConsumerWidget {
  const _BlockList({
    required this.entries,
    required this.onEdit,
    required this.onRemove,
  });

  final List<DraftBlock> entries;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      onReorderStart: (_) => ref.read(hapticServiceProvider).selectionClick(),
      onReorderItem: (from, to) =>
          ref.read(sessionDraftProvider.notifier).move(from, to),
      // The lifted row keeps its dress, no Material shadow box.
      proxyDecorator: (child, _, _) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          key: ValueKey(entry.id),
          padding: EdgeInsets.only(
            bottom: index == entries.length - 1
                ? 0
                : SessionBuilderPage.rowSpacing,
          ),
          child: Dismissible(
            key: ValueKey('dismiss-${entry.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onRemove(index),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.stopSlab,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'REMOVE',
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.stopRed,
                  fontSize: 17,
                  letterSpacing: 17 * 0.06,
                ),
              ),
            ),
            child: BlockRow(
              block: entry.block,
              semanticsHint:
                  'Block ${index + 1} of ${entries.length}. '
                  'Double tap to edit. Swipe left to remove.',
              onTap: () => onEdit(index),
              trailing: ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Drag to move',
                  child: const SizedBox(
                    width: 44,
                    height: BlockRow.height,
                    child: Icon(
                      Icons.drag_handle,
                      size: 24,
                      color: AppColors.textDisabledDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The add-block sheet: the four timers in Home order, then Rest and Sets,
/// each in its colour with the setup it would add (its last values).
/// Dressed as the voice picker sheet.
Future<void> showAddBlockSheet(BuildContext context, WidgetRef ref) {
  ref.read(hapticServiceProvider).selectionClick();
  final store = ref.read(sessionStoreProvider);
  final choices = [
    for (final kind in BlockKind.values) store.lastBlockOf(kind),
  ];
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      // Scrollable so the sheet never overflows held sideways.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Add block',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              Column(
                spacing: 8,
                children: [
                  for (final block in choices)
                    BlockRow(
                      block: block,
                      detailColor: AppColors.textSecondaryDark,
                      semanticsHint: 'Double tap to add.',
                      onTap: () {
                        ref.read(hapticServiceProvider).selectionClick();
                        ref.read(sessionDraftProvider.notifier).add(block);
                        Navigator.pop(sheetContext);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
