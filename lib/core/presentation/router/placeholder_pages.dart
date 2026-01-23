import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

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

/// Placeholder home page with timer type selection.
class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({
    required this.onTimerSelected,
    super.key,
  });

  /// Callback when a timer type is selected.
  final void Function(String timerType) onTimerSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            onPressed: () {}, // Will navigate to settings
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select Timer Type',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
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
              ),
            ],
          ),
        ),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              Icon(icon, size: 40, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
