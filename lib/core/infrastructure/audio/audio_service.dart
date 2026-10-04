import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';

/// Implementation of [IAudioService] using audioplayers package.
///
/// Configures audio session to duck (lower volume of) other audio
/// during cue playback, then restore it afterwards.
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

      // Two players for the voice and two for the beeps, so a high beep
      // and the voice line that starts on it play together, and a beep can
      // never cut off a line that is still being spoken.
      for (var i = 0; i < _poolSize; i++) {
        for (final channel in ['voice', 'beep']) {
          final player = AudioPlayer();
          await player.setPlayerMode(PlayerMode.lowLatency);
          _players['${channel}_$i'] = player;
        }
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

  static const _poolSize = 2;
  final Map<String, int> _nextIndex = {'voice': 0, 'beep': 0};
  int _activePlayers = 0;

  AudioPlayer _nextPlayer(String channel) {
    final index = _nextIndex[channel]!;
    _nextIndex[channel] = (index + 1) % _poolSize;
    return _players['${channel}_$index']!;
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
    try {
      await _initPlayers();
      await _activateSession();
      final player = _nextPlayer(channel);
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
    unawaited((_playAsset ?? _playAsync)('audio/$pack/countdown_go.mp3'));
    return right(unit);
  }
}
