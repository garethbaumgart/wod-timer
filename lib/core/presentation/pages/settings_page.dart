import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/package_info_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

/// Settings page with Signal-inspired minimal design.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _labelColor = Color(0xFF777777);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Text(
                      '\u2039',
                      style: AppTypography.sectionHeader.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: AppTypography.sectionHeader.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Settings rows
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDivider(),
                  _buildTapRow(
                    label: 'Orientation Lock',
                    value: _getOrientationShortLabel(settings.orientationLock),
                    onTap: () => _showOrientationPicker(context, ref, settings),
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    label: 'Keep Screen On',
                    value: settings.keepScreenOn,
                    onChanged: (value) {
                      ref.read(hapticServiceProvider).selectionClick();
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .setKeepScreenOn(enabled: value);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    label: 'Sound Effects',
                    value: settings.soundEnabled,
                    onChanged: (value) {
                      ref.read(hapticServiceProvider).selectionClick();
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .setSoundEnabled(enabled: value);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    label: 'Haptic Feedback',
                    value: settings.hapticEnabled,
                    onChanged: (value) {
                      ref.read(hapticServiceProvider).selectionClick();
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .setHapticEnabled(enabled: value);
                    },
                  ),
                  _buildDivider(),
                  _buildVersionRow(ref),
                  _buildDivider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildTapRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _labelColor,
              ),
            ),
            Text(
              '$value >',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: _labelColor,
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              inactiveThumbColor: const Color(0xFF555555),
              inactiveTrackColor: AppColors.border,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(WidgetRef ref) {
    final packageInfoAsync = ref.watch(packageInfoProvider);

    final versionText = packageInfoAsync.when(
      data: (info) => '${info.version} (${info.buildNumber})',
      loading: () => 'Loading...',
      error: (_, __) => 'Unknown',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Version',
            style: AppTypography.bodySmall.copyWith(
              color: _labelColor,
            ),
          ),
          Text(
            versionText,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getOrientationShortLabel(OrientationLockMode mode) {
    switch (mode) {
      case OrientationLockMode.auto:
        return 'Auto';
      case OrientationLockMode.portrait:
        return 'Portrait';
      case OrientationLockMode.landscape:
        return 'Landscape';
    }
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

  void _showOrientationPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    ref.read(hapticServiceProvider).selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Orientation Lock',
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            ...OrientationLockMode.values.map(
              (mode) => ListTile(
                leading: Icon(
                  _getOrientationIcon(mode),
                  color: AppColors.textPrimaryDark,
                ),
                title: Text(
                  _getOrientationLabel(mode),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                trailing: settings.orientationLock == mode
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(hapticServiceProvider).selectionClick();
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setOrientationLock(mode);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
