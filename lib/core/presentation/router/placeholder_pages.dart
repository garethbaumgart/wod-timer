import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

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

/// Signal design home page with hero title and colored sidebar strips.
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

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'WOD',
                style: AppTypography.heroTitle.copyWith(color: Colors.white),
              ),
              TextSpan(
                text: '.',
                style: AppTypography.heroTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Voice-coached gym timer',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryDark,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStrips(BuildContext context, WidgetRef ref) {
    return [
      _SignalStripItem(
        name: 'AMRAP',
        description: 'Max rounds in time',
        accentColor: AppColors.amrapAccent,
        onTap: () {
          ref.read(hapticServiceProvider).lightImpact();
          onTimerSelected('amrap');
        },
      ),
      const SizedBox(height: 12),
      _SignalStripItem(
        name: 'FOR TIME',
        description: 'Race the clock',
        accentColor: AppColors.forTimeAccent,
        onTap: () {
          ref.read(hapticServiceProvider).lightImpact();
          onTimerSelected('fortime');
        },
      ),
      const SizedBox(height: 12),
      _SignalStripItem(
        name: 'EMOM',
        description: 'Every minute on the minute',
        accentColor: AppColors.emomAccent,
        onTap: () {
          ref.read(hapticServiceProvider).lightImpact();
          onTimerSelected('emom');
        },
      ),
      const SizedBox(height: 12),
      _SignalStripItem(
        name: 'TABATA',
        description: 'Work / Rest intervals',
        accentColor: AppColors.tabataAccent,
        onTap: () {
          ref.read(hapticServiceProvider).lightImpact();
          onTimerSelected('tabata');
        },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 20),

          // Timer type strip list
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildStrips(context, ref),
            ),
          ),

          // Bottom icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildSettingsButton(context)],
          ),
        ],
      ),
    );
  }

  /// Landscape gets its own layout (hero left, modes right) — the
  /// portrait column used to overflow here and cut TABATA off entirely.
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStrips(context, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A strip item with colored sidebar line for the Signal design.
class _SignalStripItem extends StatelessWidget {
  const _SignalStripItem({
    required this.name,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  final String name;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name timer. $description. Double tap to select.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              children: [
                // Colored sidebar line
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          name,
                          style: AppTypography.stripName.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      ExcludeSemantics(
                        child: Text(
                          description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing chevron
                const ExcludeSemantics(
                  child: Text(
                    '\u203A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textDisabledDark,
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
