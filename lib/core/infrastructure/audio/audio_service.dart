import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/audio/session_lease.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

/// Implementation of [IAudioService] using audioplayers package.
///
/// Configures audio session to duck (lower volume of) other audio
/// during cue playback, then restore it afterwards, on both platforms:
/// see [sessionConfiguration] and [cueContext].
@LazySingleton(as: IAudioService)
class AudioService implements IAudioService {
  AudioService() : _playAsset = null {
    unawaited(_initPlayers());
  }

  /// For tests: every asset the service decides to play goes to
  /// [playAsset] instead of the player pool, and the platform is never
  /// touched. The cue-to-asset rules (voice pack, Beeps only, Silent) are
  /// exactly the production ones.
  @visibleForTesting
  AudioService.withSink(Future<void> Function(String assetPath) playAsset)
    : _playAsset = playAsset;

  final Future<void> Function(String assetPath)? _playAsset;

  /// What a cue does to other audio (5 Oct 2026). iOS: the session ducks
  /// music and mixes, so a podcast keeps playing under the line. Android:
  /// transient focus that may duck, so the music drops for the cue and
  /// comes back. The plugin default on Android is permanent focus, which
  /// stops Spotify at the first beep and never restarts it. The session is
  /// the one owner of focus, held from the first beep to the end of the
  /// last line (see [SessionLease]).
  @visibleForTesting
  static final sessionConfiguration = audio_session.AudioSessionConfiguration(
    avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions:
        audio_session.AVAudioSessionCategoryOptions.duckOthers |
        audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
    androidAudioAttributes: const audio_session.AndroidAudioAttributes(
      contentType: audio_session.AndroidAudioContentType.speech,
      usage: audio_session.AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType:
        audio_session.AndroidAudioFocusGainType.gainTransientMayDuck,
    androidWillPauseWhenDucked: false,
  );

  /// The players' own context: the same iOS options, and on Android no
  /// focus request of their own (the session owns it), on the media stream
  /// at media volume. Applied once, before the pool is created, so every
  /// player inherits it.
  @visibleForTesting
  static final cueContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {
        AVAudioSessionOptions.duckOthers,
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      audioMode: AndroidAudioMode.normal,
      stayAwake: false,
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  /// The longest cue clip is 1.7s ("complete"): a hold that gets no
  /// completion event (Android's low-latency player) is released this long
  /// after the play.
  @visibleForTesting
  static const releaseAfter = Duration(milliseconds: 2200);

  late final SessionLease _lease = SessionLease(
    onActivate: () async {
      final session = await audio_session.AudioSession.instance;
      await session.setActive(true);
    },
    onDeactivate: () async {
      final session = await audio_session.AudioSession.instance;
      await session.setActive(false);
    },
    releaseAfter: releaseAfter,
  );

  final Map<String, AudioPlayer> _players = {};
  final Map<String, StreamSubscription<PlayerState>> _subscriptions = {};
  Completer<void>? _initCompleter;

  /// Holds on the session open right now (cues still sounding).
  @visibleForTesting
  int get activeHolds => _lease.active;

  double _volume = 1;
  bool _isMuted = false;

  Future<void> _initPlayers() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    try {
      // Configure audio session to duck other audio instead of stopping it
      final session = await audio_session.AudioSession.instance;
      await session.configure(sessionConfiguration);
      try {
        await AudioPlayer.global.setAudioContext(cueContext);
      } on Exception {
        // Desktop and web have no audio context; the session still applies.
      }

      // A cue that cannot start while its hold on the session is still
      // open is dropped, never played late: the plugin's own wait is 30
      // seconds, long enough for a "3" to land after the "Go".
      AudioPlayer.preparationTimeout = releaseAfter;

      // Two players for the voice and two for the beeps, so a high beep
      // and the voice line that starts on it play together, and a beep can
      // never cut off a line that is still being spoken.
      for (var i = 0; i < _poolSize; i++) {
        for (final channel in ['voice', 'beep']) {
          final key = '${channel}_$i';
          final player = AudioPlayer();
          await player.setPlayerMode(PlayerMode.lowLatency);
          _players[key] = player;
          _watch(key, player);
        }
      }

      _initCompleter!.complete();
    } on Exception catch (e) {
      // The launch call is not awaited and nobody may be waiting on the
      // completer, so its error must not go looking for a handler; a cue
      // that is waiting still gets it, and drops itself.
      final failed = _initCompleter!;
      _initCompleter = null; // Allow retry on failure
      failed.future.ignore();
      failed.completeError(e);
    }
  }

  /// A player's completion (or stop) releases its hold on the session; a
  /// player that never reports one is released by the lease's timeout.
  void _watch(String key, AudioPlayer player) {
    _subscriptions[key] = player.onPlayerStateChanged.listen((state) async {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        await _lease.complete(key);
      }
    });
  }

