// The beep files themselves: what the gym hears. Three properties that no
// other test would notice changing.
//
// 1. Phone, Apple Watch and Wear OS play byte-identical beeps.
// 2. The halfway pips have a pitch of their own. Until 27 Nov 2026 they sat on
//    the change beep's exact pitch, so only their rhythm said "halfway" and
//    not "round over".
// 3. The halfway pips are as loud as the change beep. The 2.5.0 pips were the
//    quietest cue in the app (2.5 dB under, a tenth of the energy).
//
// The file is written by tool/audio/mid_beep.py.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _phone = 'assets/audio/beeps';
const _copies = [
  'ios/WODTimerWatch/Resources/audio/beeps',
  'android/wear/src/main/assets/audio/beeps',
];
const _beeps = ['high.wav', 'low_1.wav', 'low_2.wav', 'low_3.wav', 'mid.wav'];

class _Wav {
  _Wav(this.sampleRate, this.channels, this.samples);
  final int sampleRate;
  final int channels;

  /// Mono samples, -1 to 1.
  final List<double> samples;
}

/// Reads a 16-bit PCM WAV: the format every beep ships in.
_Wav _read(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: path);
  var sampleRate = 0;
  var channels = 0;
  var bits = 0;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      expect(data.getUint16(body, Endian.little), 1, reason: '$path is PCM');
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
      bits = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      expect(bits, 16, reason: '$path is 16-bit');
      final frames = size ~/ (2 * channels);
      final samples = List<double>.generate(frames, (i) {
        var sum = 0.0;
        for (var c = 0; c < channels; c++) {
          sum += data.getInt16(body + (i * channels + c) * 2, Endian.little);
        }
        return sum / channels / 32768;
      });
      return _Wav(sampleRate, channels, samples);
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  fail('$path has no data chunk');
}

/// Stretches of sound, as [start, end) sample indexes: 5 ms frames whose
/// peak is over a tenth of the file's peak.
List<(int, int)> _bursts(_Wav wav) {
  final frame = wav.sampleRate * 5 ~/ 1000;
  final top = wav.samples.map((s) => s.abs()).reduce(math.max);
  final bursts = <(int, int)>[];
  int? start;
  for (var i = 0; i + frame <= wav.samples.length; i += frame) {
    var peak = 0.0;
    for (var j = i; j < i + frame; j++) {
      peak = math.max(peak, wav.samples[j].abs());
    }
    final on = peak > top * 0.1;
    if (on && start == null) start = i;
    if (!on && start != null) {
      bursts.add((start, i));
      start = null;
    }
  }
  if (start != null) bursts.add((start, wav.samples.length));
  return bursts;
}

/// The pitch of a steady tone, from its upward zero crossings (the
/// harmonics in these beeps are far too weak to add crossings of their own).
double _pitch(_Wav wav, (int, int) burst) {
  final (from, to) = burst;
  // The steady middle: skip the attack and the release.
  final a = from + (to - from) ~/ 4;
  final b = to - (to - from) ~/ 4;
  final crossings = <double>[];
  for (var i = a + 1; i < b; i++) {
    final before = wav.samples[i - 1];
    final after = wav.samples[i];
    if (before < 0 && after >= 0) {
      crossings.add(i - 1 + before / (before - after));
    }
  }
  expect(crossings.length, greaterThan(8), reason: 'a tone, not a click');
  final periods = crossings.length - 1;
  return wav.sampleRate * periods / (crossings.last - crossings.first);
}

/// RMS level in dB over the steady middle of a burst.
double _levelDb(_Wav wav, (int, int) burst) {
  final (from, to) = burst;
  final a = from + (to - from) ~/ 4;
  final b = to - (to - from) ~/ 4;
  var sum = 0.0;
  for (var i = a; i < b; i++) {
    sum += wav.samples[i] * wav.samples[i];
  }
  return 10 * math.log(sum / (b - a)) / math.ln10;
}

double _ms(_Wav wav, int samples) => samples * 1000 / wav.sampleRate;

void main() {
  test('phone, Apple Watch and Wear OS ship byte-identical beeps', () {
    for (final name in _beeps) {
      final phone = File('$_phone/$name').readAsBytesSync();
      for (final dir in _copies) {
        final copy = File('$dir/$name');
        expect(copy.existsSync(), isTrue, reason: '$dir/$name');
        expect(
          copy.readAsBytesSync(),
          phone,
          reason: '$dir/$name differs from $_phone/$name',
        );
      }
    }
  });

  group('the halfway pips (mid.wav)', () {
    late _Wav mid;
    late _Wav high;
    late _Wav low;
    late List<(int, int)> pips;
    setUpAll(() {
      mid = _read('$_phone/mid.wav');
      high = _read('$_phone/high.wav');
      low = _read('$_phone/low_1.wav');
      pips = _bursts(mid);
    });

    test('are in the format the other beeps use', () {
      expect(mid.sampleRate, high.sampleRate);
      expect(mid.channels, high.channels);
    });

    test('are two pips with a clear gap, over well before a second is up', () {
      expect(pips, hasLength(2));
      for (final (from, to) in pips) {
        expect(_ms(mid, to - from), inInclusiveRange(90, 160));
      }
      expect(_ms(mid, pips[1].$1 - pips[0].$2), inInclusiveRange(60, 160));
      expect(_ms(mid, mid.samples.length), lessThan(500));
    });

    test('have a pitch of their own, between the count and the change', () {
      final change = _pitch(high, _bursts(high).first);
      final count = _pitch(low, _bursts(low).first);
      for (final pip in pips) {
        final pitch = _pitch(mid, pip);
        // A fifth under the change beep (1031 x 2/3 = 687 Hz).
        expect(pitch, closeTo(change * 2 / 3, change * 0.01));
        // At least a major third clear of each neighbour, so one pip heard
        // through the noise cannot be taken for either.
        expect(change / pitch, greaterThan(1.25));
        expect(pitch / count, greaterThan(1.25));
      }
    });

    test('are as loud as the change beep, with room for a voice line', () {
      final change = _levelDb(high, _bursts(high).first);
      for (final pip in pips) {
        expect(_levelDb(mid, pip), closeTo(change, 2));
      }
      // "Halfway" starts on the pips with a voice on. The voices are limited
      // to -4 dBFS (0.63), so a beep peak under -8 dBFS (0.40) cannot clip.
      final peak = mid.samples.map((s) => s.abs()).reduce(math.max);
      expect(peak, lessThan(0.40));
    });
  });
}
