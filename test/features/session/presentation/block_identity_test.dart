// Retest fix 3 (2.6.0): an edit screen, a removal and an UNDO act on a
// block by its identity, never its position, so no order of taps can
// write one block over another or bring a block into another session.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

const sets = SetsBlock(sets: 5, restSeconds: 120);
const rest = RestBlock(seconds: 180);
const emom = EmomBlock(intervalSeconds: 60, rounds: 10);
const amrap = AmrapBlock(durationSeconds: 720);

void main() {
  setUpAll(loadOutfit);

  group('the draft', () {
    late ProviderContainer container;
    // Every change to the draft is kept as the last session (2.6.1).
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });
    tearDown(() => container.dispose());
    SessionDraft draft() => container.read(sessionDraftProvider.notifier);

    test('UNDO after a reorder puts the block back, once', () {
      draft().open(const [sets, rest, emom, amrap], BuilderSource.home);
      final removed = draft().removeById(
        container.read(sessionDraftProvider)[3].id,
      )!;
      final generation = draft().generation;
      draft().move(0, 2);
      draft().restore(removed.index, removed.entry, generation: generation);
      draft().restore(removed.index, removed.entry, generation: generation);
      expect(draft().blocks, hasLength(4));
      expect(draft().blocks.toSet(), {sets, rest, emom, amrap});
    });

    test('an UNDO from an earlier session never lands in a new one', () {
      draft().open(const [sets, emom], BuilderSource.home);
      final removed = draft().removeById(
        container.read(sessionDraftProvider)[1].id,
      )!;
      final generation = draft().generation;
      draft().open(const [], BuilderSource.home);
      draft().restore(removed.index, removed.entry, generation: generation);
      expect(draft().blocks, isEmpty);
    });

    test('an edit of a block that has gone changes nothing', () {
      draft().open(const [sets, emom], BuilderSource.home);
      final id = container.read(sessionDraftProvider)[1].id;
      draft().removeById(id);
      draft().replaceById(id, amrap);
      expect(draft().blocks, [sets]);
    });
  });

  testWidgets('an UNDO while another block is open, then DONE, keeps every '
      'block', (tester) async {
    final app = AppHarness();
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    final draft = app.container.read(sessionDraftProvider.notifier)
      ..open(const [sets, emom, amrap], BuilderSource.home);
    await tester.pumpAndSettle();
    // Swipe Sets away, open AMRAP, then the UNDO lands (however it got
    // there), then DONE.
    final removed = draft.removeById(
      app.container.read(sessionDraftProvider)[0].id,
    )!;
    final generation = draft.generation;
    await tester.pumpAndSettle();
    await tester.tap(find.text('12:00'));
    await tester.pumpAndSettle();
    expect(find.text('REMOVE BLOCK'), findsOneWidget);
    draft.restore(removed.index, removed.entry, generation: generation);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(draft.blocks, [sets, emom, amrap]);
  });
}
