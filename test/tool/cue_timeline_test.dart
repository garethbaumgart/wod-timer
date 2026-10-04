// The real cue path end to end: the TimerNotifier driving the real
// AudioService (sink-backed), second by second, through a short workout of
// each type. Proves every file the app asks for is in the bundle, and with
// CUE_TIMELINE_OUT set writes the timelines as JSON so the audio mocks are
// rendered from what the app actually plays:
//
//   CUE_TIMELINE_OUT=/tmp/cues.json fvm flutter test test/tool/cue_timeline_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

import '../helpers/notifier_harness.dart';

void main() {
  final workouts = <String, Workout Function()>{
    'for_time': () => forTimeWorkout(cap: 60, prep: 10),
    'amrap': () => amrapWorkout(seconds: 60, prep: 10),
    'emom': () => emomWorkout(interval: 30, rounds: 3, prep: 10),
    'tabata': () => tabataWorkout(rounds: 3, prep: 10),
  };
  final timelines = <String, List<Map<String, Object>>>{};

  for (final entry in workouts.entries) {
    test('${entry.key}: every cue file exists and the end is a high beep '
        'with a line on it', () async {
      final events = <Map<String, Object>>[];
      late NotifierHarness h;
      final audio = AudioService.withSink((asset) async {
        events.add({'ms': h.engine.elapsed.inMilliseconds, 'asset': asset});
      });
      h = NotifierHarness(audioService: audio);
      addTearDown(h.dispose);

      final workout = entry.value();
      await h.notifier.start(workout);
      final total =
          workout.prepCountdown.seconds +
          workout.timerType.estimatedDuration.seconds;
      for (var ms = 100; ms <= total * 1000; ms += 100) {
        h.tick(ms ~/ 1000, ms % 1000);
      }

      for (final event in events) {
        final asset = event['asset']! as String;
        expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
      }
      final end = events.where((e) => e['ms'] == total * 1000).toList();
      expect(end.first['asset'], 'audio/beeps/high.wav');
      expect(end, hasLength(2));
      timelines[entry.key] = events;
    });
  }

  tearDownAll(() {
    final out = Platform.environment['CUE_TIMELINE_OUT'];
    if (out == null) return;
    File(
      out,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(timelines));
  });
}
