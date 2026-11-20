// The audio session (and the Android focus that ducks the music) is held
// from the first beep to the end of the last line and then released, even
// when a player never says it finished (Android's low-latency player).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/core/infrastructure/audio/session_lease.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  bool active = true;

  @override
  void cancel() => active = false;
  @override
  bool get isActive => active;
  @override
  int get tick => 0;

  void fire() {
    if (!active) return;
    active = false;
    callback();
  }
}

void main() {
  late int activations;
  late int deactivations;
  late List<_FakeTimer> timers;
  late SessionLease lease;

  setUp(() {
    activations = 0;
    deactivations = 0;
    timers = [];
    lease = SessionLease(
      onActivate: () async => activations++,
      onDeactivate: () async => deactivations++,
      releaseAfter: AudioService.releaseAfter,
      startTimer: (duration, callback) {
        final timer = _FakeTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
  });

  /// Lets the unawaited timeout release settle.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('overlapping cues share one activation and release after the last',
      () async {
    await lease.acquire('beep_0');
    await lease.acquire('voice_0');
    expect(activations, 1);
    expect(lease.active, 2);
    await lease.complete('beep_0');
    expect(deactivations, 0, reason: 'the line is still playing');
    await lease.complete('voice_0');
    expect(deactivations, 1);
    expect(lease.active, 0);
  });

  test('a player that never reports completion is released by the timeout',
      () async {
    await lease.acquire('voice_0');
    expect(timers.single.duration, AudioService.releaseAfter);
    timers.single.fire();
    await settle();
    expect(deactivations, 1);
    expect(lease.active, 0);
    await lease.complete('voice_0');
    expect(deactivations, 1, reason: 'a late completion releases nothing');
  });

  test('completion first cancels the timeout, so nothing releases twice',
      () async {
    await lease.acquire('voice_0');
    await lease.complete('voice_0');
    expect(timers.single.isActive, isFalse);
    timers.single.fire();
    await settle();
    expect(deactivations, 1);
  });

  test('a new clip on the same player takes over its hold without a flap',
      () async {
    await lease.acquire('voice_0');
    await lease.acquire('voice_0');
    expect(activations, 1);
    expect(deactivations, 0);
    expect(lease.active, 1);
    timers.first.fire(); // the replaced hold's timeout: already handed over
    await settle();
    expect(deactivations, 0);
    await lease.complete('voice_0');
    expect(deactivations, 1);
    expect(lease.active, 0);
  });

  test('the timeout outlasts the longest clip', () {
    expect(
      AudioService.releaseAfter,
      greaterThanOrEqualTo(const Duration(milliseconds: 1700)),
      reason: '"complete" is 1.7s; shorter would cut the session under it',
    );
    expect(
      AudioService.releaseAfter,
      lessThanOrEqualTo(const Duration(seconds: 3)),
      reason: 'the music should come back soon after the line',
    );
  });

  test('releaseAll drops every hold and deactivates once', () async {
    await lease.acquire('beep_0');
    await lease.acquire('voice_0');
    await lease.releaseAll();
    expect(deactivations, 1);
    expect(lease.active, 0);
    await lease.complete('beep_0');
    expect(deactivations, 1);
  });

  test('a failed activation leaves nothing held', () async {
    final failing = SessionLease(
      onActivate: () async => throw Exception('no focus'),
      onDeactivate: () async => deactivations++,
      releaseAfter: AudioService.releaseAfter,
      startTimer: (duration, callback) => _FakeTimer(duration, callback),
    );
    await expectLater(failing.acquire('voice_0'), throwsException);
    expect(failing.active, 0);
    await failing.complete('voice_0');
    expect(deactivations, 0);
  });
}
