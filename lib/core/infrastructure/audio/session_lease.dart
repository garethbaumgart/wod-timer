import 'dart:async';

/// Counts the cues holding the audio session open (and with it, on
/// Android, the audio focus that ducks the music) and releases each hold
/// exactly once: on the player's completion event, or after [releaseAfter]
/// when none comes. Android's low-latency player (SoundPool, see
/// PlayerMode.lowLatency) never reports completion, so without the timeout
/// the first cue held the session, and the music ducked, for the rest of
/// the workout (5 Oct 2026).
class SessionLease {
  SessionLease({
    required this.onActivate,
    required this.onDeactivate,
    required this.releaseAfter,
    Timer Function(Duration duration, void Function() callback)? startTimer,
  }) : _startTimer = startTimer ?? Timer.new;

  /// Called when the first hold opens (the session goes active).
  final Future<void> Function() onActivate;

  /// Called when the last hold closes (the session goes inactive).
  final Future<void> Function() onDeactivate;

  /// How long a hold lasts when the player never reports completion.
  final Duration releaseAfter;

  final Timer Function(Duration duration, void Function() callback) _startTimer;

  final Map<String, _Hold> _holds = {};
  int _active = 0;

  /// Holds open right now.
  int get active => _active;

  /// Opens a hold for the player [key]. A hold still open on the same
  /// player is taken over, not released: the new clip replaces the old one
  /// without dropping and re-taking the session.
  Future<void> acquire(String key) async {
    final old = _holds[key];
    if (old != null) {
      old.released = true;
      old.timer?.cancel();
    } else {
      _active++;
    }
    final hold = _Hold();
    _holds[key] = hold;
    if (old == null && _active == 1) {
      try {
        await onActivate();
      } on Exception {
        _active--;
        _holds.remove(key);
        rethrow;
      }
    }
    hold.timer = _startTimer(releaseAfter, () => unawaited(_release(key, hold)));
  }

  /// The player [key] finished or stopped: release its hold, if open.
  Future<void> complete(String key) async {
    final hold = _holds[key];
    if (hold != null) await _release(key, hold);
  }

  /// Drops every hold (dispose).
  Future<void> releaseAll() async {
    for (final entry in _holds.entries.toList()) {
      await _release(entry.key, entry.value);
    }
  }

  Future<void> _release(String key, _Hold hold) async {
    if (hold.released) return;
    hold.released = true;
    hold.timer?.cancel();
    if (_holds[key] == hold) _holds.remove(key);
    _active--;
    if (_active <= 0) {
      _active = 0;
      await onDeactivate();
    }
  }
}

class _Hold {
  bool released = false;
  Timer? timer;
}
