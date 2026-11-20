import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_scaffold.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';
import 'package:wod_timer/preview/todays_wod/preview_end.dart';
import 'package:wod_timer/preview/todays_wod/preview_live.dart';
import 'package:wod_timer/preview/todays_wod/session_widgets.dart';
import 'package:wod_timer/preview/todays_wod/todays_wod_preview.dart';

/// PROTOTYPE ONLY. The prototype's screens, for the app router.
List<GoRoute> todaysWodPreviewRoutes() => [
  GoRoute(
    path: TodaysWodPreview.path(':screen'),
    builder: (context, state) => TodaysWodPreviewScreen(
      // Keyed, so going from one frozen live moment to the next builds a
      // fresh screen.
      key: ValueKey(state.pathParameters['screen']),
      screen: state.pathParameters['screen'] ?? 'builder',
    ),
  ),
];

/// PROTOTYPE ONLY. One prototype screen by name, drawn from fixed numbers.
/// The controls only step to the next screen of the story.
class TodaysWodPreviewScreen extends StatelessWidget {
  const TodaysWodPreviewScreen({required this.screen, super.key});

  final String screen;

  static const Color _amber = Color(0xFFFFB800);

  /// The Sets block as a timeline: five sets with a 2:00 rest between them.
  /// A set has no length of its own; it is drawn a minute wide.
  static const _setsShape = WorkoutShape(
    parts: [
      TimelinePart(60),
      TimelinePart(120, rest: true),
      TimelinePart(60),
      TimelinePart(120, rest: true),
      TimelinePart(60),
      TimelinePart(120, rest: true),
      TimelinePart(60),
      TimelinePart(120, rest: true),
      TimelinePart(60),
    ],
    accent: _amber,
  );

  /// Sets 1 and 2 with their rests, and set 3 under way.
  static const double _throughSetThree = 420;

  @override
  Widget build(BuildContext context) {
    void go(String next) => context.go(TodaysWodPreview.path(next));
    void home() => context.go(AppRoutes.home);

    SlabCell pause() => SlabCell(
      label: 'PAUSE',
      background: AppColors.soft,
      foreground: Colors.white,
      onTap: () {},
      semanticsLabel: 'Pause button',
    );

    return switch (screen) {
      'live' => PreviewLiveScreen(
        block: 2,
        line: 'BLOCK 3 OF 5 · NEXT REST 2:00',
        clock: '56',
        clockReference: '60',
        clockColor: AppColors.emomAccent,
        second: const SecondLine.big('2/10'),
        shape: WorkoutShape.emom(intervalSeconds: 60, rounds: 10),
        elapsedSeconds: 64,
        slab: [pause()],
        onCanvasTap: () => go('get-ready'),
      ),
      'get-ready' => PreviewLiveScreen(
        block: 4,
        line: 'BLOCK 5 OF 5 · TAP TO SKIP',
        phase: ('GET READY', AppColors.prepare),
        clock: '7',
        clockReference: '12:00',
        clockColor: AppColors.prepare,
        second: const SecondLine.word(
          'NEXT · AMRAP 12:00',
          AppColors.amrapAccent,
        ),
        shape: WorkoutShape.amrap(720),
        elapsedSeconds: 0,
        slab: [
          HoldToStopCell(
            enabled: true,
            showHint: false,
            onConfirmed: home,
            onShortPress: () {},
          ),
        ],
        onCanvasTap: () => go('end'),
      ),
      'sets-work' => PreviewLiveScreen(
        block: 0,
        line: 'BLOCK 1 OF 5 · NEXT REST 3:00',
        phase: ('SET', _amber),
        clock: '3/5',
        clockReference: '2:00',
        clockColor: _amber,
        // Always a second line in this block (here, and TAP TO SKIP in
        // its rests), so the timeline under it never moves between them.
        second: const SecondLine.hint('THEN REST 2:00'),
        shape: _setsShape,
        elapsedSeconds: _throughSetThree,
        slab: [
          SlabCell(
            label: 'SET DONE',
            background: _amber,
            foreground: Colors.black,
            onTap: () => go('sets-rest'),
            semanticsLabel: 'Set done. Starts the rest.',
          ),
          pause(),
        ],
      ),
      'sets-rest' => PreviewLiveScreen(
        block: 0,
        line: 'BLOCK 1 OF 5 · NEXT REST 3:00',
        phase: ('REST · SET 4 NEXT', AppColors.rest),
        clock: '1:24',
        clockReference: '2:00',
        clockColor: AppColors.rest,
        second: const SecondLine.hint('TAP TO SKIP'),
        shape: _setsShape,
        elapsedSeconds: _throughSetThree + 36,
        slab: [pause()],
        onCanvasTap: () => go('live'),
      ),
      'end' => PreviewEndScreen(
        time: '41:36',
        results: const [
          BlockResult(BlockKind.sets, '5'),
          BlockResult(BlockKind.emom, '10', unit: 'ROUNDS'),
          BlockResult(BlockKind.amrap, '7', unit: 'ROUNDS'),
        ],
        onAgain: () => go('sets-work'),
        onDone: home,
      ),
      _ => const SessionBuilderPage(),
    };
  }
}

/// PROTOTYPE ONLY. The session builder, in the setup screens' frame: the
/// blocks as rows (colour bar, name in its colour, setup, drag handle),
/// "+ ADD BLOCK", the session's strip, and START carrying the total.
class SessionBuilderPage extends StatelessWidget {
  const SessionBuilderPage({super.key});

  static const double _rowSpacing = 8;
  static const double _stripHeight = 12;

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: "TODAY'S WOD",
      onStart: () => context.go(TodaysWodPreview.path('sets-work')),
      startSubtitle: 'About 42 min',
      body: (context, {required landscape}) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              spacing: _rowSpacing,
              children: [
                for (final block in TodaysWodPreview.blocks)
                  BlockRow(
                    kind: block.kind,
                    detail: block.detail,
                    trailing: const SizedBox(
                      width: 44,
                      height: BlockRow.height,
                      child: Icon(
                        Icons.drag_handle,
                        size: 24,
                        color: AppColors.textDisabledDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PreviewCapsule(
            label: '+ ADD BLOCK',
            onTap: () => showAddBlockSheet(context),
          ),
          const Expanded(
            child: CentredTimeline(
              // The capsule's filled box is the lowest ink above.
              aboveInkInset: 0,
              height: _stripHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SessionStrip(height: _stripHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PROTOTYPE ONLY. The add-block sheet: the four timers in Home order,
/// then Rest and Sets, each in its colour with the setup it would add (the
/// mode's last values). Dressed as the voice picker sheet.
Future<void> showAddBlockSheet(BuildContext context) {
  const choices = [
    (BlockKind.forTime, 'CAP 20:00'),
    (BlockKind.emom, '10 × 1:00'),
    (BlockKind.amrap, '10:00'),
    (BlockKind.tabata, '8 × 20s / 10s'),
    (BlockKind.rest, '2:00'),
    (BlockKind.sets, '5 · REST 2:00'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
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
                  for (final (kind, detail) in choices)
                    BlockRow(
                      kind: kind,
                      detail: detail,
                      detailColor: AppColors.textSecondaryDark,
                      onTap: () => Navigator.pop(sheetContext),
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
