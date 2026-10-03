/// Shared formatting for setup values, Home and the live screens.
library;

/// Clock format used across setup: "0:45", "1:00", "10:00".
String setupClock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// A phase length the way athletes say it: "20s" under a minute, "2:00"
/// from a minute up. Used for Tabata values, config lines and Home.
String setupPhase(int totalSeconds) =>
    totalSeconds < 60 ? '${totalSeconds}s' : setupClock(totalSeconds);

/// Spoken form of a duration: "1 minute 30 seconds", "45 seconds".
String setupSpokenDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final parts = <String>[
    if (minutes > 0) '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
    if (seconds > 0 || minutes == 0)
      '$seconds ${seconds == 1 ? 'second' : 'seconds'}',
  ];
  return parts.join(' ');
}
