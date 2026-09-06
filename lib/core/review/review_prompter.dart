import 'dart:async';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The platform's "rate this app" sheet. A port so tests never touch the store.
abstract class ReviewRequester {
  Future<bool> isAvailable();
  Future<void> request();
}

/// The real one. `requestReview` shows Apple's/Google's own sheet, which the OS
/// may silently decline to display — that is expected and not an error.
class StoreReviewRequester implements ReviewRequester {
  const StoreReviewRequester();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> request() => InAppReview.instance.requestReview();
}

/// Where the counters live. Two methods so the policy is testable with a Map.
abstract class ReviewStore {
  Future<int> readInt(String key);
  Future<void> writeInt(String key, int value);
}

class PrefsReviewStore implements ReviewStore {
  const PrefsReviewStore();

  @override
  Future<int> readInt(String key) async =>
      (await SharedPreferences.getInstance()).getInt(key) ?? 0;

  @override
  Future<void> writeInt(String key, int value) async =>
      (await SharedPreferences.getInstance()).setInt(key, value);
}

/// Asks for an App Store / Play rating, but only after the app has actually
/// been useful, and never often enough to nag.
///
/// **Why this exists:** on 6 Sep 2026 the whole portfolio had exactly zero
/// ratings on both stores, because no app had ever asked. Ratings drive both
/// search ranking and the install decision, so a listing with none converts
/// badly however well it ranks.
///
/// **The policy.** [recordValueMoment] is called at the app's payoff moment —
/// the batch that finished, the report that generated, the workout that ended.
/// Never at launch, never on a failure path. From there:
///
/// - the first [minValueMoments] payoffs pass silently, so a first-run user is
///   never asked before the app has earned it;
/// - at most [maxAsks] asks ever, [minDaysBetweenAsks] days apart;
/// - the ask is booked *before* the sheet is requested, so a platform error
///   can't produce a loop of retries.
///
/// iOS additionally throttles its own sheet to three displays a year and may
/// show nothing at all. That is deliberate on Apple's part: treat a request as
/// best-effort, never as a guarantee, and never gate UI on the outcome.
///
/// Nothing here may ever throw into a caller. A rating prompt is the least
/// important thing the app does; it must not be able to break the payoff screen.
class ReviewPrompter {
  ReviewPrompter({
    required this.requester,
    required this.store,
    this.now = DateTime.now,
    this.minValueMoments = 3,
    this.maxAsks = 3,
    this.minDaysBetweenAsks = 60,
  });

  static const momentsKey = 'review_value_moments';
  static const asksKey = 'review_ask_count';
  static const lastAskedKey = 'review_last_asked_ms';

  final ReviewRequester requester;
  final ReviewStore store;

  /// Injectable clock: the quiet-period rule is the whole policy, so it has to
  /// be testable without waiting sixty days.
  final DateTime Function() now;

  final int minValueMoments;
  final int maxAsks;
  final int minDaysBetweenAsks;

  /// Record one payoff and ask for a rating if the policy allows it.
  /// Returns true only when the sheet was actually requested — for tests.
  Future<bool> recordValueMoment() async {
    try {
      final moments = await store.readInt(momentsKey) + 1;
      await store.writeInt(momentsKey, moments);
      if (moments < minValueMoments) return false;

      final asks = await store.readInt(asksKey);
      if (asks >= maxAsks) return false;

      final lastMs = await store.readInt(lastAskedKey);
      if (lastMs > 0) {
        final since = now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (since.inDays < minDaysBetweenAsks) return false;
      }

      if (!await requester.isAvailable()) return false;

      // Book the ask BEFORE requesting: if the platform throws, we have still
      // spent this slot rather than re-asking on every subsequent payoff.
      await store.writeInt(asksKey, asks + 1);
      await store.writeInt(lastAskedKey, now().millisecondsSinceEpoch);
      await requester.request();
      return true;
    } on Object {
      // A rating prompt must never surface as an error in the app.
      return false;
    }
  }
}
