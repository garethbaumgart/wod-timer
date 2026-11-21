import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

/// Home's "TODAY'S WOD" card (2.6.0), above the four modes, in the mode
/// cards' dress. With a last session: its blocks named in their colours,
/// its strip, how long it runs, and "+ NEW"; the card repeats it. Without
/// one: "TODAY'S WOD" and "+ NEW" over one line inviting her to chain
/// timers, which fits an iPhone SE at its size.
class TodaysWodCard extends ConsumerWidget {
  const TodaysWodCard({super.key, this.compact = false});

  /// Landscape: tighter padding and a thinner strip.
  final bool compact;

  /// Home's top and bottom padding on a phone held upright (50 and 20
  /// before 2.6.0), so the card and all four mode cards fit a 6.3in phone
  /// without scrolling.
  static const double homeTopPadding = 16;
  static const double homeBottomPadding = 8;

  static const double _chipHeight = 24;

  /// Box gaps that leave 15pt between the glyphs: the label's capitals to
  /// the summary's, and the summary's baseline to the strip (measured on
  /// the 3x capture of the approved mock).
  static const double _labelToSummary = 6.5;
  static const double _summaryToStrip = 12.5;

  static TextStyle get _label => AppTypography.labelSmall.copyWith(
    color: AppColors.textPrimaryDark,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 13 * 0.14,
    height: 1,
  );

  static TextStyle get _muted => AppTypography.bodyLarge.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get _summary => AppTypography.bodyLarge.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// The card caps the system text size the way the end screen's tiles
  /// do, so the largest accessibility size never overflows Home.
  static const double maxTextScale = 1.4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: maxTextScale),
      ),
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    // Read on every build, as Home reads setup memory: Home is rebuilt each
    // time it is navigated back to, after START saved a session.
    final last = ref.watch(sessionStoreProvider).lastSession;

    void openBuilder(List<SessionBlock> blocks, BuilderSource source) {
      ref.read(hapticServiceProvider).lightImpact();
      ref.read(sessionDraftProvider.notifier).open(blocks, source);
      context.go(
        AppRoutes.todaysWodPath(addBlock: source == BuilderSource.home),
      );
    }

    void newSession() => openBuilder(const [], BuilderSource.home);
    final minutes = last?.aboutMinutes(
      getReadySeconds: TodaysWodController.getReadySeconds,
    );

    return Semantics(
      button: true,
      label: last == null
          ? "Today's WOD. Chain timers into one session. Double tap to "
                'build one.'
          : "Today's WOD, about $minutes minutes: "
                '${last.blocks.map((b) => b.spoken).join('; ')}. '
                'Double tap to repeat it.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: last == null
              ? newSession
              : () => openBuilder(last.blocks, BuilderSource.repeat),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              color: Colors.white.withValues(alpha: 0.035),
            ),
            child: Padding(
              // 15pt from the card's edge (its 1pt border included) to the
              // chip above and the strip below, the gap the rows keep.
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 10 : 14,
                16,
                compact ? 10 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(
                    context,
                    note: last == null ? null : 'about $minutes min',
                    onNew: newSession,
                  ),
                  if (last == null) ...[
                    const SizedBox(height: _labelToSummary),
                    Text(invite, maxLines: 1, softWrap: false, style: _invite),
                  ],
                  if (last != null) ...[
                    const SizedBox(height: _labelToSummary),
                    _repeatLine(last),
                    SizedBox(height: compact ? 8 : _summaryToStrip),
                    SessionStrip(blocks: last.blocks, height: compact ? 8 : 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The empty card's invitation: terse capitals, one line on an SE.
  static const invite = 'CHAIN TIMERS INTO ONE SESSION';

  static TextStyle get _invite => _muted.copyWith(fontWeight: FontWeight.w700);

  /// "TODAY'S WOD", the note, "+ NEW". Grows with large text.
  Widget _header(
    BuildContext context, {
    required String? note,
    required VoidCallback onNew,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _chipHeight * scale),
      child: Row(
        children: [
          // The label whole with the note after it where there is room; in
          // a narrow card (the wordmark's column held sideways) the note
          // goes first and the label shrinks rather than overflowing.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const label = Text("TODAY'S WOD", maxLines: 1);
                final labelWidth = GlyphInk.boxWidth(
                  "TODAY'S WOD",
                  GlyphInk.resolve(context, _label),
                  textScaler: MediaQuery.textScalerOf(context),
                );
                if (labelWidth > constraints.maxWidth) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle.merge(style: _label, child: label),
                  );
                }
                return Row(
                  children: [
                    Text("TODAY'S WOD", maxLines: 1, style: _label),
                    const SizedBox(width: 10),
                    Expanded(
                      child: note == null
                          ? const SizedBox.shrink()
                          : _Note(note, style: _muted),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          _NewChip(height: _chipHeight * scale, onTap: onNew),
        ],
      ),
    );
  }

  Widget _repeatLine(WodSession last) {
    final named = [
      for (final block in last.blocks)
        if (block.summary != null) block,
    ];
    return Row(
      children: [
        // The glyph sits 3.3pt inside its box: pulled left so its ink
        // starts on the strip's edge.
        Transform.translate(
          offset: const Offset(-3.3, 0),
          child: const Icon(
            Icons.replay,
            size: 20,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (i, block) in named.indexed) ...[
                    if (i > 0) const TextSpan(text: '  ·  '),
                    TextSpan(
                      text: block.summary,
                      style: TextStyle(color: block.kind.textColor),
                    ),
                  ],
                  // A session of rests only still says what it is.
                  if (named.isEmpty)
                    TextSpan(
                      text: 'Rest',
                      style: TextStyle(color: BlockKind.rest.textColor),
                    ),
                ],
              ),
              maxLines: 1,
              style: _summary,
            ),
          ),
        ),
      ],
    );
  }
}

/// "+ NEW": the setup voice chip's outline, smaller.
class _NewChip extends StatelessWidget {
  const _NewChip({required this.height, required this.onTap});

  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Build a new Today's WOD",
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              '+ NEW',
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
                letterSpacing: 1,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "about 41 min": whole where it fits, shrunk no smaller than
/// [minReadable] where it nearly does, and left out where it cannot be
/// read (a narrow card held sideways at large text).
class _Note extends StatelessWidget {
  const _Note(this.text, {required this.style});

  final String text;
  final TextStyle style;

  /// The smallest the note is ever drawn, in points.
  static const double minReadable = 11;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final natural = GlyphInk.boxWidth(
          text,
          GlyphInk.resolve(context, style),
          textScaler: scaler,
        );
        final label = Text(text, maxLines: 1, style: style);
        if (natural <= constraints.maxWidth) return label;
        final shown =
            scaler.scale(style.fontSize!) * constraints.maxWidth / natural;
        if (shown < minReadable) return const SizedBox.shrink();
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: label,
        );
      },
    );
  }
}
