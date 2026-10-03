import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_stepper.dart';

/// Preview only: alternative Home card layouts. Picked with the HOME
/// dart-define, or on a simulator with SIMCTL_CHILD_HOME_VARIANT at launch.
/// T* are tablet tile grids, P* phone timeline lists. Empty keeps the strips.
final String homeVariant = (() {
  try {
    final dir = File(Platform.resolvedExecutable).parent.path;
    final f = File('$dir/home_variant.txt');
    if (f.existsSync()) return f.readAsStringSync().trim();
  } on Object catch (_) {}
  return const String.fromEnvironment('HOME');
})();

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

  /// The workout's shape: (seconds, isRest) parts.
  final List<(int, bool)> shape;

  int get totalSeconds => shape.fold(0, (a, p) => a + p.$1);
}

/// What a variant turns on.
class _Spec {
  const _Spec({
    this.tile = false,
    this.tint = false,
    this.outline = false,
    this.line = 'none',
    this.hero = false,
    this.play = false,
    this.watermark = false,
    this.split = false,
    this.heroFirst = false,
    this.phase = false,
    this.total = false,
    this.compact = false,
    this.thick = false,
    this.totalTop = false,
  });

  final bool tile, tint, outline, hero, play, watermark, split, heroFirst;
  final bool phase, total, compact, thick, totalTop;

  /// Timeline: none, bottom, bg, vertical, dots, ticks, leftbar.
  final String line;
}

const _specs = <String, _Spec>{
  'T0': _Spec(tile: true),
  'T0C': _Spec(tile: true, tint: true),
  'T1': _Spec(tile: true, tint: true, line: 'bottom'),
  'T2': _Spec(tile: true, tint: true, hero: true),
  'T3': _Spec(tile: true, watermark: true),
  'T4': _Spec(tile: true, line: 'vertical'),
  'T5': _Spec(tile: true, split: true),
  'T6': _Spec(tile: true, outline: true, line: 'bottom'),
  'T7': _Spec(tile: true, tint: true, play: true),
  'T8': _Spec(tile: true, tint: true, heroFirst: true, line: 'bottom'),
  'T9': _Spec(tile: true, line: 'bg'),
  'T10': _Spec(tile: true, tint: true, line: 'dots', hero: true),
  'TA': _Spec(tile: true, line: 'bottom', total: true),
  'TB': _Spec(tile: true, tint: true, line: 'bottom', total: true),
  'TC': _Spec(tile: true, hero: true, line: 'bottom', total: true),
  'TD': _Spec(tile: true, tint: true, hero: true, line: 'bottom', total: true),
  'TE': _Spec(tile: true, outline: true, line: 'bottom', total: true),
  'TF': _Spec(tile: true, line: 'bottom', total: true, thick: true),
  'TG': _Spec(tile: true, heroFirst: true, line: 'bottom', total: true),
  'TH': _Spec(tile: true, line: 'bottom', totalTop: true),
  'P0': _Spec(line: 'bottom'),
  'P1': _Spec(line: 'bg'),
  'P2': _Spec(line: 'leftbar'),
  'P3': _Spec(line: 'bottom', total: true),
  'P4': _Spec(line: 'ticks'),
  'P5': _Spec(line: 'bottom', compact: true),
  'P6': _Spec(line: 'bottom', phase: true),
  'P7': _Spec(line: 'dots'),
  'P8': _Spec(line: 'bottom', tint: true),
  'P9': _Spec(line: 'bottom', play: true),
  'P10': _Spec(line: 'bottom', outline: true, total: true),
};

class HomeVariant extends StatelessWidget {
  const HomeVariant({required this.variant, required this.modes, super.key});

  final String variant;
  final List<HomeMode> modes;

