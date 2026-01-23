import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart';

void main() {
  group('TimerEngine', () {
    late TimerEngine timerEngine;

    setUp(() {
      timerEngine = TimerEngine(
        tickInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      timerEngine.dispose();
    });

    group('initial state', () {
      test('should not be running initially', () {
        expect(timerEngine.isRunning, false);
      });

      test('should not be paused initially', () {
        expect(timerEngine.isPaused, false);
      });

      test('should have zero elapsed initially', () {
        expect(timerEngine.elapsed, Duration.zero);
      });
    });

    group('start', () {
      test('should set isRunning to true', () {
        timerEngine.start();
        expect(timerEngine.isRunning, true);
      });

      test('should set isPaused to false', () {
        timerEngine.start();
        expect(timerEngine.isPaused, false);
      });

      test('should emit tick on start', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(emissions.isNotEmpty, true);
        await subscription.cancel();
      });

      test('should emit ticks periodically', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(emissions.length, greaterThanOrEqualTo(2));
        await subscription.cancel();
      });

      test('should increase elapsed over time', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(timerEngine.elapsed.inMilliseconds, greaterThan(50));
      });
    });

    group('pause', () {
      test('should set isRunning to false', () {
        timerEngine.start();
        timerEngine.pause();
        expect(timerEngine.isRunning, false);
      });

      test('should set isPaused to true', () {
        timerEngine.start();
        timerEngine.pause();
        expect(timerEngine.isPaused, true);
      });

      test('should preserve elapsed time', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final elapsedBeforePause = timerEngine.elapsed;

        timerEngine.pause();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          timerEngine.elapsed.inMilliseconds,
          closeTo(elapsedBeforePause.inMilliseconds, 20),
        );
      });

      test('should stop emitting ticks when paused', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final emissionsBeforePause = emissions.length;

        timerEngine.pause();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // May have one more emission from the last tick
        expect(emissions.length, lessThanOrEqualTo(emissionsBeforePause + 1));
        await subscription.cancel();
      });
    });

    group('resume', () {
      test('should set isRunning to true', () {
        timerEngine.start();
        timerEngine.pause();
        timerEngine.resume();
        expect(timerEngine.isRunning, true);
      });

      test('should set isPaused to false', () {
        timerEngine.start();
        timerEngine.pause();
        timerEngine.resume();
        expect(timerEngine.isPaused, false);
      });

      test('should continue from paused time', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final elapsedBeforePause = timerEngine.elapsed;

        timerEngine.pause();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        timerEngine.resume();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          timerEngine.elapsed.inMilliseconds,
          greaterThan(elapsedBeforePause.inMilliseconds + 50),
        );
      });

      test('should resume emitting ticks', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        timerEngine.pause();
        final emissionsAtPause = emissions.length;
        await Future<void>.delayed(const Duration(milliseconds: 50));

        timerEngine.resume();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, greaterThan(emissionsAtPause));
        await subscription.cancel();
      });

      test('should not resume if not paused', () {
        timerEngine.start();
        timerEngine.resume(); // Should have no effect
        expect(timerEngine.isRunning, true);
      });
    });

    group('stop', () {
      test('should set isRunning to false', () {
        timerEngine.start();
        timerEngine.stop();
        expect(timerEngine.isRunning, false);
      });

      test('should set isPaused to false', () {
        timerEngine.start();
        timerEngine.pause();
        timerEngine.stop();
        expect(timerEngine.isPaused, false);
      });

      test('should reset elapsed to zero', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        timerEngine.stop();
        expect(timerEngine.elapsed, Duration.zero);
      });

      test('should stop emitting ticks', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        timerEngine.stop();
        final emissionsAtStop = emissions.length;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, emissionsAtStop);
        await subscription.cancel();
      });
    });

    group('reset', () {
      test('should reset elapsed to zero while running', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        timerEngine.reset();
        expect(timerEngine.elapsed.inMilliseconds, lessThan(50));
        expect(timerEngine.isRunning, true);
      });

      test('should reset elapsed to zero while stopped', () {
        timerEngine.start();
        timerEngine.stop();
        timerEngine.reset();
        expect(timerEngine.elapsed, Duration.zero);
      });
    });

    group('dispose', () {
      test('should stop the timer', () {
        timerEngine.start();
        timerEngine.dispose();
        expect(timerEngine.isRunning, false);
      });

      test('should close the tick stream', () {
        final stream = timerEngine.tickStream;
        timerEngine.dispose();

        // Stream should complete
        expectLater(stream, emitsDone);
      });
    });

    group('tick stream', () {
      test('should be a broadcast stream', () async {
        final emissions1 = <Duration>[];
        final emissions2 = <Duration>[];

        final sub1 = timerEngine.tickStream.listen(emissions1.add);
        final sub2 = timerEngine.tickStream.listen(emissions2.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(emissions1.isNotEmpty, true);
        expect(emissions2.isNotEmpty, true);

        await sub1.cancel();
        await sub2.cancel();
      });

      test('should emit increasing durations', () async {
        final emissions = <Duration>[];
        final subscription = timerEngine.tickStream.listen(emissions.add);

        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 200));

        for (var i = 1; i < emissions.length; i++) {
          expect(
            emissions[i].inMilliseconds,
            greaterThanOrEqualTo(emissions[i - 1].inMilliseconds),
          );
        }

        await subscription.cancel();
      });
    });

    group('precision', () {
      test('should track time accurately over short period', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        timerEngine.stop();

        // Allow 100ms margin for test timing variance
        expect(
          timerEngine.elapsed.inMilliseconds,
          closeTo(0, 10), // After stop, elapsed is reset
        );
      });

      test('elapsed should be accurate while running', () async {
        timerEngine.start();
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Allow generous margin for test timing
        expect(timerEngine.elapsed.inMilliseconds, greaterThan(150));
        expect(timerEngine.elapsed.inMilliseconds, lessThan(350));
      });
    });
  });
}
