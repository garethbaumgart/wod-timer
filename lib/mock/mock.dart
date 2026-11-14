// Beep + dial mocks (14 Nov 2026). Web only: ?mock=N picks a direction,
// ?beep=0 shows the beep off, ?sheet=1 opens the sound sheet. Not for main.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';

final Map<String, String> _q = kIsWeb
    ? Uri.base.queryParameters
    : const <String, String>{};

/// 0 = today's app. 1 Pill, 2 Sound sheet, 3 Timeline tick, 4 Beep wheel,
/// 5 Ruler dials.
final int mockVariant = int.tryParse(_q['mock'] ?? '') ?? 0;

/// Open the sound sheet on the first setup frame (direction 2).
final bool mockOpenSheet = _q['sheet'] == '1';

/// Simulated iPhone insets so the web render matches the phone.
final bool mockPhoneInsets = kIsWeb;

final ValueNotifier<bool> mockBeepOn = ValueNotifier(_q['beep'] != '0');

/// Direction 5's choice: 0 off, 1 half, 2 quarters.
final ValueNotifier<int> mockBeepSplit = ValueNotifier(
  _q['beep'] == '0' ? 0 : 1,
);

bool get mockOn => mockVariant != 0;

/// Wheel row height (selected digits are 42 * row / 56).
double get mockRowHeight => switch (mockVariant) {
  1 => 72,
  2 => 96,
  3 => 84,
  4 => 66,
  _ => 56,
};

/// Width of one wheel column.
double get mockWheelWidth => switch (mockVariant) {
  1 => 160,
  2 => 180,
  3 => 172,
  4 => 172,
  _ => 130,
};

/// Bezel box at full size (capped by the screen width).
double get mockBezelSize => switch (mockVariant) {
  0 => 270,
  4 => 300,
  _ => 400,
};

/// Where the beep sits in each round, as a fraction, or null for none.
double? mockBeepFraction() {
  switch (mockVariant) {
    case 1:
    case 2:
    case 3:
    case 4:
      return mockBeepOn.value ? 0.5 : null;
    case 5:
      return mockBeepSplit.value == 0 ? null : 0.5;
    default:
      return null;
  }
}

/// Direction 5 quarters: extra ticks at 1/4 and 3/4.
bool get mockQuarters => mockVariant == 5 && mockBeepSplit.value == 2;

/// Notch colour on the timeline.
Color get mockBeepColor => mockVariant == 4 ? AppColors.warning : Colors.white;

/// The BEEP wheel's label colour (direction 4).
const Color mockBeepLabel = AppColors.warning;

/// Direction 1: the toggle pill.
class MockBeepPill extends StatelessWidget {
  const MockBeepPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: mockBeepOn,
      builder: (context, on, _) => GestureDetector(
        onTap: () => mockBeepOn.value = !on,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 12, right: 16),
              decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: on ? Colors.white : AppColors.borderLight,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    on
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    size: 18,
                    color: on ? Colors.black : AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 15,
                      letterSpacing: 1,
                      color: on ? Colors.black : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Direction 3: the line under the taller timeline.
class MockTickCaption extends StatelessWidget {
  const MockTickCaption({required this.at, super.key});

  final String at;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.notifications_active,
          size: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 6),
        Text(
          'BEEP AT $at',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 14 * 0.1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '· drag a tick to move it',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textDisabledDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Direction 5: MID-ROUND BEEP  OFF | HALF | QUARTERS, styled like For
/// Time's count switch.
class MockBeepSplitSwitch extends StatelessWidget {
  const MockBeepSplitSwitch({super.key, this.title = 'MID-ROUND BEEP'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mockBeepSplit,
      builder: (context, split, _) {
        Widget option(String label, int value) {
          final selected = split == value;
          return GestureDetector(
            onTap: () => mockBeepSplit.value = value,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: AppTypography.sectionHeader.copyWith(
                  color: selected ? Colors.black : AppColors.textSecondaryDark,
                  fontSize: 16,
                  letterSpacing: 16 * 0.06,
                  height: 1.2,
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 13 * 0.14,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    option('OFF', 0),
                    option('HALF', 1),
                    option('QUARTERS', 2),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Direction 5: a value as a full-width ruler. The big value on top, a
/// tape of ticks under it lit in the label colour up to the value, a white
/// pointer in the middle. Drag sideways to move it a step per tick.
class MockRulerDial extends StatefulWidget {
  const MockRulerDial({
    required this.label,
    required this.labelColor,
    required this.range,
    required this.value,
    required this.format,
    required this.onChanged,
    super.key,
  });

  final String label;
  final Color labelColor;
  final SetupRange range;
  final int value;
  final String Function(int value) format;
  final ValueChanged<int> onChanged;

  static const double tickGap = 14;
  static const double tapeHeight = 36;

  @override
  State<MockRulerDial> createState() => _MockRulerDialState();
}

class _MockRulerDialState extends State<MockRulerDial> {
  double _drag = 0;

  void _onDrag(DragUpdateDetails d) {
    _drag -= d.delta.dx;
    final steps = (_drag / MockRulerDial.tickGap).truncate();
    if (steps == 0) return;
    _drag -= steps * MockRulerDial.tickGap;
    final next = widget.range.normalize(
      widget.value + steps * widget.range.step,
    );
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDrag,
      onHorizontalDragEnd: (_) => _drag = 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: widget.labelColor,
              fontSize: 13,
              letterSpacing: 13 * 0.14,
            ),
          ),
          Text(
            widget.format(widget.value),
            maxLines: 1,
            style: AppTypography.timerDisplayMedium.copyWith(
              color: AppColors.textPrimaryDark,
              fontSize: 60,
              height: 1.05,
              letterSpacing: 0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: MockRulerDial.tapeHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _RulerPainter(
                range: widget.range,
                value: widget.value,
                accent: widget.labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.range,
    required this.value,
    required this.accent,
  });

  final SetupRange range;
  final int value;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final band = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas
      ..save()
      ..clipRRect(band)
      ..drawRRect(band, Paint()..color = AppColors.soft);
    final cx = size.width / 2;
    final valueIndex = (value - range.min) / range.step;
    final count = ((range.max - range.min) / range.step).round();
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var k = 0; k <= count; k++) {
      final x = cx + (k - valueIndex) * MockRulerDial.tickGap;
      if (x < -4 || x > size.width + 4) continue;
      final v = range.min + k * range.step;
      final major = range.step >= 15 ? v % 60 == 0 : v % (range.step * 5) == 0;
      final len = major ? 18.0 : 10.0;
      // Fade toward the edges.
      final edge = (math.min(x, size.width - x) / (size.width * 0.35)).clamp(
        0.0,
        1.0,
      );
      final base = k <= valueIndex ? accent : AppColors.bezelTickOff;
      tick
        ..strokeWidth = major ? 3 : 2
        ..color = base.withValues(alpha: 0.25 + 0.75 * edge);
      final top = (size.height - len) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + len), tick);
    }
    canvas.restore();
    // The pointer.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height / 2),
          width: 4,
          height: size.height - 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.value != value || old.accent != accent || old.range != range;
}
