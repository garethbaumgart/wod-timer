import 'package:audioplayers/audioplayers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';

/// Implementation of [IAudioService] using audioplayers package.
@LazySingleton(as: IAudioService)
class AudioService implements IAudioService {
  AudioService() {
    _beepPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
    _voicePlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
    _effectPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  }

  late final AudioPlayer _beepPlayer;
  late final AudioPlayer _voicePlayer;
  late final AudioPlayer _effectPlayer;

  double _volume = 1;
  bool _isMuted = false;

  /// Asset paths for sounds.
  static const _beepSound = 'audio/beep.mp3';
  static const _countdown3Sound = 'audio/countdown_3.mp3';
  static const _countdown2Sound = 'audio/countdown_2.mp3';
  static const _countdown1Sound = 'audio/countdown_1.mp3';
  static const _goSound = 'audio/go.mp3';
  static const _restSound = 'audio/rest.mp3';
  static const _completeSound = 'audio/complete.mp3';
  static const _halfwaySound = 'audio/halfway.mp3';
  static const _intervalSound = 'audio/interval.mp3';

  @override
  bool get isMuted => _isMuted;

  @override
  Future<Either<AudioFailure, Unit>> playBeep() async {
    return _play(_beepPlayer, _beepSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playCountdown(int number) async {
    final soundPath = switch (number) {
      3 => _countdown3Sound,
      2 => _countdown2Sound,
      1 => _countdown1Sound,
      _ => _beepSound,
    };
    return _play(_voicePlayer, soundPath);
  }

  @override
  Future<Either<AudioFailure, Unit>> playGo() async {
    return _play(_voicePlayer, _goSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playRest() async {
    return _play(_voicePlayer, _restSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playComplete() async {
    return _play(_effectPlayer, _completeSound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playHalfway() async {
    return _play(_voicePlayer, _halfwaySound);
  }

  @override
  Future<Either<AudioFailure, Unit>> playIntervalStart() async {
    return _play(_beepPlayer, _intervalSound);
  }

  Future<Either<AudioFailure, Unit>> _play(
    AudioPlayer player,
    String assetPath,
  ) async {
    if (_isMuted) {
      return right(unit);
    }

    try {
      await player.setVolume(_volume);
      await player.play(AssetSource(assetPath));
      return right(unit);
    } on AudioPlayerException catch (e) {
      return left(AudioFailure.playbackError(message: e.cause?.toString()));
    } on Exception catch (e) {
      return left(AudioFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<void> preloadSounds() async {
    // Preload sounds by setting the source without playing
    try {
      await _beepPlayer.setSource(AssetSource(_beepSound));
      await _voicePlayer.setSource(AssetSource(_countdown3Sound));
      await _effectPlayer.setSource(AssetSource(_completeSound));
    } on Exception catch (_) {
      // Ignore preload errors - sounds will load on first play
    }
  }

  @override
  Future<void> dispose() async {
    await _beepPlayer.dispose();
    await _voicePlayer.dispose();
    await _effectPlayer.dispose();
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
