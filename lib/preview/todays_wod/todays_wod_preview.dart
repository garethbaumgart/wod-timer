import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';

/// PROTOTYPE ONLY ("Today's WOD", 20 Nov 2026). Nothing in this folder
/// ships: it draws a proposed feature with fixed numbers so it can be judged
/// on the real screens. There is no session engine, no persistence and no
/// audio behind any of it.
///
/// Off unless the app is built with `--dart-define=PREVIEW_SESSION=1` (or a
/// screen name from [screens], which also opens the app on that screen), or
/// a capture test sets [enabled] before `main()`. With it off, a normal
/// launch is unchanged.
abstract class TodaysWodPreview {
  static const String _define = String.fromEnvironment('PREVIEW_SESSION');

  /// Whether Home and setup show the prototype's entry points, and the
  /// router carries the prototype's screens.
  static bool enabled = _define.isNotEmpty;

  /// The static screens, by route name.
  static const screens = [
    'builder',
    'live',
    'get-ready',
    'sets-work',
    'sets-rest',
    'end',
  ];

  static String path(String screen) => '/preview/todays-wod/$screen';

  /// Where the app opens when the define names a screen.
  static String? get initialLocation =>
      screens.contains(_define) ? path(_define) : null;

  /// The one session every prototype screen shows.
  static const blocks = [
    WodBlock(
      BlockKind.sets,
      detail: '5 · REST 2:00',
      summary: 'Sets 5',
      minutes: 15,
    ),
    WodBlock(BlockKind.rest, detail: '3:00', minutes: 3),
    WodBlock(
      BlockKind.emom,
      detail: '10 × 1:00',
      summary: 'EMOM 10',
      minutes: 10,
    ),
    WodBlock(BlockKind.rest, detail: '2:00', minutes: 2),
    WodBlock(
      BlockKind.amrap,
      detail: '12:00',
      summary: 'AMRAP 12',
      minutes: 12,
    ),
  ];

  static const String total = 'about 42 min';

  /// The session's own colour (its end-screen hero, AGAIN): brand green,
  /// the colour of START and of WOD in the wordmark.
  static const Color sessionAccent = AppColors.primary;
}

/// What a block can be: one of the four timers, a rest, or sets.
enum BlockKind {
  forTime('FOR TIME', AppColors.forTimeAccent),
  emom('EMOM', AppColors.emomAccent),
  amrap('AMRAP', AppColors.amrapAccent),
  tabata('TABATA', AppColors.tabataAccent),

  /// Dim rest pink, so a rest never reads as an EMOM (same pink, full).
  rest('REST', Color(0xFF7A1F4D), Color(0xFFC7528D)),

  /// The new block colour.
  sets('SETS', Color(0xFFFFB800));

  const BlockKind(this.label, this.color, [this._text]);

  final String label;

  /// Bars and strip segments.
  final Color color;

  final Color? _text;

  /// The name as text: [color], lifted where that is too dim to read.
  Color get textColor => _text ?? color;
}

/// One block of the session.
@immutable
class WodBlock {
  const WodBlock(
    this.kind, {
    required this.detail,
    required this.minutes,
    this.summary,
  });

  final BlockKind kind;

  /// The setup in the app's words ("10 × 1:00").
  final String detail;

  /// Roughly how long it runs: the strip's flex.
  final int minutes;

  /// How Home's repeat row names it ("EMOM 10"); null leaves it out
  /// (rests).
  final String? summary;
}
