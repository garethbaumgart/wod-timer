import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/package_info_provider.dart';
import 'package:wod_timer/core/application/providers/review_prompter_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/pages/settings_page.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/review/review_prompter.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

class _MockAudioService extends Mock implements IAudioService {}

class _MockHapticService extends Mock implements IHapticService {}

/// In-memory store so the prompter never touches SharedPreferences.
class _MapStore implements ReviewStore {
  final Map<String, int> values = {};

  @override
  Future<int> readInt(String key) async => values[key] ?? 0;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;
}

/// Counts what the settings screen asked of the store, without opening it.
class _FakeRequester implements ReviewRequester {
  int requests = 0;
  int listings = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> request() async => requests++;

  @override
  Future<void> openStoreListing() async => listings++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRequester requester;
  late _MapStore store;
  late _MockAudioService audio;
  final now = DateTime(2026, 10, 2);

  /// Pumps the settings page on a [width] x [height] portrait screen, with
  /// the system text size at [textScale].
  Future<void> pumpSettings(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = Size(width * 3, height * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    requester = _FakeRequester();
    store = _MapStore();
    audio = _MockAudioService();
    when(
      () => audio.playVoicePreview(any()),
    ).thenAnswer((_) async => right(unit));
    final haptic = _MockHapticService();
    when(haptic.selectionClick).thenAnswer((_) async => right(unit));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptic),
          reviewPrompterProvider.overrideWithValue(
            ReviewPrompter(requester: requester, store: store, now: () => now),
          ),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Wharf WOD',
              packageName: 'app.mentalmetal.wharfwod',
              version: '1.2.1',
              buildNumber: '1',
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('Rate Wharf WOD row', () {
    testWidgets('sits between Haptics and Send feedback', (tester) async {
      await pumpSettings(tester);

      final haptics = tester.getRect(find.text('Haptics'));
      final rate = tester.getRect(find.text('Rate Wharf WOD'));
      final feedback = tester.getRect(find.text('Send feedback'));
      expect(rate.top, greaterThan(haptics.bottom));
      expect(feedback.top, greaterThan(rate.bottom));
    });

    testWidgets('opens the store page once and never the automatic sheet', (
      tester,
    ) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.text('Rate Wharf WOD'));

      await tester.tap(find.text('Rate Wharf WOD'));
      await tester.pumpAndSettle();

      expect(requester.listings, 1);
      expect(requester.requests, 0, reason: 'a button may not call the sheet');
      // The visit holds off the automatic sheet without spending an ask.
      expect(
        store.values[ReviewPrompter.lastAskedKey],
        now.millisecondsSinceEpoch,
      );
      expect(store.values[ReviewPrompter.asksKey] ?? 0, 0);
      // rate_tapped goes through trackEvent, which is a no-op outside release
      // builds, so it is not observable here.
    });
  });

  group('Flat list', () {
    testWidgets('six rows in order, no section headers', (tester) async {
      await pumpSettings(tester);

      const order = [
        'Orientation',
        'Voice',
        'Haptics',
        'Rate Wharf WOD',
        'Send feedback',
        'Privacy policy',
      ];
      final rects = [
        for (final label in order) tester.getRect(find.text(label)),
      ];
      for (var i = 1; i < rects.length; i++) {
        expect(
          rects[i].top,
          greaterThan(rects[i - 1].bottom),
          reason: order[i],
        );
        // Evenly spaced: nothing (a header, a caption) sits between rows.
        expect(
          rects[i].top - rects[i - 1].top,
          closeTo(rects[1].top - rects[0].top, 6),
          reason: order[i],
        );
      }

      for (final gone in [
        'DISPLAY',
        'AUDIO',
        'ABOUT',
        'Haptic Feedback',
        'Version',
        'Voice cues play through the silent switch.',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('rows are 17pt, white labels and grey values', (tester) async {
      await pumpSettings(tester);

      for (final label in ['Orientation', 'Haptics', 'Privacy policy']) {
        final style = tester.widget<Text>(find.text(label)).style!;
        expect(style.fontSize, 17, reason: label);
        expect(style.color, AppColors.textPrimaryDark, reason: label);
      }
      final value = tester.widget<Text>(find.text('Auto >')).style!;
      expect(value.fontSize, 17);
      expect(value.color, AppColors.textSecondaryDark);
    });

    testWidgets('the version is a centred 15pt grey footer', (tester) async {
      await pumpSettings(tester);

      final footer = find.text('Wharf WOD 1.2.1 (1)');
      expect(footer, findsOneWidget);
      final style = tester.widget<Text>(footer).style!;
      expect(style.fontSize, 15);
      expect(style.color, AppColors.textSecondaryDark);
      final rect = tester.getRect(footer);
      expect(rect.center.dx, closeTo(390 / 2, 1));
      expect(
        rect.top,
        greaterThan(tester.getRect(find.text('Privacy policy')).bottom),
      );
    });
  });

  group('Voice picker', () {
    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
    }

    Finder playButton(String voice) => find.byTooltip('Preview $voice');

    testWidgets('preview leads each row, the check trails it', (tester) async {
      await pumpSettings(tester);
      await openPicker(tester);

      // No leading voice icons any more.
      for (final icon in [
        Icons.record_voice_over,
        Icons.shuffle,
        Icons.volume_down,
        Icons.volume_off,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
      expect(find.byIcon(Icons.play_circle_outline), findsNWidgets(4));
      for (final voice in ['Beeps', 'Silent']) {
        expect(playButton(voice), findsNothing, reason: voice);
      }

      final major = tester.getRect(find.text('Major (CrossFit Coach)'));
      final play = tester.getRect(
        find
            .ancestor(of: playButton('Major'), matching: find.byType(SizedBox))
            .first,
      );
      final check = tester.getRect(find.byIcon(Icons.check));
      expect(play.size, const Size(48, 48));
      expect(play.left, lessThan(24));
      expect(play.right, lessThan(major.left));
      expect(check.left, greaterThan(major.right));
      expect(check.right, greaterThan(390 - 40));
      // The empty 48pt slot keeps rows without a preview aligned.
      expect(tester.getRect(find.text('Beeps only')).left, major.left);
      expect(tester.getRect(find.text('Silent')).left, major.left);
    });

    testWidgets('play previews without selecting or closing', (tester) async {
      await pumpSettings(tester);
      await openPicker(tester);

      await tester.tap(playButton('Liam'));
      await tester.pumpAndSettle();

      verify(() => audio.playVoicePreview('liam')).called(1);
      expect(find.text('Liam (Old British Man)'), findsOneWidget);
      expect(find.text('Major >'), findsOneWidget);
    });

    testWidgets('tapping the row selects and closes', (tester) async {
      await pumpSettings(tester);
      await openPicker(tester);

      await tester.tap(find.text('Liam (Old British Man)'));
      await tester.pumpAndSettle();

      expect(find.text('Liam (Old British Man)'), findsNothing);
      expect(find.text('Liam >'), findsOneWidget);
      verifyNever(() => audio.playVoicePreview(any()));
    });

    testWidgets('the silent-switch line sits at the bottom of the sheet', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openPicker(tester);

      final caption = find.text('Voice cues play through the silent switch.');
      expect(caption, findsOneWidget);
      final style = tester.widget<Text>(caption).style!;
      expect(style.fontSize, 15);
      expect(style.color, AppColors.textSecondaryDark);
      expect(
        tester.getRect(caption).top,
        greaterThan(tester.getRect(find.text('Silent')).bottom),
      );
    });

    testWidgets('large text (1.6x at 375pt) lays out without overflow', (
      tester,
    ) async {
      await pumpSettings(tester, width: 375, height: 812, textScale: 1.6);
      await openPicker(tester);
      expect(tester.takeException(), isNull);
    });
  });

  // Older users run a large system text size; the whole page, the new row
  // included, must still lay out on a 375pt-wide phone.
  testWidgets('large text (1.6x at 375pt) lays out without overflow', (
    tester,
  ) async {
    await pumpSettings(tester, width: 375, height: 812, textScale: 1.6);
    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.text('Wharf WOD 1.2.1 (1)'));
    expect(tester.takeException(), isNull);
    expect(find.text('Rate Wharf WOD'), findsOneWidget);
  });
}
