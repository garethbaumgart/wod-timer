// A cue that cannot load is the service's problem, never the app's
// (WHARFWOD-3, 10 Nov 2026). On an Infinix X657 (Android 10 Go) five cues
// in a minute never loaded; the play was not awaited, so each one surfaced
// 30 seconds later as an unhandled "TimeoutException: Future not
// completed", reported fatal, and the phone stayed quiet.
//
// These run the real AudioService and the real audioplayers Dart code over
// a fake platform whose low-latency players never report a clip as loaded,
// which is exactly what the phone's did.
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sessionChannel = MethodChannel('com.ryanheise.audio_session');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late _FakePlatform platform;
  late List<(String, Map<String, dynamic>)> events;
  late AudioplayersPlatformInterface realPlatform;
  late GlobalAudioplayersPlatformInterface realGlobal;
  late AudioCache realCache;
  late Duration realTimeout;

  setUp(() {
    realPlatform = AudioplayersPlatformInterface.instance;
    realGlobal = GlobalAudioplayersPlatformInterface.instance;
    realCache = AudioCache.instance;
    realTimeout = AudioPlayer.preparationTimeout;

    platform = _FakePlatform();
    AudioplayersPlatformInterface.instance = platform;
    GlobalAudioplayersPlatformInterface.instance = _FakeGlobalPlatform();
    AudioCache.instance = _OnDiskAlready();
    messenger.setMockMethodCallHandler(sessionChannel, (_) async => null);

    events = [];
    telemetryEnabled = true;
    debugTelemetrySend = (name, props) => events.add((name, props));
  });

  tearDown(() {
    AudioplayersPlatformInterface.instance = realPlatform;
    GlobalAudioplayersPlatformInterface.instance = realGlobal;
    AudioCache.instance = realCache;
    AudioPlayer.preparationTimeout = realTimeout;
    messenger.setMockMethodCallHandler(sessionChannel, null);
    telemetryEnabled = false;
    debugTelemetrySend = null;
    resetTelemetryForTest();
  });

  /// Runs [body] on a fake clock and returns every error nobody handled:
  /// what the app's top-level handler, and so Sentry, would have been
  /// given. Nothing is awaited inside; the clock is moved by hand.
  List<Object> unhandledIn(void Function(FakeAsync clock) body) {
    final unhandled = <Object>[];
    fakeAsync((clock) {
      runZonedGuarded(() => body(clock), (error, _) => unhandled.add(error));
      clock.flushMicrotasks();
    });
    return unhandled;
  }

  test('a healthy cue plays on its low-latency player, untouched', () {
    final unhandled = unhandledIn((clock) {
      final audio = AudioService();
      unawaited(audio.playHighBeep());
      clock.elapse(const Duration(milliseconds: 100));

      expect(platform.started, hasLength(1));
      expect(platform.modeOf(platform.started.single), PlayerMode.lowLatency);
      expect(platform.released, isEmpty);
      expect(events, isEmpty);

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('a cue that never loads is not an unhandled error', () {
    final unhandled = unhandledIn((clock) {
      platform.lowLatencyLoads = false;
      final audio = AudioService();
      unawaited(audio.playHighBeep());

      // Past the plugin's own 30-second wait, which is where the phone's
      // five errors came from.
      clock.elapse(const Duration(seconds: 31));

      expect(
        platform.started,
        isEmpty,
        reason: 'nothing loaded, nothing plays',
      );
      expect(audio.activeHolds, 0, reason: 'the music gets its volume back');

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('it is dropped when its hold ends, never played late', () {
    final unhandled = unhandledIn((clock) {
      platform.lowLatencyLoads = false;
      final audio = AudioService();
      unawaited(audio.playLowBeep(3));
      clock.elapse(const Duration(milliseconds: 100));
      final stuck = platform.sourced.single;

      clock.elapse(AudioService.releaseAfter);
      expect(platform.released, [stuck], reason: 'given up on after 2.2s');

      // The clip finally loads, ten seconds after its moment.
      platform.reportLoaded(stuck);
      clock.elapse(const Duration(seconds: 10));
      expect(platform.started, isEmpty);

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('the stuck player is rebuilt as a standard one, and the next '
      'cue on it plays', () {
    final unhandled = unhandledIn((clock) {
      platform.lowLatencyLoads = false;
      final audio = AudioService();

      // beep_0 fails; beep_1 is the next in the round robin and fails too.
      unawaited(audio.playLowBeep(3));
      clock.elapse(const Duration(seconds: 3));
      unawaited(audio.playLowBeep(2));
      clock.elapse(const Duration(seconds: 3));
      expect(platform.started, isEmpty);
      expect(platform.released, hasLength(2));

      // Round the robin again: both beep players are standard ones now.
      unawaited(audio.playLowBeep(1));
      unawaited(audio.playHighBeep());
      clock.elapse(const Duration(milliseconds: 100));

      expect(platform.started, hasLength(2));
      for (final id in platform.started) {
        expect(platform.modeOf(id), PlayerMode.mediaPlayer);
        expect(platform.released, isNot(contains(id)));
      }

      // A standard player says when it is done, and the hold goes with it.
      platform.started.forEach(platform.reportComplete);
      clock.elapse(const Duration(milliseconds: 100));
      expect(audio.activeHolds, 0);

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('the voice players are left alone when only a beep failed', () {
    final unhandled = unhandledIn((clock) {
      platform.lowLatencyLoads = false;
      final audio = AudioService();
      unawaited(audio.playHighBeep());
      clock.elapse(const Duration(seconds: 3));

      platform.lowLatencyLoads = true;
      unawaited(audio.playGo());
      clock.elapse(const Duration(milliseconds: 100));

      expect(platform.modeOf(platform.started.single), PlayerMode.lowLatency);
      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('each failure is counted, a handful per launch at most', () {
    final unhandled = unhandledIn((clock) {
      platform
        ..lowLatencyLoads = false
        ..standardLoads = false;
      final audio = AudioService();

      for (var i = 0; i < 6; i++) {
        unawaited(audio.playHighBeep());
        clock.elapse(const Duration(seconds: 3));
      }

      expect(events.map((e) => e.$1).toSet(), {'cue_failed'});
      expect(events, hasLength(4));
      expect(events.first.$2, containsPair('channel', 'beep'));
      expect(events.first.$2, containsPair('mode', 'low_latency'));
      expect(events.first.$2, containsPair('error', 'timeout'));
      expect(events.last.$2, containsPair('mode', 'standard'));

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('a platform that refuses the clip outright is handled too', () {
    final unhandled = unhandledIn((clock) {
      platform.refuses = true;
      final audio = AudioService();
      unawaited(audio.playHighBeep());
      clock.elapse(const Duration(seconds: 3));

      expect(events.single.$2, containsPair('error', 'other'));
      expect(audio.activeHolds, 0);

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });

  test('players that cannot be created at launch are not an unhandled error, '
      'and the next cue tries again', () {
    final unhandled = unhandledIn((clock) {
      platform.refusesCreate = true;
      final audio = AudioService();
      clock.elapse(const Duration(milliseconds: 100));
      expect(platform.created, isEmpty);

      platform.refusesCreate = false;
      unawaited(audio.playHighBeep());
      clock.elapse(const Duration(milliseconds: 100));
      expect(platform.started, hasLength(1));

      unawaited(audio.dispose());
    });
    expect(unhandled, isEmpty);
  });
}

/// Every clip is already copied out of the bundle (no disk in a test).
class _OnDiskAlready extends AudioCache {
  @override
  Future<Uri> load(String fileName) async => Uri.file('/cues/$fileName');
}

class _FakeGlobalPlatform extends GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}

  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}

  @override
  Future<void> emitGlobalLog(String message) async {}

  @override
  Future<void> emitGlobalError(String code, String message) async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

/// The native side, as far as a cue is concerned: a clip is "loaded" when
/// the player says so, and a player that never says so is the bug.
class _FakePlatform extends AudioplayersPlatformInterface {
  /// Whether a low-latency player ever reports its clip as loaded.
  bool lowLatencyLoads = true;

  /// The same, for a standard player.
  bool standardLoads = true;

  /// Whether setting a source fails on the spot.
  bool refuses = false;

  /// Whether the native player cannot be created at all.
  bool refusesCreate = false;

  final created = <String>[];
  final sourced = <String>[];
  final started = <String>[];

  /// Players given up on: a dispose starts by releasing the native one.
  final released = <String>[];

  final _modes = <String, PlayerMode>{};
  final _events = <String, StreamController<AudioEvent>>{};

  PlayerMode modeOf(String playerId) =>
      _modes[playerId] ?? PlayerMode.mediaPlayer;

  void reportLoaded(String playerId) {
    final events = _events[playerId];
    if (events == null || events.isClosed) return;
    events.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  void reportComplete(String playerId) => _events[playerId]?.add(
    const AudioEvent(eventType: AudioEventType.complete),
  );

  @override
  Future<void> create(String playerId) async {
    if (refusesCreate) throw PlatformException(code: 'AndroidAudioError');
    created.add(playerId);
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      _events[playerId]!.stream;

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {
    _modes[playerId] = playerMode;
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    if (refuses) throw PlatformException(code: 'AndroidAudioError');
    sourced.add(playerId);
    final loads = modeOf(playerId) == PlayerMode.lowLatency
        ? lowLatencyLoads
        : standardLoads;
    if (loads) reportLoaded(playerId);
  }

  @override
  Future<void> resume(String playerId) async => started.add(playerId);

  @override
  Future<void> release(String playerId) async => released.add(playerId);

  @override
  Future<void> dispose(String playerId) async {
    await _events[playerId]?.close();
  }

  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) async {}

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> stop(String playerId) async {}

  @override
  Future<void> seek(String playerId, Duration position) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  ) async {}

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<int?> getCurrentPosition(String playerId) async => null;

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}
