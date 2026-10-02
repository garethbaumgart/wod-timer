import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/placeholder_pages.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

class _MockHapticService extends Mock implements IHapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> selected;

  /// Pumps Home on a [width] x [height] screen with [stored] as the device's
  /// SharedPreferences and the system text size at [textScale].
  Future<void> pumpHome(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double textScale = 1,
    Map<String, Object> stored = const {},
  }) async {
    tester.view
      ..physicalSize = Size(width * 3, height * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(Map.of(stored));
    final prefs = await SharedPreferences.getInstance();
    final haptic = _MockHapticService();
    when(haptic.lightImpact).thenAnswer((_) async => right(unit));
    selected = [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          hapticServiceProvider.overrideWithValue(haptic),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: PlaceholderHomePage(onTimerSelected: selected.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each strip shows its default setup and no tagline', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('CAP 20:00 · UP'), findsOneWidget);
    expect(find.text('10 × 1:00'), findsOneWidget);
    expect(find.text('8 × 20s / 10s'), findsOneWidget);

    // The old furniture is gone.
    expect(find.text('Voice-coached gym timer'), findsNothing);
    expect(find.text('Max rounds in time'), findsNothing);
    expect(find.text('Every minute on the minute'), findsNothing);
    expect(find.text('›'), findsNothing);
  });

  testWidgets('strips read the remembered setup for each mode', (
    tester,
  ) async {
    await pumpHome(
      tester,
      stored: {
        SetupMemory.amrapDurationKey: 720,
        SetupMemory.forTimeCapKey: 900,
        SetupMemory.forTimeCountUpKey: false,
        SetupMemory.emomIntervalKey: 90,
        SetupMemory.emomRoundsKey: 12,
        SetupMemory.tabataWorkKey: 65,
        SetupMemory.tabataRestKey: 15,
        SetupMemory.tabataRoundsKey: 6,
      },
    );

    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('CAP 15:00 · DOWN'), findsOneWidget);
    expect(find.text('12 × 1:30'), findsOneWidget);
    expect(find.text('6 × 1:05 / 15s'), findsOneWidget);
  });

  testWidgets('name and setup share one row, setup at the right', (
    tester,
  ) async {
    await pumpHome(tester);

    final name = tester.getRect(find.text('EMOM'));
    final config = tester.getRect(find.text('10 × 1:00'));
    expect(config.left, greaterThan(name.right));
    expect((config.center.dy - name.center.dy).abs(), lessThan(4));
    // Flush right inside the strip: 18pt screen + 14pt strip padding.
    expect(config.right, closeTo(390 - 18 - 14 - 1, 2));
    expect(tester.getSize(find.text('EMOM')).height, greaterThan(28));
  });

  testWidgets('the screen reader hears the setup, not a description', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(
      find.bySemanticsLabel(
        'EMOM timer. 10 rounds of 1 minute. Double tap to select.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'FOR TIME timer. Cap 20 minutes, counts up. Double tap to select.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a strip selects its mode', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('8 × 20s / 10s'));
    await tester.pump();
    expect(selected, ['tabata']);
  });

  testWidgets('all four strips fit an 844 x 390 landscape screen', (
    tester,
  ) async {
    await pumpHome(tester, width: 844, height: 390);

    expect(tester.takeException(), isNull);
    final amrap = tester.getRect(find.text('AMRAP'));
    final tabata = tester.getRect(find.text('TABATA'));
    final tabataStrip = tester.getRect(
      find
          .ancestor(of: find.text('TABATA'), matching: find.byType(InkWell))
          .first,
    );
    expect(amrap.top, greaterThanOrEqualTo(0));
    expect(tabata.bottom, lessThan(390));
    expect(tabataStrip.bottom, lessThanOrEqualTo(390 - 8));
    // Nothing had to scroll to get there.
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });

  // Older users run a large system text size; Home must still lay out.
  testWidgets('large text (1.6x at 375pt) lays out without overflow', (
    tester,
  ) async {
    await pumpHome(tester, width: 375, height: 812, textScale: 1.6);
    expect(tester.takeException(), isNull);
    expect(find.text('TABATA'), findsOneWidget);
  });
}
