import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/package_info_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';

/// Settings page for configuring app preferences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Display Section
          _buildSectionHeader(context, 'Display', isDark),
          _buildOrientationLockTile(context, ref, settings, isDark),
          _buildSwitchTile(
            context: context,
            title: 'Keep Screen On',
            subtitle: 'Prevent screen from sleeping during workouts',
            icon: Icons.brightness_high,
            value: settings.keepScreenOn,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref
                  .read(appSettingsNotifierProvider.notifier)
                  .setKeepScreenOn(enabled: value);
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Audio & Haptic Section
          _buildSectionHeader(context, 'Feedback', isDark),
          _buildSwitchTile(
            context: context,
            title: 'Sound Effects',
            subtitle: 'Play audio cues for countdown and phase changes',
            icon: Icons.volume_up,
            value: settings.soundEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref
                  .read(appSettingsNotifierProvider.notifier)
                  .setSoundEnabled(enabled: value);
            },
            isDark: isDark,
          ),
          _buildSwitchTile(
            context: context,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on timer events and interactions',
            icon: Icons.vibration,
            value: settings.hapticEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref
                  .read(appSettingsNotifierProvider.notifier)
                  .setHapticEnabled(enabled: value);
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xl),

          // About Section
          _buildSectionHeader(context, 'About', isDark),
          _buildVersionTile(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildOrientationLockTile(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.screen_rotation,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          'Orientation Lock',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getOrientationLabel(settings.orientationLock),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showOrientationPicker(context, ref, settings),
      ),
    );
  }

  String _getOrientationLabel(OrientationLockMode mode) {
    switch (mode) {
      case OrientationLockMode.auto:
        return 'Auto (follow device)';
      case OrientationLockMode.portrait:
        return 'Portrait only';
      case OrientationLockMode.landscape:
        return 'Landscape only';
    }
  }

  void _showOrientationPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Orientation Lock',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...OrientationLockMode.values.map(
              (mode) => ListTile(
                leading: Icon(_getOrientationIcon(mode)),
                title: Text(_getOrientationLabel(mode)),
                trailing: settings.orientationLock == mode
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setOrientationLock(mode);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  IconData _getOrientationIcon(OrientationLockMode mode) {
    switch (mode) {
      case OrientationLockMode.auto:
        return Icons.screen_rotation;
      case OrientationLockMode.portrait:
        return Icons.stay_current_portrait;
      case OrientationLockMode.landscape:
        return Icons.stay_current_landscape;
    }
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildVersionTile(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.info_outline, color: AppColors.primary),
        ),
        title: Text(
          'Version',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: packageInfoAsync.when(
          data: (info) => Text(
            '${info.version} (${info.buildNumber})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          loading: () => Text(
            'Loading...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          error: (_, __) => Text(
            'Unknown',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
