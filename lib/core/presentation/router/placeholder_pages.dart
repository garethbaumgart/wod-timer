import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/content_width_cap.dart';
import 'package:wod_timer/core/presentation/widgets/wordmark.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_stepper.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// Placeholder page for routes that haven't been implemented yet.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key, this.subtitle});

  /// The page title.
  final String title;

  /// Optional subtitle or description.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.workoutTitle.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Coming Soon',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One mode as Home shows it: the remembered setup, in words and as a
/// timeline.
class HomeMode {
  const HomeMode({
    required this.name,
    required this.config,
    required this.spokenConfig,
    required this.timerType,
    required this.shape,
  });

  final String name;

  /// Remembered setup as shown ("10 × 1:00").
  final String config;

  /// The same setup the way a screen reader should say it.
  final String spokenConfig;

  final String timerType;
  final WorkoutShape shape;

  Color get accent => shape.accent;
  int get totalSeconds => shape.totalSeconds;
}

/// Home (1.3.1): the stacked wordmark, then every mode as a card showing
/// the setup it will open on, drawn as a timeline. Phones list the four
/// cards; tablets put the last mode started in a big tile across the top
/// and the other three in a row below.
class PlaceholderHomePage extends ConsumerWidget {
  const PlaceholderHomePage({required this.onTimerSelected, super.key});

  /// Callback when a timer type is selected.
  final void Function(String timerType) onTimerSelected;

  /// Logical shortest side (under TabletScale) from which Home uses tiles.
  static const double tabletShortestSide = 560;

  /// The modes in Home order: For Time, EMOM, AMRAP, Tabata.
  static List<HomeMode> modesOf(SetupMemory memory) {
    final amrap = memory.amrap;
    final forTime = memory.forTime;
    final emom = memory.emom;
    final tabata = memory.tabata;
    final direction = forTime.countUp ? 'UP' : 'DOWN';
    return [
      HomeMode(
        name: 'FOR TIME',
        config: 'CAP ${setupClock(forTime.capSeconds)} · $direction',
        spokenConfig:
            'Cap ${setupSpokenDuration(forTime.capSeconds)}, '
            'counts ${direction.toLowerCase()}',
        timerType: TimerTypes.forTime,
        shape: WorkoutShape.ofSetup(forTime),
      ),
      HomeMode(
        name: 'EMOM',
        config: '${emom.rounds} × ${setupClock(emom.intervalSeconds)}',
        spokenConfig:
            '${emom.rounds} ${emom.rounds == 1 ? 'round' : 'rounds'} of '
            '${setupSpokenDuration(emom.intervalSeconds)}',
        timerType: TimerTypes.emom,
        shape: WorkoutShape.ofSetup(emom),
      ),
      HomeMode(
        name: 'AMRAP',
        config: setupClock(amrap.durationSeconds),
        spokenConfig: setupSpokenDuration(amrap.durationSeconds),
        timerType: TimerTypes.amrap,
        shape: WorkoutShape.ofSetup(amrap),
      ),
      HomeMode(
        name: 'TABATA',
        config:
            '${tabata.rounds} × ${setupPhase(tabata.workSeconds)} / '
            '${setupPhase(tabata.restSeconds)}',
        spokenConfig:
            '${tabata.rounds} ${tabata.rounds == 1 ? 'round' : 'rounds'}, '
            '${setupSpokenDuration(tabata.workSeconds)} work, '
            '${setupSpokenDuration(tabata.restSeconds)} rest',
        timerType: TimerTypes.tabata,
        shape: WorkoutShape.ofSetup(tabata),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read on every build: Home is rebuilt each time it is navigated back
    // to, after setup saved.
    final memory = ref.watch(setupMemoryProvider);
    final modes = modesOf(memory);
    final size = MediaQuery.sizeOf(context);
    final tablet = size.shortestSide >= tabletShortestSide;
    final landscape = size.width > size.height;

    void select(String type) {
      ref.read(hapticServiceProvider).lightImpact();
      onTimerSelected(type);
    }

    final Widget cards = tablet
        ? _HomeTiles(modes: modes, lastMode: memory.lastMode, onSelect: select)
        : _HomeCards(modes: modes, compact: landscape, onSelect: select);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: landscape
            ? _buildLandscape(context, cards, tablet: tablet)
            : _buildPortrait(context, cards, tablet: tablet),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.settings_outlined,
        color: AppColors.textSecondaryDark,
        size: 28,
      ),
      onPressed: () => context.go(AppRoutes.settings),
      tooltip: 'Settings',
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    Widget cards, {
    required bool tablet,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 20),
      child: ContentWidthCap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wordmark(),
            const SizedBox(height: 20),
            Expanded(
              child: tablet
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: cards,
                    )
                  : cards,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildSettingsButton(context)],
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape: wordmark column left, the cards or tiles right. All four
  /// phone cards fit 844 x 390pt without the total line.
  Widget _buildLandscape(
    BuildContext context,
    Widget cards, {
    required bool tablet,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Wordmark(),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSettingsButton(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: tablet
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: cards,
                  )
                : ContentWidthCap(maxWidth: 520, child: cards),
          ),
        ],
      ),
    );
  }
}

