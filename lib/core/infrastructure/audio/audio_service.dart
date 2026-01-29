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
    _initPlayers();
  }

  final Map<String, AudioPlayer> _players = {};
  bool _initialized = false;

  double _volume = 1;
  bool _isMuted = false;

  Future<void> _initPlayers() async {
    if (_initialized) return;
    _initialized = true;

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

    // Listen for playback completion to deactivate session and restore audio
    for (final player in _players.values) {
      player.onPlayerComplete.listen((_) async {
        await _deactivateSession();
      });
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
  static const _countdown3Sound = 'audio/countdown_3.m4a';
  static const _countdown2Sound = 'audio/countdown_2.m4a';
  static const _countdown1Sound = 'audio/countdown_1.m4a';
  static const _goSound = 'audio/go.m4a';
  static const _restSound = 'audio/rest.m4a';
  static const _completeSound = 'audio/complete.m4a';
  static const _halfwaySound = 'audio/halfway.m4a';
  static const _intervalSound = 'audio/interval.m4a';

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