  @override
  Widget build(BuildContext context) {
    final spec = _specs[variant] ?? const _Spec(line: 'bottom');
    if (!spec.tile) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: spec.compact ? 10 : 14,
            children: [for (final m in modes) _Strip(m, spec)],
          ),
        ),
      );
    }
    if (spec.heroFirst) {
      return Column(
        spacing: 14,
        children: [
          Expanded(flex: 5, child: _Tile(modes[0], spec, big: true)),
          Expanded(
            flex: 4,
            child: Row(
              spacing: 14,
              children: [
                for (final m in modes.skip(1)) Expanded(child: _Tile(m, spec)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      spacing: 14,
      children: [
        for (var r = 0; r < 2; r++)
          Expanded(
            child: Row(
              spacing: 14,
              children: [
                for (var c = 0; c < 2; c++)
                  Expanded(child: _Tile(modes[r * 2 + c], spec)),
              ],
            ),
          ),
      ],
    );
  }
}

TextStyle _name(double size) => AppTypography.stripName.copyWith(
  color: Colors.white,
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

TextStyle _muted(double size) => AppTypography.bodyLarge.copyWith(
  color: AppColors.textSecondaryDark,
  fontSize: size,
  fontWeight: FontWeight.w600,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

Widget _bar(Color c, {double width = 6, double? height}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
);

Color _partColour(HomeMode m, bool rest, _Spec s, {double a = 0.9}) {
  if (rest) return AppColors.rest.withValues(alpha: a);
  // Workouts with rest draw work green, so green is work and pink is rest.
  if (m.shape.any((p) => p.$2)) return AppColors.work.withValues(alpha: a);
  return (s.phase ? AppColors.work : m.accent).withValues(alpha: a);
}

/// The workout drawn as parts, flex by seconds.
Widget _timeline(
  HomeMode m,
  _Spec s, {
  double height = 14,
  Axis axis = Axis.horizontal,
  double alpha = 0.9,
  bool dots = false,
}) {
  final parts = m.shape;
  if (dots && parts.length > 1) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final (secs, rest) in parts)
            Expanded(
              flex: secs,
              child: Center(
                child: Container(
                  width: height,
                  height: height,
                  decoration: BoxDecoration(
                    color: _partColour(m, rest, s, a: alpha),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  final children = [
    for (final (secs, rest) in parts)
      Expanded(
        flex: secs,
        child: Container(
          decoration: BoxDecoration(
            color: _partColour(m, rest, s, a: alpha),
            borderRadius: BorderRadius.circular(height / 4),
          ),
        ),
      ),
  ];
  return axis == Axis.horizontal
      ? SizedBox(height: height, child: Row(spacing: 3, children: children))
      : SizedBox(width: height, child: Column(spacing: 3, children: children));
}

Widget _ticks(HomeMode m, _Spec s) => SizedBox(
  height: 22,
  child: Stack(
    alignment: Alignment.center,
    children: [
      Container(
        height: 6,
        decoration: BoxDecoration(
          color: m.accent.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      Row(
        children: [
          for (final (i, (secs, rest)) in m.shape.indexed)
            Expanded(
              flex: secs,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 3,
                  height: i == 0 ? 0 : (rest ? 10 : 22),
                  color: rest ? AppColors.rest : m.accent,
                ),
              ),
            ),
        ],
      ),
    ],
  ),
);

Widget _play(double size) => Container(
  width: size,
  height: size,
  decoration: const BoxDecoration(
    color: AppColors.primary,
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: size * 0.64),
);

BoxDecoration _decor(HomeMode m, _Spec s, {double r = 18}) {
  if (s.tint) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: m.accent.withValues(alpha: 0.55)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          m.accent.withValues(alpha: 0.22),
          m.accent.withValues(alpha: 0.03),
        ],
      ),
    );
  }
  if (s.outline) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: m.accent, width: 2),
      boxShadow: [
        BoxShadow(color: m.accent.withValues(alpha: 0.35), blurRadius: 18),
      ],
      color: const Color(0xFF07070F),
    );
  }
  return BoxDecoration(
    borderRadius: BorderRadius.circular(r),
    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    color: Colors.white.withValues(alpha: 0.035),
  );
}

class _Tap extends StatelessWidget {
  const _Tap({required this.mode, required this.decoration, required this.child});
  final HomeMode mode;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: mode.onTap,
      borderRadius: decoration.borderRadius as BorderRadius?,
      child: Ink(decoration: decoration, child: child),
    ),
  );
}

Widget _fit(Widget w) =>
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w);

