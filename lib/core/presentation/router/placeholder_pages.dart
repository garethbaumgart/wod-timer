import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/features/timer/application/providers/recent_workouts_provider.dart';

/// Placeholder page for routes that haven't been implemented yet.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    super.key,
    this.subtitle,
  });

  /// The page title.
  final String title;

  /// Optional subtitle or description.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
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
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Coming Soon',
                style: theme.textTheme.labelLarge?.copyWith(
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

/// Placeholder home page with timer type selection and recent workouts.
class PlaceholderHomePage extends ConsumerWidget {
  const PlaceholderHomePage({
    required this.onTimerSelected,
    super.key,
  });

  /// Callback when a timer type is selected.
  final void Function(String timerType) onTimerSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentWorkouts = ref.watch(recentWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WOD Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {}, // Will navigate to presets
            tooltip: 'Presets',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recent workouts section
              if (recentWorkouts.isNotEmpty) ...[
                _buildRecentWorkoutsSection(context, recentWorkouts),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Timer type selection
              Text(
                'Select Timer Type',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _TimerTypeCard(
                    title: 'AMRAP',
                    subtitle: 'As Many Rounds\nAs Possible',
                    icon: Icons.loop,
                    color: AppColors.primary,
                    onTap: () => onTimerSelected('amrap'),
                  ),
                  _TimerTypeCard(
                    title: 'FOR TIME',
                    subtitle: 'Complete Work\nAs Fast As Possible',
                    icon: Icons.timer,
                    color: AppColors.secondary,
                    onTap: () => onTimerSelected('fortime'),
                  ),
                  _TimerTypeCard(
                    title: 'EMOM',
                    subtitle: 'Every Minute\nOn the Minute',
                    icon: Icons.av_timer,
                    color: AppColors.success,
                    onTap: () => onTimerSelected('emom'),
                  ),
                  _TimerTypeCard(
                    title: 'TABATA',
                    subtitle: '20s Work\n10s Rest',
                    icon: Icons.fitness_center,
                    color: AppColors.warning,
                    onTap: () => onTimerSelected('tabata'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsSection(
    BuildContext context,
    List<RecentWorkout> recents,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Recent',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recents.map(
          (recent) => _RecentWorkoutTile(
            recent: recent,
            onTap: () {
              HapticFeedback.lightImpact();
              onTimerSelected(recent.timerType);
            },
          ),
        ),
      ],
    );
  }
}

class _RecentWorkoutTile extends StatelessWidget {
  const _RecentWorkoutTile({
    required this.recent,
    required this.onTap,
  });

  final RecentWorkout recent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            recent.icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          recent.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          recent.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}

class _TimerTypeCard extends StatelessWidget {
  const _TimerTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$title timer. ${subtitle.replaceAll('\n', ' ')}. Double tap to select.',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: 4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 40, color: color)),
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                ExcludeSemantics(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
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
