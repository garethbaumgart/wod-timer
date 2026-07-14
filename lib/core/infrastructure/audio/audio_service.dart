import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';

/// Implementation of [IAudioService] using audioplayers package.
///
/// Configures audio session to duck (lower volume of) other audio
/// during cue playback, then restore it afterwards.
@LazySingleton(as: IAudioService)
class AudioService implements IAudioService {
  AudioService() {
    unawaited(_initPlayers());
  }

  final Map<String, AudioPlayer> _players = {};
  final List<StreamSubscription<PlayerState>> _subscriptions = [];
  Completer<void>? _initCompleter;

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
      await session.configure(
        audio_session.AudioSessionConfiguration(
          avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              audio_session.AVAudioSessionCategoryOptions.duckOthers |
              audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        ),
      );

      // Create a pool of players for concurrent playback
      for (var i = 0; i < 3; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _players['pool_$i'] = player;
      }

      // Listen for playback completion or errors to deactivate session.
      // Use a single listener to avoid double-decrementing _activePlayers.
      for (final player in _players.values) {
        final sub = player.onPlayerStateChanged.listen((state) async {
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            await _deactivateSession();
          }
        });
        _subscriptions.add(sub);
      }

      _initCompleter!.complete();
    } on Exception catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Allow retry on failure
    }
  }

  int _currentPlayerIndex = 0;
  int _activePlayers = 0;

  AudioPlayer get _nextPlayer {
    final player = _players['pool_$_currentPlayerIndex']!;
    _currentPlayerIndex = (_currentPlayerIndex + 1) % 3;
    return player;
  }

  Future<void> _activateSession() async {
    _activePlayers++;
    final session = await audio_session.AudioSession.instance;
    await session.setActive(true);
  }

  Future<void> _deactivateSession() async {
    _activePlayers--;
    if (_activePlayers <= 0) {
      _activePlayers = 0;
      final session = await audio_session.AudioSession.instance;
      await session.setActive(false);
    }
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

  /// Beep is shared across all voice packs.
  static const _beepSound = 'audio/major/beep.m4a';

  /// Whether spoken voice cues are muted (beeps-only mode).
  bool _voiceMuted = false;

  /// Play a voice cue, honouring beeps-only mode.
  ///
  /// With the voice muted, timing-critical cues ([beepFallback] true) fall
  /// back to a beep so countdowns and transitions stay audible; the
  /// encouragement cues go silent.
  Future<Either<AudioFailure, Unit>> _playVoice(
    String filename, {
    bool beepFallback = false,
  }) async {
    if (_voiceMuted) {
      return beepFallback ? _play(_beepSound) : right(unit);
    }
    return _play(_voicePath(filename));
  }

  @override
  bool get isMuted => _isMuted;

  @override
  Future<Either<AudioFailure, Unit>> playBeep() async {
    return _play(_beepSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playCountdown(int number) async {
    if (number > 3 || number < 1) return _play(_beepSound);
    return _playVoice('countdown_$number.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGo() async {
    return _playVoice('countdown_go.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playRest() async {
    return _playVoice('rest.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playComplete() async {
    return _playVoice('complete.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playHalfway() async {
    return _playVoice('halfway.mp3');
  }

  @override
  Future<Either<AudioFailure, Unit>> playIntervalStart() async {
    return _playVoice('interval.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGetReady() async {
    return _playVoice('get_ready.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playTenSeconds() async {
    return _playVoice('ten_seconds.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playLastRound() async {
    return _playVoice('last_round.mp3', beepFallback: true);
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
    return _playVoice('next_round.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playFinalCountdown() async {
    return _playVoice('final_countdown.mp3', beepFallback: true);
  }

  @override
  Future<Either<AudioFailure, Unit>> playLetsGo() async {
    return _playVoice('lets_go.mp3', beepFallback: true);
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

  @override
  Future<Either<AudioFailure, Unit>> playNoRep() async {
    return _playVoice('no_rep.mp3');
  }

  Future<Either<AudioFailure, Unit>> _play(String assetPath) async {
    if (_isMuted) {
      return right(unit);
    }

    // Fire and forget - don't await playback to avoid blocking UI
    unawaited(_playAsync(assetPath));
    return right(unit);
  }

  Future<void> _playAsync(String assetPath) async {
    try {
      await _initPlayers();
      await _activateSession();
      final player = _nextPlayer;
      await player.setVolume(_volume);
      // Not awaiting - fire and forget for responsiveness
      unawaited(player.play(AssetSource(assetPath)));
    } on Exception {
      // Audio is non-critical - ignore errors
      await _deactivateSession();
    }
  }

  @override
  Future<void> preloadSounds() async {
    await _initPlayers();
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
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
    unawaited(_playAsync('audio/$pack/countdown_go.mp3'));
    return right(unit);
  }
}
