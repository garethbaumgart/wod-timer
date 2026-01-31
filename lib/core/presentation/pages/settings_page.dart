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
                  Semantics(
                    button: true,
                    label: 'Go back',
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 22,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: AppTypography.sectionHeader.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontSize: 24,
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
                  // DISPLAY section
                  _buildSectionHeader('Display'),
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
                  // AUDIO section
                  _buildSectionHeader('Audio'),
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
                  _buildTapRow(
                    label: 'Voice',
                    value: _getVoiceShortLabel(settings.voice),
                    onTap: () => _showVoicePicker(context, ref, settings),
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
                  // ABOUT section
                  _buildSectionHeader('About'),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.summaryLabel.copyWith(
          color: AppColors.textHintDark,
          fontSize: 11,
          letterSpacing: 1,
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
              style: AppTypography.bodyMedium.copyWith(
                color: _labelColor,
              ),
            ),
            Text(
              '$value >',
              style: AppTypography.bodyMedium.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
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
            style: AppTypography.bodyMedium.copyWith(
              color: _labelColor,
            ),
          ),
          Text(
            versionText,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getVoiceShortLabel(VoiceOption voice) {
    switch (voice) {
      case VoiceOption.major:
        return 'Major';
      case VoiceOption.liam:
        return 'Liam';
      case VoiceOption.random:
        return 'Random';
    }
  }

  String _getVoiceLabel(VoiceOption voice) {
    switch (voice) {
      case VoiceOption.major:
        return 'Major (CrossFit Coach)';
      case VoiceOption.liam:
        return 'Liam (Old British Man)';
      case VoiceOption.random:
        return 'Random (surprise me)';
    }
  }

  IconData _getVoiceIcon(VoiceOption voice) {
    switch (voice) {
      case VoiceOption.major:
        return Icons.record_voice_over;
      case VoiceOption.liam:
        return Icons.record_voice_over_outlined;
      case VoiceOption.random:
        return Icons.shuffle;
    }
  }

  void _showVoicePicker(
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
                'Voice',
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            ...VoiceOption.values.map(
              (voice) => ListTile(
                leading: Icon(
                  _getVoiceIcon(voice),
                  color: AppColors.textPrimaryDark,
                ),
                title: Text(
                  _getVoiceLabel(voice),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                trailing: settings.voice == voice
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(hapticServiceProvider).selectionClick();
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setVoice(voice);
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
