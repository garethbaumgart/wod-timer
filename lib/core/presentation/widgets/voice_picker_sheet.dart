import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

/// Short label for a voice option ("Major", "Off", ...).
String voiceShortLabel(VoiceOption voice) {
  switch (voice) {
    case VoiceOption.major:
      return 'Major';
    case VoiceOption.liam:
      return 'Liam';
    case VoiceOption.holly:
      return 'Holly';
    case VoiceOption.random:
      return 'Random';
    case VoiceOption.off:
      return 'Off';
  }
}

/// Full descriptor label for a voice option.
String voiceLabel(VoiceOption voice) {
  switch (voice) {
    case VoiceOption.major:
      return 'Major (CrossFit Coach)';
    case VoiceOption.liam:
      return 'Liam (Old British Man)';
    case VoiceOption.holly:
      return 'Holly (Female Coach)';
    case VoiceOption.random:
      return 'Random (mix it up each cue)';
    case VoiceOption.off:
      return 'Off (beeps only)';
  }
}

IconData _voiceIcon(VoiceOption voice) {
  switch (voice) {
    case VoiceOption.major:
    case VoiceOption.liam:
    case VoiceOption.holly:
      return Icons.record_voice_over;
    case VoiceOption.random:
      return Icons.shuffle;
    case VoiceOption.off:
      return Icons.volume_off;
  }
}

/// The voice pack to audition for a picker row, null when not previewable.
String? _previewPack(VoiceOption voice) {
  switch (voice) {
    case VoiceOption.major:
      return 'major';
    case VoiceOption.liam:
      return 'liam';
    case VoiceOption.holly:
      return 'holly';
    case VoiceOption.random:
      return 'random';
    case VoiceOption.off:
      return null;
  }
}

/// Shared voice-pack picker bottom sheet.
///
/// Every row with a voice can be auditioned via its play button before
/// selecting (the app's wedge feature shouldn't be a blind choice).
Future<void> showVoicePickerSheet(BuildContext context, WidgetRef ref) {
  ref.read(hapticServiceProvider).selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    builder: (sheetContext) => SafeArea(
      // Scrollable so the sheet never overflows in landscape.
      child: SingleChildScrollView(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsNotifierProvider);
            return Column(
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
                ...VoiceOption.values.map((voice) {
                  final pack = _previewPack(voice);
                  final isSelected = settings.voice == voice;
                  return ListTile(
                    leading: Icon(
                      _voiceIcon(voice),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimaryDark,
                    ),
                    title: Text(
                      voiceLabel(voice),
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pack != null)
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_outline,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            tooltip: 'Preview',
                            onPressed: () {
                              ref.read(hapticServiceProvider).selectionClick();
                              ref
                                  .read(audioServiceProvider)
                                  .playVoicePreview(pack);
                            },
                          ),
                        if (isSelected)
                          const Icon(Icons.check, color: AppColors.primary)
                        else
                          const SizedBox(width: 24),
                      ],
                    ),
                    onTap: () {
                      ref.read(hapticServiceProvider).selectionClick();
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .setVoice(voice);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    ),
  );
}
