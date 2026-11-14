import 'dart:async';

/// The theme tests start with a cold font cache: `bundled_fonts_test.dart`
/// pins that every Outfit weight resolves from the bundled assets with
/// runtime fetching off (Sentry WHARFWOD-1), which the shared preload in
/// `test/flutter_test_config.dart` would satisfy before the test looked.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
