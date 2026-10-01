import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's SharedPreferences, loaded once in `main()` before the first
/// frame so setup screens can open on remembered values synchronously.
///
/// Always overridden at the root `ProviderScope` (and in tests). Written by
/// hand: riverpod_generator 2.6's analyzer can't parse the Flutter 3.47 SDK.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a loaded instance',
  ),
);
