// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioServiceHash() => r'b26444a0e7a3b78e0dc5df63fe5c9b639ee48b51';

/// Provider for the audio service.
///
/// Uses the singleton from get_it so the mute state set from settings
/// applies to the same instance that plays the workout cues (a locally
/// constructed instance here would silently diverge from it).
///
/// Copied from [audioService].
@ProviderFor(audioService)
final audioServiceProvider = Provider<IAudioService>.internal(
  audioService,
  name: r'audioServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioServiceRef = ProviderRef<IAudioService>;
String _$hapticServiceHash() => r'3be4c5322479e747a7d6522622ae6a56df70d7b5';

/// Provider for the haptic feedback service.
///
/// Uses the singleton from get_it to ensure the enabled state is shared
/// across the app when toggled from settings.
///
/// Copied from [hapticService].
@ProviderFor(hapticService)
final hapticServiceProvider = Provider<IHapticService>.internal(
  hapticService,
  name: r'hapticServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hapticServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HapticServiceRef = ProviderRef<IHapticService>;
String _$timerEngineHash() => r'5bae638a5f1364f431f55db1eda3f4887f3e20b2';

/// Provider for the timer engine.
///
/// Copied from [timerEngine].
@ProviderFor(timerEngine)
final timerEngineProvider = AutoDisposeProvider<ITimerEngine>.internal(
  timerEngine,
  name: r'timerEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimerEngineRef = AutoDisposeProviderRef<ITimerEngine>;
String _$createWorkoutHash() => r'52ca31fb366300176c7ac6c52547b14273ef7e9b';

/// Provider for the CreateWorkout use case.
///
/// Copied from [createWorkout].
@ProviderFor(createWorkout)
final createWorkoutProvider = AutoDisposeProvider<CreateWorkout>.internal(
  createWorkout,
  name: r'createWorkoutProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createWorkoutHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CreateWorkoutRef = AutoDisposeProviderRef<CreateWorkout>;
String _$startTimerHash() => r'e93a8c77cb0ce83c49915edac4de19c202e83b42';

/// Provider for the StartTimer use case.
///
/// Copied from [startTimer].
@ProviderFor(startTimer)
final startTimerProvider = AutoDisposeProvider<StartTimer>.internal(
  startTimer,
  name: r'startTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$startTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StartTimerRef = AutoDisposeProviderRef<StartTimer>;
String _$pauseTimerHash() => r'67e63b9d541ba7716d6757dd9d91f39616a5466d';

/// Provider for the PauseTimer use case.
///
/// Copied from [pauseTimer].
@ProviderFor(pauseTimer)
final pauseTimerProvider = AutoDisposeProvider<PauseTimer>.internal(
  pauseTimer,
  name: r'pauseTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pauseTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PauseTimerRef = AutoDisposeProviderRef<PauseTimer>;
String _$resumeTimerHash() => r'e9e59333fba1b8f18bbb1b2ae3a196cc0e0de11b';

/// Provider for the ResumeTimer use case.
///
/// Copied from [resumeTimer].
@ProviderFor(resumeTimer)
final resumeTimerProvider = AutoDisposeProvider<ResumeTimer>.internal(
  resumeTimer,
  name: r'resumeTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resumeTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResumeTimerRef = AutoDisposeProviderRef<ResumeTimer>;
String _$stopTimerHash() => r'85cf4e613a0ab4c1afd421a2ffa8c0de2c8f2a02';

/// Provider for the StopTimer use case.
///
/// Copied from [stopTimer].
@ProviderFor(stopTimer)
final stopTimerProvider = AutoDisposeProvider<StopTimer>.internal(
  stopTimer,
  name: r'stopTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stopTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StopTimerRef = AutoDisposeProviderRef<StopTimer>;
String _$tickTimerHash() => r'a6de3bbdc0977636a65b69bc5f298fd0b1877f7e';

/// Provider for the TickTimer use case.
///
/// Copied from [tickTimer].
@ProviderFor(tickTimer)
final tickTimerProvider = AutoDisposeProvider<TickTimer>.internal(
  tickTimer,
  name: r'tickTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tickTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TickTimerRef = AutoDisposeProviderRef<TickTimer>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
