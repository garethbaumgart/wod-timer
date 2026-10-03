import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/placeholder_pages.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/tablet_scale.dart';
import 'package:wod_timer/core/presentation/widgets/wordmark.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

class _MockHapticService extends Mock implements IHapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> selected;

  /// Pumps Home on a [width] x [height] screen with [stored] as the device's
  /// SharedPreferences and the system text size at [textScale]. With
  /// [tablet] the app's TabletScale wraps it, as in main.dart.
  Future<void> pumpHome(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double dpr = 3,
    double textScale = 1,
    bool tablet = false,
    Map<String, Object> stored = const {},
  }) async {
    tester.view
      ..physicalSize = Size(width * dpr, height * dpr)
      ..devicePixelRatio = dpr;
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
          builder: (context, child) {
            final scaled = MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            );
            return tablet ? TabletScale(child: scaled) : scaled;
          },
          home: PlaceholderHomePage(onTimerSelected: selected.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder cardOf(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first;

  TimelinePainter timelineOf(WidgetTester tester, String name) {
    final paint = find.descendant(
      of: cardOf(name),
      matching: find.byType(CustomPaint),
    );
    return tester.widget<CustomPaint>(paint.last).painter! as TimelinePainter;
  }

  testWidgets('each card shows its default setup, timeline and total', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('CAP 20:00 · UP'), findsOneWidget);
    expect(find.text('10 × 1:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('8 × 20s / 10s'), findsOneWidget);
    expect(find.text('20:00 total'), findsOneWidget);
    expect(find.text('10:00 total'), findsNWidgets(2));
    expect(find.text('4:00 total'), findsOneWidget);
    expect(find.byType(WorkoutTimeline), findsNWidgets(4));

    // The old furniture is gone.
    expect(find.text('Voice-coached gym timer'), findsNothing);
    expect(find.text('›'), findsNothing);
  });

  testWidgets('modes read For Time, EMOM, AMRAP, Tabata top to bottom', (
    tester,
  ) async {
    await pumpHome(tester);

    final tops = [
      for (final name in ['FOR TIME', 'EMOM', 'AMRAP', 'TABATA'])
        tester.getRect(find.text(name)).top,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(4));
  });

  testWidgets('cards read the remembered setup for each mode', (tester) async {
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
    expect(find.text('18:00 total'), findsOneWidget);
    expect(find.text('8:00 total'), findsOneWidget);
    expect(timelineOf(tester, 'EMOM').shape.parts, hasLength(12));
    expect(timelineOf(tester, 'TABATA').shape.parts, hasLength(12));
  });

  testWidgets('name and setup share one row, timeline and total under', (
    tester,
  ) async {
    await pumpHome(tester);

    final name = tester.getRect(find.text('EMOM'));
    final config = tester.getRect(find.text('10 × 1:00'));
    expect(config.left, greaterThan(name.right));
    expect((config.center.dy - name.center.dy).abs(), lessThan(4));
    // Flush right inside the card: 18pt screen + 16pt card padding.
    expect(config.right, closeTo(390 - 18 - 16 - 1, 2));
    expect(tester.widget<Text>(find.text('EMOM')).style!.fontSize, 28);
    expect(tester.widget<Text>(find.text('10 × 1:00')).style!.fontSize, 18);

    final timeline = tester.getRect(
      find.descendant(
        of: cardOf('EMOM'),
        matching: find.byType(WorkoutTimeline),
      ),
    );
    expect(timeline.top, greaterThan(name.bottom));
    expect(timeline.height, 12);
    expect(timeline.left, closeTo(name.left - 18, 1)); // under the bar
    final total = tester.getRect(find.text('10:00 total').first);
    expect(total.top, greaterThan(timeline.bottom));
    expect(total.right, closeTo(config.right, 1));
    expect(
      tester.widget<Text>(find.text('10:00 total').first).style!.color,
      AppColors.textSecondaryDark,
    );
  });

  testWidgets('each card leads with its mode colour bar and timeline', (
    tester,
  ) async {
    await pumpHome(tester);

    const modes = {
      'FOR TIME': AppColors.forTimeAccent,
      'EMOM': AppColors.emomAccent,
      'AMRAP': AppColors.amrapAccent,
      'TABATA': AppColors.tabataAccent,
    };
    for (final MapEntry(key: name, value: color) in modes.entries) {
      final bar = find.descendant(
        of: cardOf(name),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == 4 &&
              (w.decoration as BoxDecoration?)?.color == color,
        ),
      );
      expect(bar, findsOneWidget, reason: name);
      expect(
        tester.getRect(bar).right,
        lessThan(tester.getRect(find.text(name)).left),
      );
      expect(timelineOf(tester, name).shape.accent, color, reason: name);
      expect(timelineOf(tester, name).elapsedSeconds, isNull);
    }
    final tabata = timelineOf(tester, 'TABATA').shape;
    expect(tabata.colorOf(tabata.parts[1]), AppColors.rest);
  });

  testWidgets('mode names are white under the stacked wordmark', (
    tester,
  ) async {
    await pumpHome(tester);

    for (final name in ['AMRAP', 'FOR TIME', 'EMOM', 'TABATA']) {
      expect(
        tester.widget<Text>(find.text(name)).style?.color,
        AppColors.textPrimaryDark,
        reason: name,
      );
    }
    expect(find.byType(Wordmark), findsOneWidget);
    expect(find.text('WHARF'), findsOneWidget);
    expect(find.bySemanticsLabel('Wharf WOD'), findsOneWidget);
    expect(
      tester.getRect(find.byType(Wordmark)).bottom,
      lessThan(tester.getRect(find.text('FOR TIME')).top),
    );
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

  testWidgets('tapping a card selects its mode', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('8 × 20s / 10s'));
    await tester.pump();
    expect(selected, ['tabata']);
  });

  testWidgets('all four cards fit an 844 x 390 landscape screen', (
    tester,
  ) async {
    await pumpHome(tester, width: 844, height: 390);

    expect(tester.takeException(), isNull);
    final first = tester.getRect(find.text('FOR TIME'));
    final tabata = tester.getRect(find.text('TABATA'));
    expect(first.top, greaterThanOrEqualTo(0));
    expect(tabata.bottom, lessThan(390));
    expect(tester.getRect(cardOf('TABATA')).bottom, lessThanOrEqualTo(390 - 8));
    // No total line and a thinner timeline in landscape.
    expect(find.textContaining('total'), findsNothing);
    expect(tester.getSize(find.byType(WorkoutTimeline).first).height, 8);
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

  group('tablet (1.3.1)', () {
    // iPad Pro 13in: 1024 x 1366pt, laid out at 600 x 800 under TabletScale.
    Future<void> pumpIpad(
      WidgetTester tester, {
      bool landscape = false,
      Map<String, Object> stored = const {},
    }) => pumpHome(
      tester,
      width: landscape ? 1366 : 1024,
      height: landscape ? 1024 : 1366,
      dpr: 2,
      tablet: true,
      stored: stored,
    );

    testWidgets('the last mode started is the big tile, For Time by default', (
      tester,
    ) async {
      await pumpIpad(tester);
      expect(tester.takeException(), isNull);

      final hero = tester.getRect(cardOf('FOR TIME'));
      final emom = tester.getRect(cardOf('EMOM'));
      final amrap = tester.getRect(cardOf('AMRAP'));
      final tabata = tester.getRect(cardOf('TABATA'));
      expect(hero.width, greaterThan(emom.width * 2.5));
      expect(hero.bottom, lessThan(emom.top));
      expect(emom.top, amrap.top);
      expect(amrap.top, tabata.top);
      expect(emom.right, lessThan(amrap.left));
      expect(amrap.right, lessThan(tabata.left));
      expect(tester.widget<Text>(find.text('FOR TIME')).style!.fontSize, 44);
      expect(tester.widget<Text>(find.text('EMOM')).style!.fontSize, 32);
      expect(find.text('20:00 total'), findsOneWidget);
      expect(find.byType(WorkoutTimeline), findsNWidgets(4));
      expect(find.byType(Scrollable), findsNothing);
    });

    testWidgets('a Tabata started last takes the hero; the rest keep order', (
      tester,
    ) async {
      await pumpIpad(tester, stored: {SetupMemory.lastModeKey: 'tabata'});

      final hero = tester.getRect(cardOf('TABATA'));
      final forTime = tester.getRect(cardOf('FOR TIME'));
      final emom = tester.getRect(cardOf('EMOM'));
      final amrap = tester.getRect(cardOf('AMRAP'));
      expect(hero.bottom, lessThan(forTime.top));
      expect(forTime.right, lessThan(emom.left));
      expect(emom.right, lessThan(amrap.left));
    });

    testWidgets('an unknown last mode falls back to For Time', (tester) async {
      await pumpIpad(tester, stored: {SetupMemory.lastModeKey: 'yoga'});
      expect(tester.widget<Text>(find.text('FOR TIME')).style!.fontSize, 44);
    });

    testWidgets(
      'landscape puts the wordmark left and the tiles right, fitting',
      (tester) async {
        await pumpIpad(tester, landscape: true);
        expect(tester.takeException(), isNull);

        final mark = tester.getRect(find.byType(Wordmark));
        final hero = tester.getRect(cardOf('FOR TIME'));
        final tabata = tester.getRect(cardOf('TABATA'));
        expect(mark.right, lessThan(hero.left));
        expect(hero.top, greaterThanOrEqualTo(0));
        expect(tabata.bottom, lessThanOrEqualTo(1024));
        expect(tabata.right, lessThanOrEqualTo(1366));
        expect(find.byType(Scrollable), findsNothing);
      },
    );

    testWidgets('tapping a tile selects its mode', (tester) async {
      await pumpIpad(tester);
      await tester.tap(find.text('AMRAP'));
      await tester.pump();
      expect(selected, ['amrap']);
    });
  });
}
