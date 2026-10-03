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
      return 'Beeps';
    case VoiceOption.silent:
      return 'Silent';
  }
}

/// Full descriptor label for a voice option.
String voiceLabel(VoiceOption voice) {
  switch (voice) {
    case VoiceOption.major:
      return 'Major (CrossFit Coach)';
    case VoiceOption.liam:
      return 'Liam (Male Coach)';
    case VoiceOption.holly:
      return 'Holly (Female Coach)';
    case VoiceOption.random:
      return 'Random (mix it up each cue)';
    case VoiceOption.off:
      return 'Beeps only';
    case VoiceOption.silent:
      return 'Silent';
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
    case VoiceOption.silent:
      return null;
  }
}

/// Shared voice-pack picker bottom sheet.
///
/// Every row with a voice can be auditioned via its play button before
/// selecting (the app's wedge feature shouldn't be a blind choice). Preview
/// leads the row and the check trails it, so "listen" and "choose" sit at
/// opposite ends and a thumb can't confuse them; the rest of the row picks.
Future<void> showVoicePickerSheet(BuildContext context, WidgetRef ref) {
  ref.read(hapticServiceProvider).selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
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
                    // Same 48pt slot on every row, empty where there is
                    // nothing to preview, so the labels line up.
                    leading: SizedBox.square(
                      dimension: 48,
                      child: pack == null
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.play_circle_outline,
                                color: AppColors.textPrimaryDark,
                                size: 28,
                              ),
                              tooltip: 'Preview ${voiceShortLabel(voice)}',
                              onPressed: () {
                                ref
                                    .read(hapticServiceProvider)
                                    .selectionClick();
                                ref
                                    .read(audioServiceProvider)
                                    .playVoicePreview(pack);
                              },
                            ),
                    ),
                    title: Text(
                      voiceLabel(voice),
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : const SizedBox(width: 24),
                    onTap: () {
                      ref.read(hapticServiceProvider).selectionClick();
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .setVoice(voice);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Text(
                    'Voice cues play through the silent switch.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryDark,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