  static const _poolSize = 2;
  final Map<String, int> _nextIndex = {'voice': 0, 'beep': 0};

  /// The next player of [channel], round robin ('voice_0', 'voice_1').
  String _nextKey(String channel) {
    final index = _nextIndex[channel]!;
    _nextIndex[channel] = (index + 1) % _poolSize;
    return '${channel}_$index';
  }

  /// Current voice pack directory name.
  String _voicePack = 'major';

  /// Whether to randomize voice pack per cue.
  bool _randomizePerCue = false;

  final Random _random = Random();

  /// Asset path helper — prefixes with current voice pack directory.
  /// When [_randomizePerCue] is enabled, randomly picks a voice pack.
  String _voicePath(String filename) {
    final pack = _randomizePerCue
        ? _validVoicePacks.elementAt(_random.nextInt(_validVoicePacks.length))
        : _voicePack;
    return 'audio/$pack/$filename';
  }

  /// The gym-timer beeps, shared by every voice pack.
  static const _highBeep = 'audio/beeps/high.wav';
  static String _lowBeep(int secondsLeft) =>
      'audio/beeps/low_${secondsLeft.clamp(1, 3)}.wav';

  /// Whether spoken voice cues are muted (Beeps only).
  bool _voiceMuted = false;

  /// Play a voice cue; Beeps only drops it (the beeps carry the timing).
  Future<Either<AudioFailure, Unit>> _playVoice(String filename) async {
    if (_voiceMuted) return right(unit);
    return _play(_voicePath(filename));
  }

  @override
  bool get isMuted => _isMuted;

  @override
  Future<Either<AudioFailure, Unit>> playBeep() => playHighBeep();

  @override
  Future<Either<AudioFailure, Unit>> playLowBeep(int secondsLeft) =>
      _play(_lowBeep(secondsLeft), channel: 'beep');

  @override
  Future<Either<AudioFailure, Unit>> playHighBeep() =>
      _play(_highBeep, channel: 'beep');

