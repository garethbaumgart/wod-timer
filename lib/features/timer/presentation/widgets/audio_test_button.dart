import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

/// A button to test audio sounds before starting a workout.
///
/// Helps users verify their volume is set correctly and audio is working.
class AudioTestButton extends ConsumerStatefulWidget {
  const AudioTestButton({super.key});

  @override
  ConsumerState<AudioTestButton> createState() => _AudioTestButtonState();
}

class _AudioTestButtonState extends ConsumerState<AudioTestButton> {
  bool _isPlaying = false;

  Future<void> _testSounds() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    ref.read(hapticServiceProvider).lightImpact();

    final audioService = ref.read(audioServiceProvider);

    // Play countdown sequence
    await audioService.playCountdown(3);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await audioService.playCountdown(2);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await audioService.playCountdown(1);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await audioService.playGo();

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: !_isPlaying,
      label: _isPlaying
          ? 'Playing audio test, please wait'
          : 'Test sounds button. Plays countdown audio to verify volume settings.',
      child: OutlinedButton.icon(
        onPressed: _isPlaying ? null : _testSounds,
        icon: _isPlaying
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              )
            : const Icon(Icons.volume_up, size: 18),
        label: Text(_isPlaying ? 'Playing...' : 'Test Sounds'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}
