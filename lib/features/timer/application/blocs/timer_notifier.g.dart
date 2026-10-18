// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerNotifierHash() => r'a9024681a4046c68bf56877ea1b97942d0e5544d';

/// Notifier for managing timer state during a workout session.
///
/// Integrates with the timer engine for precise timing and
/// triggers audio and haptic cues at appropriate moments.
///
/// Copied from [TimerNotifier].
@ProviderFor(TimerNotifier)
final timerNotifierProvider =
    NotifierProvider<TimerNotifier, TimerNotifierState>.internal(
      TimerNotifier.new,
      name: r'timerNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$timerNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TimerNotifier = Notifier<TimerNotifierState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
