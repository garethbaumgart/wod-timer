// The real router: every route lands on its screen, bad paths land on a
// placeholder instead of crashing, and the chevrons, settings icon and
// "Go to Setup" move between screens the way the Android back tests
// expect them to.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/presentation/pages/settings_page.dart';
import 'package:wod_timer/core/presentation/router/app_router.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/router/placeholder_pages.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';

import '../../../helpers/screen_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late GoRouter router;
  late MockHapticService haptic;

  Future<void> pumpApp(WidgetTester tester, {String at = AppRoutes.home}) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    LiveHarness.mockPlatformChannels();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    haptic = MockHapticService();
    when(haptic.lightImpact).thenAnswer((_) async => right(unit));
    when(haptic.selectionClick).thenAnswer((_) async => right(unit));
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioServiceProvider.overrideWithValue(MockAudioService()),
        hapticServiceProvider.overrideWithValue(haptic),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    if (at != AppRoutes.home) {
      router.go(at);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('opens on Home', (tester) async {
    await pumpApp(tester);
    expect(find.byType(PlaceholderHomePage), findsOneWidget);
    expect(find.text('FOR TIME'), findsOneWidget);
  });

  testWidgets('each mode path opens its setup screen', (tester) async {
    await pumpApp(tester);
    final pages = <String, Type>{
      TimerTypes.amrap: AmrapSetupPage,
      TimerTypes.forTime: ForTimeSetupPage,
      TimerTypes.emom: EmomSetupPage,
      TimerTypes.tabata: TabataSetupPage,
    };
    for (final entry in pages.entries) {
      router.go(AppRoutes.timerSetupPath(entry.key));
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text('START'), findsOneWidget);
    }
  });

  testWidgets('tapping a Home card opens that setup, with a light tap', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    expect(find.byType(TabataSetupPage), findsOneWidget);
    verify(haptic.lightImpact).called(1);

    // The header chevron goes Home.
    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceholderHomePage), findsOneWidget);
  });

  testWidgets('an unknown mode is a placeholder, not a crash', (tester) async {
    await pumpApp(tester, at: '/timer/yoga');
    expect(find.byType(PlaceholderPage), findsOneWidget);
    expect(find.text('Invalid Timer Type'), findsNWidgets(2));
    expect(find.text('The selected timer type is not valid.'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown path lands on Page Not Found', (tester) async {
    await pumpApp(tester, at: '/nowhere/at/all');
    expect(find.text('Page Not Found'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live route without a session offers the way back', (
    tester,
  ) async {
    await pumpApp(tester, at: AppRoutes.timerActivePath(TimerTypes.emom));
    expect(find.byType(TimerActivePage), findsOneWidget);
    expect(find.text('Timer Not Started'), findsOneWidget);
    await tester.tap(find.text('Go to Setup'));
    await tester.pumpAndSettle();
    expect(find.byType(EmomSetupPage), findsOneWidget);
  });

  testWidgets('the live route without a session: Android back goes to setup', (
    tester,
  ) async {
    await pumpApp(tester, at: AppRoutes.timerActivePath(TimerTypes.amrap));
    // PopScope only wraps a configured timer; the not-started screen is a
    // plain page, so back pops to the parent setup route.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AmrapSetupPage), findsOneWidget);
  });

  testWidgets('the settings icon opens Settings; its chevron goes Home', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceholderHomePage), findsOneWidget);
  });

  // Flutter 3.50: go_router before 18 looked for the in-framework
  // MaterialApp to pick its page type. Under material_ui's MaterialApp it
  // found none and fell back to NoTransitionPage, so setup and the live
  // screen appeared with no slide and iOS lost its swipe back, while every
  // other test here stayed green.
  Future<void> expectSlidesIn(WidgetTester tester, Type page) async {
    // Mid-flight: the navigation resolves on the next frame, then the page
    // starts its entrance.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final route = ModalRoute.of(
      tester.element(find.byType(page, skipOffstage: false)),
    )!;
    expect(route, isA<PageRoute<void>>());
    expect(
      route.transitionDuration,
      greaterThan(Duration.zero),
      reason: 'go_router fell back to NoTransitionPage',
    );
    await tester.pumpAndSettle();
    expect(find.byType(page), findsOneWidget);
  }

  testWidgets(
    'a Home card slides its setup in, as a Material page does',
    (tester) async {
      await pumpApp(tester);
      router.go(AppRoutes.timerSetupPath(TimerTypes.emom));
      await expectSlidesIn(tester, EmomSetupPage);
    },
    variant: const TargetPlatformVariant(
      {TargetPlatform.android, TargetPlatform.iOS},
    ),
  );

  testWidgets(
    'START slides the live screen in over its setup',
    (tester) async {
      await pumpApp(tester, at: AppRoutes.timerSetupPath(TimerTypes.amrap));
      router.go(AppRoutes.timerActivePath(TimerTypes.amrap));
      await expectSlidesIn(tester, TimerActivePage);
    },
    variant: const TargetPlatformVariant(
      {TargetPlatform.android, TargetPlatform.iOS},
    ),
  );

  test('route paths are built from the mode code', () {
    expect(AppRoutes.timerSetupPath('emom'), '/timer/emom');
    expect(AppRoutes.timerActivePath('emom'), '/timer/emom/active');
    expect(TimerTypes.all, ['amrap', 'fortime', 'emom', 'tabata']);
    expect(TimerTypes.isValid('tabata'), isTrue);
    expect(TimerTypes.isValid('TABATA'), isFalse);
  });
}
