import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wod_timer/core/presentation/theme/app_fonts.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

// Regression guard for Sentry WHARFWOD-1 ("Failed to load font with url:
// https://fonts.gstatic.com/..."): google_fonts fetched Outfit at runtime, so
// a cold start with no connectivity crashed the session — 19 fatal events on
// 9 Aug 2026 (59% of the month's sessions). The fix bundles all nine Outfit
// weights in assets/fonts/ and disables runtime fetching; these tests pin
// both halves so the crash class cannot come back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configureBundledFonts turns runtime font fetching off', () {
    configureBundledFonts();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('all nine Outfit weights are bundled under the names google_fonts '
      'resolves', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    const weightNames = [
      'Thin',
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ];
    for (final name in weightNames) {
      expect(
        assets,
        contains('assets/fonts/Outfit-$name.ttf'),
        reason: 'Outfit-$name.ttf is missing: with runtime fetching disabled '
            'a request for this weight throws the exact WHARFWOD-1 exception',
      );
    }
  });

  test('the bundled OFL license is registered', () async {
    configureBundledFonts();

    final entries = await LicenseRegistry.licenses
        .where((entry) => entry.packages.contains('Outfit'))
        .toList();

    expect(entries, isNotEmpty);
  });

  testWidgets(
    'every text style the app can request loads from bundled fonts with '
    'fetching disabled',
    (_) async {
      configureBundledFonts();

      // Touching a style schedules its font load. Cover both real themes plus
      // the full weight axis — google_fonts snaps any request to one of the
      // nine Outfit API variants, so this sweep is exhaustive.
      final themed = <Object>[
        AppTheme.light,
        AppTheme.dark,
        AppTypography.outfitTextTheme,
      ];
      final sweep = FontWeight.values
          .map((weight) => GoogleFonts.outfit(fontWeight: weight))
          .toList();

      expect(themed, hasLength(3));
      expect(sweep, hasLength(FontWeight.values.length));
      for (final style in sweep) {
        expect(style.fontFamily, startsWith('Outfit'));
      }

      // Completes only if every scheduled variant resolved from the asset
      // bundle — with fetching disabled, a single miss rejects this future
      // with the same exception class that crashed offline sessions.
      await GoogleFonts.pendingFonts();
    },
  );
}
