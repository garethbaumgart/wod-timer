import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/review/review_prompter.dart';

part 'review_prompter_provider.g.dart';

/// Asks for a store rating at a payoff moment, under a deliberately quiet
/// policy (see [ReviewPrompter]). The whole portfolio had zero ratings on both
/// stores as of 6 Sep 2026 because no app had ever asked.
@Riverpod(keepAlive: true)
ReviewPrompter reviewPrompter(ReviewPrompterRef ref) => ReviewPrompter(
  requester: const StoreReviewRequester(),
  store: const PrefsReviewStore(),
);
