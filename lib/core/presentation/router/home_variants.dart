import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// Preview only: alternative Home card layouts, picked with the HOME
/// dart-define (A to F). Empty keeps the shipped strips.
const homeVariant = String.fromEnvironment('HOME');

/// One mode as Home shows it.
class HomeMode {
  const HomeMode({
    required this.name,
    required this.config,
    required this.accent,
    required this.onTap,
    required this.shape,
  });

  final String name;
  final String config;
  final Color accent;
  final VoidCallback onTap;

  /// The workout's shape for the timeline cards: (seconds, isRest) parts.
  final List<(int, bool)> shape;
}

class HomeVariant extends StatelessWidget {
  const HomeVariant({required this.variant, required this.modes, super.key});

  final String variant;
  final List<HomeMode> modes;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case 'B':
      case 'C':
        return _grid(colour: variant == 'C');
      default:
        return Column(
          spacing: 14,
          children: [
            for (final m in modes)
              Expanded(
                child: switch (variant) {
                  'D' => _Scoreboard(m),
                  'E' => _Tall(m, play: true),
                  'F' => _Timeline(m),
                  _ => _Tall(m),
                },
              ),
          ],
        );
    }
  }

  Widget _grid({required bool colour}) => Column(
    spacing: 14,
    children: [
      for (var r = 0; r < 2; r++)
        Expanded(
          child: Row(
            spacing: 14,
            children: [
              for (var c = 0; c < 2; c++)
                Expanded(child: _Tile(modes[r * 2 + c], colour: colour)),
            ],
          ),
        ),
    ],
  );
}

TextStyle _name(double size) => AppTypography.stripName.copyWith(
  color: AppColors.brand,
  fontSize: size,
  fontWeight: FontWeight.w900,
  height: 1,
);

TextStyle _config(double size, {FontWeight weight = FontWeight.w700}) =>
    AppTypography.bodyLarge.copyWith(
      color: Colors.white,
      fontSize: size,
      fontWeight: weight,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class _Card extends StatelessWidget {
  const _Card({
    required this.mode,
    required this.child,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  });

  final HomeMode mode;
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: mode.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration:
            decoration ??
            BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              color: Colors.white.withValues(alpha: 0.035),
            ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

Widget _bar(Color c, {double width = 6, double? height}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
);

/// A: the strips, grown to share the height: bigger name and setup.
/// E: the same with a one-tap start on the right.
class _Tall extends StatelessWidget {
  const _Tall(this.mode, {this.play = false});
  final HomeMode mode;
  final bool play;

  @override
  Widget build(BuildContext context) => _Card(
    mode: mode,
    child: Row(
      children: [
        _bar(mode.accent, height: double.infinity),
        const SizedBox(width: 20),
        Text(mode.name, style: _name(40)),
        const Spacer(),
        Text(mode.config, style: _config(play ? 22 : 26)),
        if (play) ...[
          const SizedBox(width: 18),
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.black,
              size: 42,
            ),
          ),
        ],
      ],
    ),
  );
}

/// B / C: a 2 x 2 grid of big tiles; C tints each tile in its mode colour.
class _Tile extends StatelessWidget {
  const _Tile(this.mode, {required this.colour});
  final HomeMode mode;
  final bool colour;

  @override
  Widget build(BuildContext context) => _Card(
    mode: mode,
    padding: const EdgeInsets.all(22),
    decoration: colour
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: mode.accent.withValues(alpha: 0.55)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mode.accent.withValues(alpha: 0.22),
                mode.accent.withValues(alpha: 0.03),
              ],
            ),
          )
        : null,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!colour) ...[_bar(mode.accent), const SizedBox(width: 18)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (colour) ...[
                _bar(mode.accent, width: 44, height: 6),
                const SizedBox(height: 18),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(mode.name, style: _name(34)),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  mode.config,
                  style: _config(34, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// D: the setup is the hero, in big digits like the live clock.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard(this.mode);
  final HomeMode mode;

  @override
  Widget build(BuildContext context) => _Card(
    mode: mode,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      children: [
        _bar(mode.accent, height: double.infinity),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode.name,
                style: _name(22).copyWith(letterSpacing: 2.5),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  mode.config,
                  style: _config(54, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// F: each card draws its workout's shape: EMOM's rounds, Tabata's work and
/// rest, AMRAP's one block, For Time's run to the cap.
class _Timeline extends StatelessWidget {
  const _Timeline(this.mode);
  final HomeMode mode;

  @override
  Widget build(BuildContext context) => _Card(
    mode: mode,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(mode.accent, height: 40),
            const SizedBox(width: 18),
            Text(mode.name, style: _name(38)),
            const Spacer(),
            Text(mode.config, style: _config(24)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 16,
          child: Row(
            spacing: 3,
            children: [
              for (final (secs, rest) in mode.shape)
                Expanded(
                  flex: secs,
                  child: Container(
                    decoration: BoxDecoration(
                      color: rest
                          ? AppColors.rest.withValues(alpha: 0.85)
                          : mode.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