TextStyle _nameStyle(double size) => AppTypography.stripName.copyWith(
  color: AppColors.textPrimaryDark,
  fontSize: size,
  fontWeight: FontWeight.w900,
  height: 1,
);

TextStyle _configStyle(double size, {FontWeight weight = FontWeight.w700}) =>
    AppTypography.bodyLarge.copyWith(
      color: AppColors.textPrimaryDark,
      fontSize: size,
      fontWeight: weight,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _mutedStyle(double size) => AppTypography.bodyLarge.copyWith(
  color: AppColors.textSecondaryDark,
  fontSize: size,
  fontWeight: FontWeight.w600,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

Widget _bar(Color color, {required double width, double? height}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(width / 2),
  ),
);

Widget _fitLeft(Widget child) => FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: child,
);

/// The whole card is the button; no chevron.
class _HomeTap extends StatelessWidget {
  const _HomeTap({
    required this.mode,
    required this.radius,
    required this.onTap,
    required this.child,
  });

  final HomeMode mode;
  final double radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${mode.name} timer. ${mode.spokenConfig}. Double tap to select.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              color: Colors.white.withValues(alpha: 0.035),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Phone: full-width cards, centred in the space, scrolling only when
/// large text can't fit.
class _HomeCards extends StatelessWidget {
  const _HomeCards({
    required this.modes,
    required this.compact,
    required this.onSelect,
  });

  final List<HomeMode> modes;

  /// Landscape: no total line, an 8pt timeline, tighter padding.
  final bool compact;
  final void Function(String timerType) onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: compact ? 10 : 14,
            children: [
              for (final mode in modes)
                _HomeCard(
                  mode: mode,
                  compact: compact,
                  onTap: () => onSelect(mode.timerType),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One phone card: 4pt mode-colour bar, white name 28, setup right-aligned
/// 18, the timeline under, "10:00 total" right-aligned 13 grey under that.
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.mode,
    required this.compact,
    required this.onTap,
  });

  final HomeMode mode;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeTap(
      mode: mode,
      radius: 14,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _bar(mode.accent, width: 4, height: 30),
                const SizedBox(width: 14),
                // Halves, so large text shrinks the name and wraps the
                // setup instead of pushing the row off the card.
                Expanded(
                  child: _fitLeft(Text(mode.name, style: _nameStyle(28))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mode.config,
                    textAlign: TextAlign.end,
                    style: _configStyle(18),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 14),
            WorkoutTimeline(shape: mode.shape, height: compact ? 8 : 12),
            if (!compact) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${setupClock(mode.totalSeconds)} total',
                  style: _mutedStyle(13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tablet: the last mode started as a big tile across the top, the other
/// three in a row below in Home order.
class _HomeTiles extends StatelessWidget {
  const _HomeTiles({
    required this.modes,
    required this.lastMode,
    required this.onSelect,
  });

  final List<HomeMode> modes;
  final String lastMode;
  final void Function(String timerType) onSelect;

  @override
  Widget build(BuildContext context) {
    final hero = modes.firstWhere(
      (m) => m.timerType == lastMode,
      orElse: () => modes.first,
    );
    final rest = modes.where((m) => m != hero).toList();
    return Column(
      spacing: 14,
      children: [
        Expanded(
          flex: 5,
          child: _HomeTile(
            mode: hero,
            big: true,
            onTap: () => onSelect(hero.timerType),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            spacing: 14,
            children: [
              for (final mode in rest)
                Expanded(
                  child: _HomeTile(
                    mode: mode,
                    big: false,
                    onTap: () => onSelect(mode.timerType),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One tablet tile: bar, white name, setup, timeline, total.
class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.mode, required this.big, required this.onTap});

  final HomeMode mode;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeTap(
      mode: mode,
      radius: 18,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(mode.accent, width: 6),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fitLeft(Text(mode.name, style: _nameStyle(big ? 44 : 32))),
                  const Spacer(),
                  _fitLeft(
                    Text(
                      mode.config,
                      style: _configStyle(
                        big ? 40 : 32,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WorkoutTimeline(shape: mode.shape, height: 14),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${setupClock(mode.totalSeconds)} total',
                      style: _mutedStyle(big ? 18 : 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
