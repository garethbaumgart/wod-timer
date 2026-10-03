import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/router/home_variants.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/content_width_cap.dart';
import 'package:wod_timer/core/presentation/widgets/wordmark.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_stepper.dart';

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

/// Signal design home page: the WOD. title, then one strip per mode showing
/// the setup that mode will open on.
class PlaceholderHomePage extends ConsumerWidget {
  const PlaceholderHomePage({required this.onTimerSelected, super.key});

  /// Callback when a timer type is selected.
  final void Function(String timerType) onTimerSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscape(context, ref);
            }
            return _buildPortrait(context, ref);
          },
        ),
      ),
    );
  }

  Widget _buildHero() => const Wordmark();

  /// One strip per mode, each showing the remembered setup, so Home answers
  /// "what will this start?" before the tap. Read on every build: Home is
  /// rebuilt each time it is navigated back to, after setup saved.
  List<Widget> _buildStrips(
    BuildContext context,
    WidgetRef ref, {
    required double verticalPadding,
  }) {
    final memory = ref.watch(setupMemoryProvider);
    final amrap = memory.amrap;
    final forTime = memory.forTime;
    final emom = memory.emom;
    final tabata = memory.tabata;
    final direction = forTime.countUp ? 'UP' : 'DOWN';

    Widget strip({
      required String name,
      required String config,
      required String spokenConfig,
      required String timerType,
      required Color accentColor,
    }) {
      return _SignalStripItem(
        name: name,
        config: config,
        spokenConfig: spokenConfig,
        accentColor: accentColor,
        verticalPadding: verticalPadding,
        onTap: () {
          ref.read(hapticServiceProvider).lightImpact();
          onTimerSelected(timerType);
        },
      );
    }

    return [
      strip(
        name: 'AMRAP',
        config: setupClock(amrap.durationSeconds),
        spokenConfig: setupSpokenDuration(amrap.durationSeconds),
        timerType: 'amrap',
        accentColor: AppColors.amrapAccent,
      ),
      const SizedBox(height: 12),
      strip(
        name: 'FOR TIME',
        config: 'CAP ${setupClock(forTime.capSeconds)} \u00B7 $direction',
        spokenConfig:
            'Cap ${setupSpokenDuration(forTime.capSeconds)}, '
            'counts ${direction.toLowerCase()}',
        timerType: 'fortime',
        accentColor: AppColors.forTimeAccent,
      ),
      const SizedBox(height: 12),
      strip(
        name: 'EMOM',
        config: '${emom.rounds} \u00D7 ${setupClock(emom.intervalSeconds)}',
        spokenConfig:
            '${emom.rounds} ${emom.rounds == 1 ? 'round' : 'rounds'} of '
            '${setupSpokenDuration(emom.intervalSeconds)}',
        timerType: 'emom',
        accentColor: AppColors.emomAccent,
      ),
      const SizedBox(height: 12),
      strip(
        name: 'TABATA',
        config:
            '${tabata.rounds} \u00D7 ${setupPhase(tabata.workSeconds)} / '
            '${setupPhase(tabata.restSeconds)}',
        spokenConfig:
            '${tabata.rounds} ${tabata.rounds == 1 ? 'round' : 'rounds'}, '
            '${setupSpokenDuration(tabata.workSeconds)} work, '
            '${setupSpokenDuration(tabata.restSeconds)} rest',
        timerType: 'tabata',
        accentColor: AppColors.tabataAccent,
      ),
    ];
  }

  /// Preview only: the four modes for the HOME card variants.
  List<HomeMode> _modes(WidgetRef ref) {
    final memory = ref.watch(setupMemoryProvider);
    final amrap = memory.amrap;
    final forTime = memory.forTime;
    final emom = memory.emom;
    final tabata = memory.tabata;
    void go(String type) {
      ref.read(hapticServiceProvider).lightImpact();
      onTimerSelected(type);
    }

    return [
      HomeMode(
        name: 'FOR TIME',
        config:
            'CAP ${setupClock(forTime.capSeconds)} \u00B7 '
            '${forTime.countUp ? 'UP' : 'DOWN'}',
        accent: AppColors.forTimeAccent,
        onTap: () => go('fortime'),
        shape: [(forTime.capSeconds, false)],
      ),
      HomeMode(
        name: 'EMOM',
        config: '${emom.rounds} \u00D7 ${setupClock(emom.intervalSeconds)}',
        accent: AppColors.emomAccent,
        onTap: () => go('emom'),
        shape: [for (var i = 0; i < emom.rounds; i++) (emom.intervalSeconds, false)],
      ),
      HomeMode(
        name: 'AMRAP',
        config: setupClock(amrap.durationSeconds),
        accent: AppColors.amrapAccent,
        onTap: () => go('amrap'),
        shape: [(amrap.durationSeconds, false)],
      ),
      HomeMode(
        name: 'TABATA',
        config:
            '${tabata.rounds} \u00D7 ${setupPhase(tabata.workSeconds)} / '
            '${setupPhase(tabata.restSeconds)}',
        accent: AppColors.tabataAccent,
        onTap: () => go('tabata'),
        shape: [
          for (var i = 0; i < tabata.rounds; i++) ...[
            (tabata.workSeconds, false),
            (tabata.restSeconds, true),
          ],
        ],
      ),
    ];
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

  Widget _buildPortrait(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 20),
      child: ContentWidthCap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            const SizedBox(height: 20),

            if (homeVariant.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: HomeVariant(
                    variant: homeVariant,
                    modes: _modes(ref),
                  ),
                ),
              )
            else
            // Timer type strip list; scrolls only when large text can't fit.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildStrips(context, ref, verticalPadding: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildSettingsButton(context)],
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape gets its own layout (hero left, modes right): the portrait
  /// column used to overflow here and cut TABATA off entirely. All four
  /// strips fit 844 x 390pt; the scroll view is only a silent fallback.
  Widget _buildLandscape(BuildContext context, WidgetRef ref) {
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
                _buildHero(),
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
            child: ContentWidthCap(
              maxWidth: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStrips(context, ref, verticalPadding: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One mode as a single row: the mode's colour bar, the name in brand
/// orange, and the setup it will open on at the right. The bars came back
/// in 1.3.1 (Gareth liked them); there is still no chevron, the whole strip
/// is the button.
class _SignalStripItem extends StatelessWidget {
  const _SignalStripItem({
    required this.name,
    required this.config,
    required this.spokenConfig,
    required this.accentColor,
    required this.verticalPadding,
    required this.onTap,
  });

  final String name;

  /// The mode's sidebar colour (AMRAP green, For Time blue, EMOM magenta,
  /// Tabata amber).
  final Color accentColor;

  /// Remembered setup as shown ("10 × 1:00").
  final String config;

  /// The same setup the way a screen reader should say it.
  final String spokenConfig;

  final double verticalPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name timer. $spokenConfig. Double tap to select.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  name,
                  style: AppTypography.stripName.copyWith(
                    color: AppColors.brand,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded so large text wraps the config instead of
                // pushing the row off the screen.
                Expanded(
                  child: Text(
                    config,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
