import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';

/// One-time teaching hints on the live screen.
///
/// "TAP TO COUNT" shows in the AMRAP round slot only until the athlete has
/// counted a round once, ever; after that a zero count reads "0".
/// One additive key; a missing or mistyped value reads as "not yet".
class LiveHints {
  LiveHints(this._prefs);

  final SharedPreferences _prefs;

  static const countedRoundKey = 'hint_amrap_counted_round';

  bool get hasCountedRound {
    try {
      return _prefs.getBool(countedRoundKey) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> markCountedRound() async {
    if (hasCountedRound) return;
    try {
      await _prefs.setBool(countedRoundKey, true);
    } on Object {
      // A hint is a convenience; never block a workout on it.
    }
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final liveHintsProvider = Provider<LiveHints>(
  (ref) => LiveHints(ref.watch(sharedPreferencesProvider)),
);