  @override
  Future<Either<AudioFailure, Unit>> playGo() async {
    return _playVoice('countdown_go.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playRest() async {
    return _playVoice('rest.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playComplete() async {
    return _playVoice('complete.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playHalfway() async {
    return _playVoice('halfway.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playGetReady() async {
    return _playVoice('get_ready.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playTenSeconds() async {
    return _playVoice('ten_seconds.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playLastRound() async {
    return _playVoice('last_round.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playKeepGoing() async {
    return _playVoice('keep_going.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playGoodJob() async {
    return _playVoice('good_job.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playNextRound() async {
    return _playVoice('next_round.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playLetsGo() async {
    return _playVoice('lets_go.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playComeOn() async {
    return _playVoice('come_on.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playAlmostThere() async {
    return _playVoice('almost_there.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playThatsIt() async {
    return _playVoice('thats_it.mp3');
  }

  Future<Either<AudioFailure, Unit>> _play(
    String assetPath, {
    String channel = 'voice',
  }) async {
    if (_isMuted) {
      return right(unit);
    }

    // Fire and forget - don't await playback to avoid blocking UI
    unawaited(
      _playAsset != null
          ? _playAsset(assetPath)
          : _playAsync(assetPath, channel),
    );
    return right(unit);
  }

  Future<void> _playAsync(String assetPath, [String channel = 'voice']) async {
    final key = _nextKey(channel);
    try {
      await _initPlayers();
      await _lease.acquire(key);
      final player = _players[key]!;
      await player.setVolume(_volume);
      // Not awaited (a cue never holds up the timer), but never left
      // without a handler either: see [_start].
      unawaited(_start(key, channel, player, assetPath));
    } on Exception {
      // Audio is non-critical - ignore errors
      await _lease.complete(key);
    }
  }

  /// Plays [assetPath] on [player] and owns whatever goes wrong. A play
  /// that was simply not awaited sent its error to the app's top-level
  /// handler as a fatal one: on an Infinix X657 (Android 10 Go) five cues
  /// in a minute never loaded, each reported 30 seconds later
  /// (WHARFWOD-3, 10 Nov 2026).
  Future<void> _start(
    String key,
    String channel,
    AudioPlayer player,
    String assetPath,
  ) async {
    try {
      await player.play(AssetSource(assetPath));
    } on Object catch (error) {
      try {
        await _lease.complete(key);
        _reportCueFailure(channel, player, error);
        await _replace(key, player);
      } on Object {
        // Audio is non-critical: the next cue starts from what is there.
      }
    }
  }

  /// A player that failed to load a clip is rebuilt as a standard one.
  /// Android's low-latency player shares each loaded sound between
  /// players, and a player whose load was cut short can wait on it for
  /// good, as can every later player that asks for the same clip. The
  /// standard player shares nothing: a few milliseconds slower to start,
  /// but it plays. The cue that failed is not replayed, it is late by now.
  Future<void> _replace(String key, AudioPlayer failed) async {
    if (!identical(_players[key], failed)) return;
    final player = AudioPlayer();
    _players[key] = player;
    unawaited(_subscriptions.remove(key)?.cancel());
    _watch(key, player);
    try {
      await failed.dispose();
    } on Object {
      // It is out of the pool either way.
    }
  }

  static const _maxFailureReports = 4;
  int _failureReports = 0;

  /// Counts failed cues (anonymous, a handful per launch at most), so a
  /// phone whose cues go quiet is still seen now that the error is
  /// handled here.
  void _reportCueFailure(String channel, AudioPlayer player, Object error) {
    if (_failureReports >= _maxFailureReports) return;
    _failureReports++;
    trackEvent('cue_failed', {
      'channel': channel,
      'mode': player.mode == PlayerMode.lowLatency ? 'low_latency' : 'standard',
      'error': error is TimeoutException ? 'timeout' : 'other',
    });
  }

  @override
  Future<void> preloadSounds() async {
    await _initPlayers();
  }

  @override
  Future<void> dispose() async {
    await _lease.releaseAll();
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    _isMuted = muted;
  }

  static const _validVoicePacks = {'major', 'liam', 'holly'};

  @override
  void setVoicePack(String voicePack) {
    _voicePack = _validVoicePacks.contains(voicePack) ? voicePack : 'major';
  }

  @override
  void setRandomizePerCue({required bool enabled}) {
    _randomizePerCue = enabled;
  }

  @override
  void setVoiceMuted({required bool muted}) {
    _voiceMuted = muted;
  }

  @override
  Future<Either<AudioFailure, Unit>> playVoicePreview(String voicePack) async {
    final pack = _validVoicePacks.contains(voicePack)
        ? voicePack
        : _validVoicePacks.elementAt(_random.nextInt(_validVoicePacks.length));
    // Deliberate user action: previews bypass mute/voice-off so the picker
    // is always auditionable.
    unawaited((_playAsset ?? _playAsync)('audio/$pack/countdown_go.mp3'));
    return right(unit);
  }
}
