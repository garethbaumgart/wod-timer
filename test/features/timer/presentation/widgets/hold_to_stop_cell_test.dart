// HOLD TO STOP on its own: the hold confirms once at 0.8s, letting go
// early rewinds and hints, a cancelled pointer rewinds quietly, a disabled
// cell ignores the finger, and a screen reader confirms with long press.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';

void main() {
  late int confirmed;
  late int shortPresses;

  setUp(() {
    confirmed = 0;
    shortPresses = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool showHint = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 132,
            child: HoldToStopCell(
              enabled: enabled,
              showHint: showHint,
              onConfirmed: () => confirmed++,
              onShortPress: () => shortPresses++,
            ),
          ),
        ),
      ),
    );
  }

  final fill = find.byType(FractionallySizedBox);

  testWidgets('a full hold confirms exactly once', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    // The first frame after the press starts the ticker's clock.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fill, findsOneWidget);
    expect(
      tester.widget<FractionallySizedBox>(fill).widthFactor,
      closeTo(0.5, 0.05),
    );
    expect(confirmed, 0);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(confirmed, 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(confirmed, 1);
    expect(shortPresses, 0);
  });

  testWidgets('letting go early rewinds the fill and hints', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fill, findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(shortPresses, 1);
    expect(confirmed, 0);
    await tester.pumpAndSettle();
    expect(fill, findsNothing);
  });

  testWidgets('a cancelled pointer rewinds without the hint', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fill, findsOneWidget);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(shortPresses, 0);
    expect(confirmed, 0);
    expect(fill, findsNothing);
  });

  testWidgets('the hint brightens the cell; disabled greys the label', (
    tester,
  ) async {
    await pump(tester);
    Color? boxColor() =>
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration!
                as BoxDecoration)
            .color;
    expect(boxColor(), AppColors.stopSlab);

    await pump(tester, showHint: true);
    expect(boxColor(), isNot(AppColors.stopSlab));

    await pump(tester, enabled: false, showHint: true);
    expect(boxColor(), AppColors.stopSlab, reason: 'no hint when disabled');
    expect(
      tester.widget<Text>(find.text('HOLD TO STOP')).style!.color,
      AppColors.textDisabledDark,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(confirmed, 0);
    expect(shortPresses, 0);
    expect(fill, findsNothing);
  });

  testWidgets('a screen reader confirms with the long-press action', (
    tester,
  ) async {
    await pump(tester);
    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(
      find.bySemanticsLabel('End workout. Hold to confirm.'),
    );
    expect(
      node,
      isSemantics(isButton: true, isEnabled: true, hasLongPressAction: true),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('End workout. Hold to confirm.'),
      SemanticsAction.longPress,
    );
    await tester.pump();
    expect(confirmed, 1);

    await pump(tester, enabled: false);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
      ),
      isSemantics(isEnabled: false, hasLongPressAction: false),
    );
    handle.dispose();
  });

  testWidgets('the raw pointer, not a long-press recogniser, starts the fill', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(Listener), findsWidgets);
    expect(find.byType(LongPressGestureRecognizer), findsNothing);
    final down = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(fill, findsOneWidget, reason: 'fills from the first frames');
    await down.up();
    await tester.pumpAndSettle();
  });
}
