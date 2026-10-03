// The settings rows that do something: the orientation picker (labels,
// icons, the check, what it persists and asks the OS for), the Haptics
// switch (persisted and pushed to the service), the two links, and the
// version footer while the package info is loading or missing.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/package_info_provider.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/pages/settings_page.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/injection.dart';

class _MockHapticService extends Mock implements IHapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockHapticService haptic;
  late List<List<String>> orientationRequests;
  late List<Map<Object?, Object?>> launches;

  setUp(() {
    orientationRequests = [];
    launches = [];
    haptic = _MockHapticService();
    when(haptic.selectionClick).thenAnswer((_) async => right(unit));
    when(
      () => haptic.setEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    getIt.registerSingleton<IHapticService>(haptic);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientationRequests.add(
            (call.arguments as List<Object?>).cast<String>(),
          );
        }
        return null;
      })
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          if (call.method == 'launch') {
            launches.add(call.arguments as Map<Object?, Object?>);
            return true;
          }
          return null;
        },
      );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, null)
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
    await getIt.reset();
  });

  Future<SharedPreferences> pumpSettings(
    WidgetTester tester, {
    Map<String, Object> stored = const {},
    Future<PackageInfo> Function()? packageInfo,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(Map.of(stored));
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hapticServiceProvider.overrideWithValue(haptic),
          packageInfoProvider.overrideWith(
            (ref) =>
                packageInfo?.call() ??
                Future.value(
                  PackageInfo(
                    appName: 'Wharf WOD',
                    packageName: 'app.mentalmetal.wharfwod',
                    version: '2.0.0',
                    buildNumber: '18',
                  ),
                ),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  group('Orientation', () {
    testWidgets('the row opens a sheet with the three modes, current ticked', (
      tester,
    ) async {
      await pumpSettings(tester, stored: {'app_orientation_lock': 1});
      expect(find.text('Portrait >'), findsOneWidget);

      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      verify(haptic.selectionClick).called(1);

      expect(find.text('Auto (follow device)'), findsOneWidget);
      expect(find.text('Portrait only'), findsOneWidget);
      expect(find.text('Landscape only'), findsOneWidget);
      expect(find.byIcon(Icons.screen_rotation), findsOneWidget);
      expect(find.byIcon(Icons.stay_current_portrait), findsOneWidget);
      expect(find.byIcon(Icons.stay_current_landscape), findsOneWidget);
      final check = find.byIcon(Icons.check);
      expect(check, findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(of: check, matching: find.byType(ListTile)),
          matching: find.text('Portrait only'),
        ),
        findsOneWidget,
        reason: 'the check sits on the current mode',
      );
      expect(tester.widget<Icon>(check).color, AppColors.primary);
    });

    testWidgets('choosing Landscape persists it, locks the OS, closes', (
      tester,
    ) async {
      final prefs = await pumpSettings(tester);
      expect(find.text('Auto >'), findsOneWidget);
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      orientationRequests.clear();

      await tester.tap(find.text('Landscape only'));
      await tester.pumpAndSettle();

      expect(find.text('Landscape only'), findsNothing, reason: 'sheet closed');
      expect(find.text('Landscape >'), findsOneWidget);
      expect(
        prefs.getInt('app_orientation_lock'),
        OrientationLockMode.landscape.index,
      );
      expect(orientationRequests, [
        ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight'],
      ]);
      verify(haptic.selectionClick).called(2);
    });

    testWidgets('Auto frees all four orientations; Portrait the two upright', (
      tester,
    ) async {
      await pumpSettings(tester, stored: {'app_orientation_lock': 2});
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      orientationRequests.clear();
      await tester.tap(find.text('Auto (follow device)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portrait only'));
      await tester.pumpAndSettle();
      expect(orientationRequests, [
        [
          'DeviceOrientation.portraitUp',
          'DeviceOrientation.portraitDown',
          'DeviceOrientation.landscapeLeft',
          'DeviceOrientation.landscapeRight',
        ],
        ['DeviceOrientation.portraitUp', 'DeviceOrientation.portraitDown'],
      ]);
    });
  });

  group('Haptics', () {
    testWidgets('the switch persists and reaches the haptic service', (
      tester,
    ) async {
      final prefs = await pumpSettings(tester);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(prefs.getBool('app_haptic_enabled'), isFalse);
      verify(() => haptic.setEnabled(enabled: false)).called(1);
      verify(haptic.selectionClick).called(1);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(prefs.getBool('app_haptic_enabled'), isTrue);
      verify(() => haptic.setEnabled(enabled: true)).called(greaterThan(0));
    });

    testWidgets('a stored Haptics off opens the switch off', (tester) async {
      await pumpSettings(tester, stored: {'app_haptic_enabled': false});
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });

  group('links', () {
    testWidgets('Send feedback opens a mail to support with the subject', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(
        launches.single['url'],
        'mailto:support@mentalmetal.app?subject=Wharf%20WOD%20feedback',
      );
    });

    testWidgets('Privacy policy opens the site page outside the app', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(
        launches.single['url'],
        'https://mentalmetal.app/wharf-wod/privacy',
      );
      expect(launches.single['useWebView'], isFalse);
      expect(launches.single['useSafariVC'], isFalse);
    });
  });

  group('version footer', () {
    testWidgets('shows the version and build once known', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Wharf WOD 2.0.0 (18)'), findsOneWidget);
    });

    testWidgets('reads just the name while loading or when it fails', (
      tester,
    ) async {
      final never = Completer<PackageInfo>();
      await pumpSettings(tester, packageInfo: () => never.future);
      expect(find.text('Wharf WOD'), findsOneWidget);

      await pumpSettings(
        tester,
        packageInfo: () => Future.error(StateError('no platform')),
      );
      expect(find.text('Wharf WOD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
