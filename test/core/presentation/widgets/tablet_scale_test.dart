import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/widgets/tablet_scale.dart';

void main() {
  test('phones and split-view slivers are not scaled', () {
    expect(TabletScale.factorFor(const Size(390, 844)), 1);
    expect(TabletScale.factorFor(const Size(440, 956)), 1);
    expect(TabletScale.factorFor(const Size(932, 430)), 1);
    // An iPad in half split view is phone-width.
    expect(TabletScale.factorFor(const Size(507, 1366)), 1);
  });

  test('tablets lay out at a 600pt shortest side', () {
    expect(
      TabletScale.factorFor(const Size(1024, 1366)),
      closeTo(1024 / 600, 1e-9),
    );
    expect(
      TabletScale.factorFor(const Size(1194, 834)),
      closeTo(834 / 600, 1e-9),
    );
    expect(
      TabletScale.factorFor(const Size(2000, 1500)),
      TabletScale.maxFactor,
    );
  });

  Future<({Size seen, int Function() taps})> pump(
    WidgetTester tester,
    Size physical,
    double dpr,
  ) async {
    tester.view
      ..physicalSize = physical
      ..devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    late Size seen;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TabletScale(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('TAP', style: TextStyle(fontSize: 20)),
                ),
              ),
            );
          },
        ),
      ),
    );
    return (seen: seen, taps: () => taps);
  }

  testWidgets('a 12.9in iPad lays out at 600pt wide and paints full size', (
    tester,
  ) async {
    final result = await pump(tester, const Size(2048, 2732), 2);

    expect(result.seen.width, closeTo(600, 0.01));
    expect(result.seen.height, closeTo(1366 * 600 / 1024, 0.01));
    final rect = tester.getRect(find.text('TAP'));
    // Centred on the real screen, and drawn 1024/600 times its layout size.
    expect(rect.center.dx, closeTo(512, 1));
    expect(rect.center.dy, closeTo(683, 1));
    expect(
      rect.height,
      closeTo(tester.getSize(find.text('TAP')).height * 1024 / 600, 0.5),
    );
    // Taps land where the button is drawn.
    await tester.tap(find.text('TAP'));
    expect(result.taps(), 1);
  });

  testWidgets('a phone is left exactly as it was', (tester) async {
    final result = await pump(tester, const Size(1170, 2532), 3);

    expect(result.seen, const Size(390, 844));
    final rect = tester.getRect(find.text('TAP'));
    expect(rect.height, tester.getSize(find.text('TAP')).height);
  });
}
