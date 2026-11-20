// Retest fix 2 (2.6.0): the "REMOVED · UNDO" bar shows for a few seconds
// only, goes the moment she leaves the builder (START, back, an edit
// screen, the add sheet), never reaches a live screen, and is readable.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  SessionDraft draft() => app.container.read(sessionDraftProvider.notifier);

  /// The builder with Sets and EMOM, the EMOM swiped away.
  Future<void> removeEmom(WidgetTester tester) async {
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    draft().open(const [
      SetsBlock(sets: 5, restSeconds: 120),
      EmomBlock(intervalSeconds: 60, rounds: 10),
    ], BuilderSource.home);
    await tester.pumpAndSettle();
    await tester.drag(find.text('10 × 1:00'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('EMOM REMOVED'), findsOneWidget);
  }

  testWidgets('goes away by itself within a few seconds', (tester) async {
    await removeEmom(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('EMOM REMOVED'), findsNothing);
  });

  testWidgets('UNDO reads clearly: a light label on the dark bar', (
    tester,
  ) async {
    await removeEmom(tester);
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    expect(action.textColor, AppColors.primary);
  });

  testWidgets('START: gone, and never on the live screen', (tester) async {
    await removeEmom(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.router.state.uri.path, AppRoutes.todaysWodActive);
    expect(find.text('EMOM REMOVED'), findsNothing);
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('back Home: gone, and a new session never gets the block', (
    tester,
  ) async {
    await removeEmom(tester);
    app.router.go(AppRoutes.home);
    // Once the builder has slid away.
    await tester.pumpAndSettle();
    expect(find.text('UNDO'), findsNothing);
    draft().open(const [], BuilderSource.home);
    await tester.pump();
    expect(draft().blocks, isEmpty);
  });

  testWidgets('opening an edit screen: gone', (tester) async {
    await removeEmom(tester);
    await tester.tap(find.text('5 · REST 2:00'));
    await tester.pumpAndSettle();
    expect(find.text('REMOVE BLOCK'), findsOneWidget);
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('opening the add sheet: gone', (tester) async {
    await removeEmom(tester);
    await tester.tap(find.text('+ ADD BLOCK'));
    await tester.pumpAndSettle();
    expect(find.text('Add block'), findsOneWidget);
    expect(find.text('UNDO'), findsNothing);
  });
}
