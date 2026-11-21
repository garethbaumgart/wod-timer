// 2.6.1 (independent retest of 2.6.0): the capsule under the wheels
// ("+ THEN" on EMOM and Tabata, "REMOVE BLOCK" on a Rest or Sets block)
// made those screens overflow at large text on an iPhone SE, where EMOM
// and Tabata fitted in 2.5.2. The space above the wheels now gives way
// first, a wheel's label shrinks to one line instead of breaking mid-word,
// and at the very largest size the capsule slims down: every size fits
// upright, and with room to spare nothing moves.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

const se = Device('iPhone SE 375x667', Size(375, 667), dpr: 2);

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  void expectCapsuleClear(WidgetTester tester, String where) {
    expect(tester.takeException(), isNull, reason: '$where: overflow');
    final capsule = tester.getRect(find.byType(SessionCapsule));
    final slab = tester.getRect(find.byType(BottomSlab));
    final wheels = find.byType(SetupWheel);
    final wheelsBottom = [
      for (final e in wheels.evaluate())
        tester.getRect(find.byWidget(e.widget)),
    ].map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
    expect(capsule.bottom, lessThanOrEqualTo(slab.top), reason: where);
    expect(capsule.top, greaterThanOrEqualTo(wheelsBottom), reason: where);
  }

  group('+ THEN on an SE at large text', () {
    for (final route in [TimerTypes.emom, TimerTypes.tabata]) {
      for (final scale in [1.0, 1.6, 2.0, 2.4, 3.1]) {
        testWidgets('$route at ${scale}x fits', (tester) async {
          await app.pump(
            tester,
            device: se,
            location: AppRoutes.timerSetupPath(route),
            textScale: scale,
          );
          expect(find.text('+ THEN'), findsOneWidget);
          expectCapsuleClear(tester, '$route ${scale}x');
        });
      }
    }
  });

  group('REMOVE BLOCK on an SE at large text', () {
    for (final block in const <SessionBlock>[
      RestBlock(seconds: 120),
      SetsBlock(sets: 5, restSeconds: 120),
      EmomBlock(intervalSeconds: 60, rounds: 10),
      TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 8),
    ]) {
      for (final scale in [1.0, 2.0, 2.4, 3.1]) {
        testWidgets('${block.kind.name} at ${scale}x fits', (tester) async {
          await app.pump(
            tester,
            device: se,
            location: AppRoutes.todaysWod,
            textScale: scale,
          );
          final draft = app.container.read(sessionDraftProvider.notifier)
            ..open([block], BuilderSource.home);
          await tester.pumpAndSettle();
          app.router.go(AppRoutes.todaysWodBlockPath(draft.state.first.id));
          await tester.pumpAndSettle();
          expect(find.text('REMOVE BLOCK'), findsOneWidget);
          expectCapsuleClear(tester, '${block.kind.name} ${scale}x');
        });
      }
    }
  });

  // The 2.6.0 layout on a phone with room for everything, measured before
  // this change: the capsule takes its room from below the wheels, never
  // from above them, so the wheels do not move.
  for (final (route, top) in [
    (TimerTypes.emom, _emomWheelTop),
    (TimerTypes.tabata, _tabataWheelTop),
  ]) {
    testWidgets('$route with room to spare: the wheels have not moved', (
      tester,
    ) async {
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.timerSetupPath(route),
      );
      final wheel = tester.getRect(find.byType(SetupWheel).first);
      expect(wheel.top, moreOrLessEquals(top, epsilon: 0.01));
    });
  }
}

const double _emomWheelTop = 180.33333333333331;
const double _tabataWheelTop = 180.33333333333331;
