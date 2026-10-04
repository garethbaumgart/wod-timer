import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/package_info_provider.dart';
import 'package:wod_timer/core/application/providers/review_prompter_provider.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/content_width_cap.dart';
import 'package:wod_timer/core/presentation/widgets/voice_picker_sheet.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

/// Settings page with Signal-inspired minimal design.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Rows at 17pt: white labels, grey values.
  static TextStyle get _labelStyle => AppTypography.bodyMedium.copyWith(
    color: AppColors.textPrimaryDark,
    fontSize: 17,
  );

  static TextStyle get _valueStyle => AppTypography.bodyMedium.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: 17,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsNotifierProvider);

    // Reached with context.go, so it is the only route: the Android back
    // button would close the app. Back goes Home, like the header chevron.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: ContentWidthCap(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.home),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox(
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

                // One flat list: six rows read faster than three headed
                // sections of one or two rows each.
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDivider(),
                      _buildTapRow(
                        label: 'Orientation',
                        value: _getOrientationShortLabel(
                          settings.orientationLock,
                        ),
                        onTap: () =>
                            _showOrientationPicker(context, ref, settings),
                      ),
                      _buildDivider(),
                      _buildTapRow(
                        label: 'Voice',
                        value: voiceShortLabel(settings.voice),
                        onTap: () => showVoicePickerSheet(context, ref),
                      ),
                      _buildDivider(),
                      _buildSwitchRow(
                        label: 'Haptics',
                        value: settings.hapticEnabled,
                        onChanged: (value) {
                          ref.read(hapticServiceProvider).selectionClick();
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .setHapticEnabled(enabled: value);
                        },
                      ),
                      _buildDivider(),
                      _buildRateBlock(ref),
                      _buildDivider(),
                      _buildTapRow(
                        label: 'Privacy policy',
                        value: '',
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://mentalmetal.app/wharf-wod/privacy',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      _buildDivider(),
                      _buildVersionFooter(ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rate and feedback as one question with two answers (2.1.0, option 14
  /// of the Rate row mocks): "Love it" opens the store page, "Could be
  /// better" opens the feedback mail. Both are always on screen: showing the
  /// store only to people who say they love it would be review gating,
  /// which Google Play bans.
  ///
  /// The automatic rating sheet is throttled by Apple and may never appear,
  /// so someone who wants to rate needs a control they can find. It opens
  /// the store page, not the sheet: neither store lets a button call the
  /// in-app review API.
  Widget _buildRateBlock(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How is Wharf WOD working for you?',
            style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RateAnswer(
                  label: 'Love it',
                  semanticsLabel: 'Love it: rate Wharf WOD',
                  filled: true,
                  onTap: () {
                    trackEvent('rate_tapped', {'source': 'settings'});
                    unawaited(ref.read(reviewPrompterProvider).openStorePage());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateAnswer(
                  label: 'Could be better',
                  semanticsLabel: 'Could be better: send feedback',
                  filled: false,
                  onTap: () {
                    trackEvent('feedback_tapped', {'source': 'settings'});
                    unawaited(
                      launchUrl(
                        Uri.parse(
                          'mailto:support@mentalmetal.app'
                          '?subject=Wharf%20WOD%20feedback',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.divider);
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
            Text(label, style: _labelStyle),
            Text(value.isEmpty ? '>' : '$value >', style: _valueStyle),
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
          Text(label, style: _labelStyle),
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

  /// The version as a quiet footer, not a row: it isn't something to tap.
  Widget _buildVersionFooter(WidgetRef ref) {
    final versionText = ref
        .watch(packageInfoProvider)
        .when(
          data: (info) => 'Wharf WOD ${info.version} (${info.buildNumber})',
          loading: () => 'Wharf WOD',
          error: (_, _) => 'Wharf WOD',
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Text(
        versionText,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
          fontSize: 15,
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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Orientation',
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
      ),
    );
  }
}

/// One of the two answers in the rate block: a 48pt button, the filled one
/// neon green with a star.
class _RateAnswer extends StatelessWidget {
  const _RateAnswer({
    required this.label,
    required this.semanticsLabel,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled
        ? AppColors.backgroundDark
        : AppColors.textPrimaryDark;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (filled) ...[
                Icon(Icons.star_rounded, size: 19, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: foreground,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
