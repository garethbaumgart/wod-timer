import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/review/review_prompter.dart';

/// In-memory store so the policy is exercised without SharedPreferences.
class _MapStore implements ReviewStore {
  final Map<String, int> values = {};

  @override
  Future<int> readInt(String key) async => values[key] ?? 0;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;
}

class _FakeRequester implements ReviewRequester {
  _FakeRequester({this.available = true, this.throwOnRequest = false});

  final bool available;
  final bool throwOnRequest;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> request() async {
    requests++;
    if (throwOnRequest) throw StateError('store unavailable');
  }
}

void main() {
  late _MapStore store;
  late DateTime now;

  setUp(() {
    store = _MapStore();
    now = DateTime(2026, 9, 6);
  });

  ReviewPrompter build(_FakeRequester requester) =>
      ReviewPrompter(requester: requester, store: store, now: () => now);

  test('stays silent until the app has actually been useful', () async {
    final requester = _FakeRequester();
    final prompter = build(requester);

    expect(await prompter.recordValueMoment(), isFalse);
    expect(await prompter.recordValueMoment(), isFalse);
    expect(requester.requests, 0, reason: 'must not ask a first-run user');

    expect(await prompter.recordValueMoment(), isTrue);
    expect(requester.requests, 1);
  });

  test('does not ask again inside the quiet period', () async {
    final requester = _FakeRequester();
    final prompter = build(requester);
    for (var i = 0; i < 3; i++) {
      await prompter.recordValueMoment();
    }
    expect(requester.requests, 1);

    now = now.add(const Duration(days: 59));
    expect(await prompter.recordValueMoment(), isFalse);
    expect(
      requester.requests,
      1,
      reason: '59 days is inside the 60-day window',
    );
  });

  test('asks again once the quiet period has passed', () async {
    final requester = _FakeRequester();
    final prompter = build(requester);
    for (var i = 0; i < 3; i++) {
      await prompter.recordValueMoment();
    }

    now = now.add(const Duration(days: 61));
    expect(await prompter.recordValueMoment(), isTrue);
    expect(requester.requests, 2);
  });

  test('never asks more than three times in the life of the install', () async {
    final requester = _FakeRequester();
    final prompter = build(requester);
    for (var i = 0; i < 3; i++) {
      await prompter.recordValueMoment();
    }
    for (var round = 0; round < 6; round++) {
      now = now.add(const Duration(days: 61));
      await prompter.recordValueMoment();
    }
    expect(requester.requests, 3);
  });

  test(
    'does not ask when the platform says the sheet is unavailable',
    () async {
      final requester = _FakeRequester(available: false);
      final prompter = build(requester);
      for (var i = 0; i < 5; i++) {
        expect(await prompter.recordValueMoment(), isFalse);
      }
      expect(requester.requests, 0);
      expect(
        store.values[ReviewPrompter.asksKey] ?? 0,
        0,
        reason: 'an unavailable sheet must not burn an ask slot',
      );
    },
  );

  test(
    'swallows a platform failure and does not retry on every payoff',
    () async {
      final requester = _FakeRequester(throwOnRequest: true);
      final prompter = build(requester);

      for (var i = 0; i < 3; i++) {
        expect(await prompter.recordValueMoment(), isFalse);
      }
      expect(requester.requests, 1, reason: 'the throw must not escape');

      // The slot was booked before the request, so the next payoff stays quiet.
      expect(await prompter.recordValueMoment(), isFalse);
      expect(requester.requests, 1);
    },
  );

  test('counts every payoff even while it is staying silent', () async {
    final requester = _FakeRequester(available: false);
    final prompter = build(requester);
    await prompter.recordValueMoment();
    await prompter.recordValueMoment();
    expect(store.values[ReviewPrompter.momentsKey], 2);
  });
}
