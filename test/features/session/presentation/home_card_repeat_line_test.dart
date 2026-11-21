// 2.6.1 (independent retest of 2.6.0): Home's repeat line names every
// block it can at a readable size. One FittedBox line shrank to 8.9pt
// with five named blocks and 3.7pt with twelve; now it is never drawn
// under TodaysWodCard.minSummarySize, and the blocks that will not fit
// give way to "+N".
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

const _cycle = <SessionBlock>[
  SetsBlock(sets: 5, restSeconds: 120),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  AmrapBlock(durationSeconds: 720),
  ForTimeBlock(capSeconds: 1200, countUp: true),
  TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 8),
];

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  Finder line() => find.descendant(
    of: find.byType(TodaysWodCard),
    matching: find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Sets 5'),
    ),
  );

  /// The size the line is drawn at, in points.
  double drawnSize(WidgetTester tester) {
    final shown = tester.getRect(line()).width;
    final natural = tester.renderObject<RenderParagraph>(line()).size.width;
    return 20 * shown / natural;
  }

  String text(WidgetTester tester) =>
      tester.widget<RichText>(line()).text.toPlainText();

  for (final device in [Device.phone, Device.phoneLandscape]) {
    for (final n in [1, 3, 5, 6, 8, 12]) {
      testWidgets('${device.name}, $n named blocks: readable', (tester) async {
        final blocks = [for (var i = 0; i < n; i++) _cycle[i % 5]];
        await app.pump(
          tester,
          device: device,
          stored: {
            SessionStore.lastSessionKey: SessionCodec.encode(
              WodSession(blocks),
            ),
          },
        );
        expect(tester.takeException(), isNull);
        expect(
          drawnSize(tester),
          greaterThanOrEqualTo(TodaysWodCard.minSummarySize - 0.01),
        );
        final said = text(tester);
        final named = RegExp('  ·  ').allMatches(said).length + 1;
        final more = RegExp(r'\+(\d+)$').firstMatch(said);
        if (more == null) {
          expect(named, n, reason: said);
        } else {
          // Every block counted: the names shown plus "+N".
          expect(named - 1 + int.parse(more.group(1)!), n, reason: said);
        }
      });
    }
  }

  testWidgets("the mock's three blocks are all named, at full size", (
    tester,
  ) async {
    await app.pump(
      tester,
      device: Device.phone,
      stored: {
        SessionStore.lastSessionKey: SessionCodec.encode(
          WodSession(const [
            SetsBlock(sets: 5, restSeconds: 120),
            RestBlock(seconds: 180),
            EmomBlock(intervalSeconds: 60, rounds: 10),
            RestBlock(seconds: 120),
            AmrapBlock(durationSeconds: 720),
          ]),
        ),
      },
    );
    expect(text(tester), 'Sets 5  ·  EMOM 10  ·  AMRAP 12');
  });
}
