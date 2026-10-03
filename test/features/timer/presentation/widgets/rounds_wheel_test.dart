// The AMRAP end-screen wheel on its own: 0..999, the selected number in
// AMRAP blue with dim neighbours, a drag reports the new count, a count
// set from outside moves the wheel, and the adjustable node stops at the
// ends.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';

void main() {
  late List<int> changes;

  setUp(() => changes = []);

  Future<void> pump(WidgetTester tester, int rounds) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RoundsWheel(
              rounds: rounds,
              fontSize: 60,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  test('geometry follows the font size', () {
    expect(RoundsWheel.itemHeightFor(100), 105);
    expect(RoundsWheel.heightFor(100), closeTo(199.5, 0.01));
    expect(RoundsWheel.widthFor(100), 160);
    expect(RoundsWheel.max, 999);
  });

  testWidgets('the selected count is blue, its neighbours dim, no scaling', (
    tester,
  ) async {
    await pump(tester, 5);
    expect(colorOf(tester, '5'), AppColors.amrapAccent);
    expect(colorOf(tester, '4'), AppColors.wheelDim);
    expect(colorOf(tester, '6'), AppColors.wheelDim);
    expect(
      tester.widget<Text>(find.text('5')).textScaler,
      TextScaler.noScaling,
    );
    expect(tester.widget<Text>(find.text('5')).style!.fontSize, 60);
  });

  testWidgets('a drag of one row reports the new count once', (tester) async {
    await pump(tester, 5);
    await tester.drag(
      find.byType(RoundsWheel),
      Offset(0, -RoundsWheel.itemHeightFor(60)),
    );
    await tester.pumpAndSettle();
    expect(changes, [6]);
  });

  testWidgets('a count set from outside moves the wheel to it', (tester) async {
    await pump(tester, 3);
    await pump(tester, 7);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Rounds')),
      isSemantics(value: '7', increasedValue: '8', decreasedValue: '6'),
    );
    handle.dispose();
    expect(colorOf(tester, '7'), AppColors.amrapAccent);
    expect(changes, isEmpty, reason: 'a programmatic move is not a change');
  });

  testWidgets('adjustable: increase and decrease by one, held at 0 and 999', (
    tester,
  ) async {
    await pump(tester, 0);
    final handle = tester.ensureSemantics();
    await tester.pump();
    SemanticsNode node() =>
        tester.getSemantics(find.bySemanticsLabel('Rounds'));
    expect(
      node(),
      isSemantics(
        value: '0',
        increasedValue: '1',
        hasIncreaseAction: true,
        hasDecreaseAction: false,
      ),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Rounds'),
      SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    expect(changes, [1]);

    await pump(tester, RoundsWheel.max);
    await tester.pump();
    expect(
      node(),
      isSemantics(
        value: '999',
        decreasedValue: '998',
        hasIncreaseAction: false,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });
}
