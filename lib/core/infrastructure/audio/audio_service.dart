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

  /// Current voice pack directory name.
  String _voicePack = 'major';

  /// Asset path helper — prefixes with current voice pack directory.
  String _voicePath(String filename) => 'audio/$_voicePack/$filename';

  /// Beep is shared across all voice packs.
  static const _beepSound = 'audio/major/beep.m4a';

  @override
  bool get isMuted => _isMuted;

  @override
  Future<Either<AudioFailure, Unit>> playBeep() async {
    return _play(_beepSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playCountdown(int number) async {
    final soundPath = switch (number) {
      3 => _voicePath('countdown_3.mp3'),
      2 => _voicePath('countdown_2.mp3'),
      1 => _voicePath('countdown_1.mp3'),
      _ => _beepSound,
    };
    return _play(soundPath);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGo() async {
    return _play(_voicePath('countdown_go.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playRest() async {
    return _play(_voicePath('rest.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playComplete() async {
    return _play(_voicePath('complete.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playHalfway() async {
    return _play(_voicePath('halfway.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playIntervalStart() async {
    return _play(_voicePath('interval.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playGetReady() async {
    return _play(_voicePath('get_ready.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playTenSeconds() async {
    return _play(_voicePath('ten_seconds.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playLastRound() async {
    return _play(_voicePath('last_round.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playKeepGoing() async {
    return _play(_voicePath('keep_going.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playGoodJob() async {
    return _play(_voicePath('good_job.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playNextRound() async {
    return _play(_voicePath('next_round.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playFinalCountdown() async {
    return _play(_voicePath('final_countdown.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playLetsGo() async {
    return _play(_voicePath('lets_go.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playComeOn() async {
    return _play(_voicePath('come_on.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playAlmostThere() async {
    return _play(_voicePath('almost_there.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playThatsIt() async {
    return _play(_voicePath('thats_it.mp3'));
  }

  @override
  Future<Either<AudioFailure, Unit>> playNoRep() async {
    return _play(_voicePath('no_rep.mp3'));
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

  @override
  void setVoicePack(String voicePack) {
    _voicePack = voicePack;
  }
}
