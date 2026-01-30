import 'dart:async';

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
          avAudioSessionCategory:
              audio_session.AVAudioSessionCategory.playback,
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
          if (state == PlayerState.completed ||
              state == PlayerState.stopped) {
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

  /// Asset paths for sounds.
  static const _beepSound = 'audio/beep.m4a';
  static const _countdown3Sound = 'audio/countdown_3.mp3';
  static const _countdown2Sound = 'audio/countdown_2.mp3';
  static const _countdown1Sound = 'audio/countdown_1.mp3';
  static const _goSound = 'audio/countdown_go.mp3';
  static const _restSound = 'audio/rest.mp3';
  static const _completeSound = 'audio/complete.mp3';
  static const _halfwaySound = 'audio/halfway.mp3';
  static const _intervalSound = 'audio/interval.mp3';
  static const _getReadySound = 'audio/get_ready.mp3';
  static const _tenSecondsSound = 'audio/ten_seconds.mp3';
  static const _lastRoundSound = 'audio/last_round.mp3';
  static const _keepGoingSound = 'audio/keep_going.mp3';
  static const _goodJobSound = 'audio/good_job.mp3';
  static const _nextRoundSound = 'audio/next_round.mp3';
  static const _finalCountdownSound = 'audio/final_countdown.mp3';
  static const _letsGoSound = 'audio/lets_go.mp3';
  static const _comeOnSound = 'audio/come_on.mp3';
  static const _almostThereSound = 'audio/almost_there.mp3';
  static const _thatsItSound = 'audio/thats_it.mp3';
  static const _noRepSound = 'audio/no_rep.mp3';

  @override
  bool get isMuted => _isMuted;

  @override
  Future<Either<AudioFailure, Unit>> playBeep() async {
    return _play(_beepSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playCountdown(int number) async {
    final soundPath = switch (number) {
      3 => _countdown3Sound,
      2 => _countdown2Sound,
      1 => _countdown1Sound,
      _ => _beepSound,
    };
    return _play(soundPath);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGo() async {
    return _play(_goSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playRest() async {
    return _play(_restSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playComplete() async {
    return _play(_completeSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playHalfway() async {
    return _play(_halfwaySound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playIntervalStart() async {
    return _play(_intervalSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGetReady() async {
    return _play(_getReadySound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playTenSeconds() async {
    return _play(_tenSecondsSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playLastRound() async {
    return _play(_lastRoundSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playKeepGoing() async {
    return _play(_keepGoingSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGoodJob() async {
    return _play(_goodJobSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playNextRound() async {
    return _play(_nextRoundSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playFinalCountdown() async {
    return _play(_finalCountdownSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playLetsGo() async {
    return _play(_letsGoSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playComeOn() async {
    return _play(_comeOnSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playAlmostThere() async {
    return _play(_almostThereSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playThatsIt() async {
    return _play(_thatsItSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playNoRep() async {
    return _play(_noRepSound);
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
}
