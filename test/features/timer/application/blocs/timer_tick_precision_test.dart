// The engine reports elapsed time to the microsecond and the domain
// accumulates whole milliseconds per tick. Differencing microseconds and
// truncating each delta lost up to a millisecond a tick, which made a
// 10:00 AMRAP run about three seconds long (found on the watch, 5 Oct 2026).
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../../helpers/notifier_harness.dart';

void main() {
  late NotifierHarness h;

  setUp(() => h = NotifierHarness());
  tearDown(() => h.dispose());

  test('6000 ticks of 100.7ms read 604 seconds, not 600', () async {
    await h.notifier.start(amrapWorkout(seconds: 1200));
    for (var i = 1; i <= 6000; i++) {
      h.engine.emit(Duration(microseconds: i * 100700));
    }
    expect(h.state, isA<TimerRunning>());
    expect(h.state.sessionOrNull!.elapsed.seconds, 604);
  });

  test('ticks that jitter either side of 100ms still sum to the clock', () async {
    await h.notifier.start(amrapWorkout(seconds: 1200));
    var micros = 0;
    for (var i = 1; i <= 3000; i++) {
      micros += i.isEven ? 99400 : 100600; // averages 100ms exactly
      h.engine.emit(Duration(microseconds: micros));
    }
    expect(h.state.sessionOrNull!.elapsed.seconds, 300);
  });
}
