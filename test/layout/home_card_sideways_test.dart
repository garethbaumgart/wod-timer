// 2.6.1 (independent retest of 2.6.0): Home's card on real phones held
// sideways, with the notch side's safe-area insets the layout tests' plain
// 844x390 phone never had. On an iPhone 16 and 16 Pro the header's
// "TODAY'S WOD" fitted but the gap before the note did not, and the row
// overflowed by 2.5 to 7.8pt.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

/// (name, size in pt, left and right inset in pt)
const _phones = [
  ('iPhone 16 Pro', Size(874, 402), 62.0),
  ('iPhone 16', Size(852, 393), 59.0),
  ('iPhone 16 Pro Max', Size(956, 440), 62.0),
  ('iPhone 13 mini', Size(812, 375), 50.0),
  ('iPhone SE', Size(667, 375), 0.0),
];

const _blocks = [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  RestBlock(seconds: 120),
  AmrapBlock(durationSeconds: 720),
];

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  for (final (name, size, side) in _phones) {
    for (final withSession in [false, true]) {
      testWidgets('$name sideways, '
          '${withSession ? 'with a session' : 'empty card'}: fits', (
        tester,
      ) async {
        final padding = FakeViewPadding(
          left: side * 3,
          right: side * 3,
          bottom: 21 * 3,
        );
        tester.view
          ..padding = padding
          ..viewPadding = padding;
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await app.pump(
          tester,
          device: Device('$name landscape', size),
          stored: {
            if (withSession)
              SessionStore.lastSessionKey: SessionCodec.encode(
                WodSession(_blocks),
              ),
          },
        );
        expect(tester.takeException(), isNull);
        // The label is always there, whole or shrunk.
        expect(
          find.descendant(
            of: find.byType(TodaysWodCard),
            matching: find.text("TODAY'S WOD"),
          ),
          findsOneWidget,
        );
      });
    }
  }
}