class _Tile extends StatelessWidget {
  const _Tile(this.m, this.s, {this.big = false});
  final HomeMode m;
  final _Spec s;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final nameSize = big ? 44.0 : 32.0;
    final configSize = s.hero ? (big ? 64.0 : 46.0) : (big ? 40.0 : 32.0);
    final showBar = !s.tint && !s.outline && !s.split && s.line != 'vertical';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.tint || s.outline) ...[
          _bar(m.accent, width: 44, height: 6),
          const SizedBox(height: 16),
        ],
        if (s.split)
          const SizedBox.shrink()
        else if (s.totalTop)
          Row(
            children: [
              Expanded(child: _fit(Text(m.name, style: _name(nameSize)))),
              Text('${setupClock(m.totalSeconds)} total', style: _muted(18)),
            ],
          )
        else
          _fit(Text(m.name, style: _name(nameSize))),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _fit(
                Text(m.config, style: _config(configSize, weight: FontWeight.w800)),
              ),
            ),
            if (s.play) _play(big ? 76 : 60),
          ],
        ),
        if (s.line == 'bottom' || s.line == 'dots') ...[
          const SizedBox(height: 16),
          _timeline(
            m,
            s,
            height: s.thick ? 24 : 14,
            dots: s.line == 'dots',
          ),
        ],
        if (s.total) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${setupClock(m.totalSeconds)} total',
              style: _muted(big ? 18 : 16),
            ),
          ),
        ],
      ],
    );
    Widget body = Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBar) ...[_bar(m.accent), const SizedBox(width: 18)],
          Expanded(child: content),
          if (s.line == 'vertical') ...[
            const SizedBox(width: 16),
            _timeline(m, s, height: 12, axis: Axis.vertical),
          ],
        ],
      ),
    );
    if (s.split) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            decoration: BoxDecoration(
              color: m.accent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: _fit(
              Text(m.name, style: _name(nameSize).copyWith(color: Colors.black)),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }
    if (s.watermark || s.line == 'bg') {
      body = Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: s.watermark
                  ? Align(
                      alignment: const Alignment(1.4, 1.6),
                      child: Text(
                        m.name.substring(0, 1),
                        style: _name(260).copyWith(
                          color: m.accent.withValues(alpha: 0.13),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(0, 80, 0, 0),
                      child: _timeline(m, s, height: double.infinity, alpha: 0.12),
                    ),
            ),
          ),
          body,
        ],
      );
    }
    return _Tap(mode: m, decoration: _decor(m, s), child: body);
  }
}

class _Strip extends StatelessWidget {
  const _Strip(this.m, this.s);
  final HomeMode m;
  final _Spec s;

  @override
  Widget build(BuildContext context) {
    final nameSize = s.compact ? 24.0 : 28.0;
    final top = Row(
      children: [
        if (s.line != 'leftbar') ...[
          _bar(m.accent, width: 4, height: 30),
          const SizedBox(width: 14),
        ],
        Text(m.name, style: _name(nameSize)),
        const Spacer(),
        Text(m.config, style: _config(s.compact ? 16 : 18)),
        if (s.play) ...[const SizedBox(width: 12), _play(44)],
      ],
    );
    Widget line;
    switch (s.line) {
      case 'ticks':
        line = _ticks(m, s);
      case 'dots':
        line = _timeline(m, s, height: 10, dots: true);
      case 'bg':
        line = const SizedBox.shrink();
      case 'leftbar':
        line = _timeline(m, s, height: 16);
      default:
        line = _timeline(m, s, height: s.compact ? 8 : 12);
    }
    Widget body = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: s.compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          if (s.line != 'bg') ...[
            SizedBox(height: s.compact ? 10 : 14),
            line,
          ],
          if (s.total) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${setupClock(m.totalSeconds)} total', style: _muted(13)),
            ),
          ],
        ],
      ),
    );
    if (s.line == 'never') {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
              child: _timeline(m, s, height: 7, axis: Axis.vertical),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    if (s.line == 'bg') {
      body = Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _timeline(m, s, height: double.infinity, alpha: 0.16),
            ),
          ),
          body,
        ],
      );
    }
    return _Tap(mode: m, decoration: _decor(m, s, r: 14), child: body);
  }
}
