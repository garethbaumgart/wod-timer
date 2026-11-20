// Retest fix 8 (2.6.0): builder and add-sheet rows line up as mocked: the
// detail right-aligned to one edge, the drag handles in one column.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/block_style.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

const blocks = [
  ForTimeBlock(capSeconds: 1200, countUp: true),
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 8),
  AmrapBlock(durationSeconds: 720),
];

void main() {
  setUpAll(loadOutfit);

  for (final device in [
    Device.phone,
    const Device('iPhone SE 375x667', Size(375, 667), dpr: 2),
    Device.tablet13,
  ]) {
    testWidgets('builder rows and the add sheet line up (${device.name})', (
      tester,
    ) async {
      final app = AppHarness();
      await app.pump(tester, device: device, location: AppRoutes.todaysWod);
      app.container
          .read(sessionDraftProvider.notifier)
          .open(blocks, BuilderSource.home);
      await tester.pumpAndSettle();

      final rights = {
        for (final b in blocks)
          tester.getRect(find.text(b.detail).first).right.toStringAsFixed(1),
      };
      expect(rights, hasLength(1), reason: 'detail right edges $rights');
      final handles = {
        for (final e in find.byIcon(Icons.drag_handle).evaluate())
          tester.getRect(find.byWidget(e.widget).first).left.toStringAsFixed(1),
      };
      expect(handles, hasLength(1), reason: 'handle columns $handles');

      await tester.tap(find.text('+ ADD BLOCK'));
      await tester.pumpAndSettle();
      final sheet = find.ancestor(
        of: find.text('Add block'),
        matching: find.byType(SingleChildScrollView),
      );
      final sheetRights = {
        for (final e
            in find
                .descendant(of: sheet, matching: find.byType(Text))
                .evaluate())
          if ((e.widget as Text).data case final String d
              when RegExp(r'\d').hasMatch(d))
            tester.getRect(find.byWidget(e.widget)).right.toStringAsFixed(1),
      };
      expect(sheetRights, hasLength(1), reason: 'sheet details $sheetRights');
    });
  }
}
