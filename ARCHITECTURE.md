# WOD Timer - Architecture & Development Guidelines

> Flutter/Dart best practices with Domain-Driven Design (DDD)

## Table of Contents

1. [Project Structure](#project-structure)
2. [Layer Responsibilities](#layer-responsibilities)
3. [Domain Layer Patterns](#domain-layer-patterns)
4. [Error Handling](#error-handling)
5. [State Management](#state-management)
6. [Dependency Injection](#dependency-injection)
7. [Dart 3+ Idioms](#dart-3-idioms)
8. [Testing Strategy](#testing-strategy)
9. [Code Style & Linting](#code-style--linting)
10. [Performance Guidelines](#performance-guidelines)
11. [Package Dependencies](#package-dependencies)

---

## Project Structure

We use a **feature-first DDD structure** combining domain isolation with feature modularity:

```
lib/
├── core/                           # Shared kernel
│   ├── domain/                     # Core domain concepts
│   │   ├── value_objects/          # Shared value objects (UniqueId, etc.)
│   │   └── failures/               # Base failure types
│   ├── infrastructure/             # Core infrastructure
│   │   └── services/               # Platform services (audio, storage)
│   └── presentation/               # Shared UI
│       ├── widgets/                # Reusable widgets
│       ├── theme/                  # App theme
│       └── router/                 # Navigation/routing
│
├── features/                       # Feature modules
│   ├── timer/                      # Timer feature
│   │   ├── domain/
│   │   │   ├── entities/           # Timer, Workout, Round
│   │   │   ├── value_objects/      # Duration, TimerType
│   │   │   ├── repositories/       # ITimerRepository (interface)
│   │   │   └── failures/           # TimerFailure
│   │   ├── application/
│   │   │   ├── usecases/           # StartTimer, PauseTimer, etc.
│   │   │   └── blocs/              # TimerBloc
│   │   ├── infrastructure/
│   │   │   ├── repositories/       # TimerRepository (implementation)
│   │   │   ├── datasources/        # Local storage, etc.
│   │   │   └── dtos/               # Data transfer objects
│   │   └── presentation/
│   │       ├── pages/              # TimerPage, TimerSetupPage
│   │       └── widgets/            # TimerDisplay, RoundCounter
│   │
│   ├── presets/                    # Saved workout presets
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   └── voice_packs/                # Custom voice cues (future)
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       └── presentation/
│
├── injection.dart                  # DI configuration
└── main.dart                       # App entry point
```

### Key Principles

1. **Feature isolation** - Each feature is self-contained with its own DDD layers
2. **Domain independence** - Domain layer has NO external dependencies (pure Dart)
3. **Dependency flow** - Dependencies point inward (presentation → application → domain ← infrastructure)
4. **Shared kernel** - Common domain concepts live in `core/domain/`

---

## Layer Responsibilities

### Domain Layer (Pure Dart)

The heart of the application. Contains business logic and rules.

| Component | Purpose |
|-----------|---------|
| **Entities** | Objects with identity that can change over time |
| **Value Objects** | Immutable objects identified by their attributes |
| **Repositories** | Interfaces (contracts) for data access |
| **Domain Services** | Business logic that doesn't belong to a single entity |
| **Failures** | Domain-specific error types |

**Rules:**
- NO Flutter imports
- NO external package dependencies (except fpdart for Either)
- NO implementation details
- Pure business logic only

### Application Layer

Orchestrates domain objects to perform use cases.

| Component | Purpose |
|-----------|---------|
| **Use Cases** | Single-purpose operations (one public method) |
| **BLoCs/Cubits** | State management, UI event handling |
| **DTOs** | Data transfer between layers (if needed) |

**Rules:**
- Depends only on domain layer
- No direct infrastructure access
- Coordinates between presentation and domain

### Infrastructure Layer

Implements domain interfaces with concrete technologies.

| Component | Purpose |
|-----------|---------|
| **Repositories** | Implementations of domain repository interfaces |
| **Data Sources** | API clients, local storage, platform services |
| **DTOs** | JSON/database mapping objects |

**Rules:**
- Implements domain interfaces
- Handles all external dependencies
- Converts external data to domain objects

### Presentation Layer

User interface and user interaction handling.

| Component | Purpose |
|-----------|---------|
| **Pages** | Full-screen widgets (Scaffold) |
| **Widgets** | Reusable UI components |
| **BLoC Providers** | State management wiring |

**Rules:**
- Only talks to application layer (BLoCs/Use Cases)
- No direct domain or infrastructure access
- Stateless widgets preferred where possible

---

## Domain Layer Patterns

### Value Objects

Use `freezed` for immutable, self-validating value objects:

```dart
// domain/value_objects/timer_duration.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'timer_duration.freezed.dart';

@freezed
class TimerDuration with _$TimerDuration {
  const TimerDuration._();

  const factory TimerDuration._internal(int seconds) = _TimerDuration;

  /// Factory with validation - returns Either for error handling
  static Either<ValueFailure, TimerDuration> create(int seconds) {
    if (seconds < 0) {
      return left(const ValueFailure.negativeValue());
    }
    if (seconds > 7200) { // Max 2 hours
      return left(const ValueFailure.exceedsMaximum(7200));
    }
    return right(TimerDuration._internal(seconds));
  }

  /// Unsafe factory for known-valid values (e.g., from database)
  factory TimerDuration.fromSeconds(int seconds) =>
      TimerDuration._internal(seconds);

  // Getters
  int get minutes => seconds ~/ 60;
  int get remainingSeconds => seconds % 60;
  String get formatted => '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';

  // Operations
  TimerDuration operator +(TimerDuration other) =>
      TimerDuration._internal(seconds + other.seconds);
}
```

### Entities

Entities have identity and mutable state over time:

```dart
// domain/entities/workout.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';

@freezed
class Workout with _$Workout {
  const Workout._();

  const factory Workout({
    required UniqueId id,
    required WorkoutName name,
    required TimerType timerType,
    required TimerDuration workDuration,
    TimerDuration? restDuration,
    required RoundCount rounds,
    required TimerDuration prepCountdown,
    required DateTime createdAt,
  }) = _Workout;

  /// Business logic: Calculate total workout time
  TimerDuration get totalDuration {
    final workTime = workDuration.seconds * rounds.value;
    final restTime = (restDuration?.seconds ?? 0) * (rounds.value - 1);
    return TimerDuration.fromSeconds(workTime + restTime + prepCountdown.seconds);
  }

  /// Business logic: Check if workout has rest periods
  bool get hasRestPeriods => restDuration != null && restDuration!.seconds > 0;
}
```

### Sealed Classes for Timer Types

Use Dart 3 sealed classes for exhaustive type checking:

```dart
// domain/value_objects/timer_type.dart
sealed class TimerType {
  const TimerType();
}

class AmrapTimer extends TimerType {
  final TimerDuration duration;
  const AmrapTimer(this.duration);
}

class ForTimeTimer extends TimerType {
  final TimerDuration timeCap;
  final bool countUp;
  const ForTimeTimer(this.timeCap, {this.countUp = false});
}

class EmomTimer extends TimerType {
  final TimerDuration intervalDuration;
  final RoundCount rounds;
  const EmomTimer(this.intervalDuration, this.rounds);
}

class TabataTimer extends TimerType {
  final TimerDuration workDuration;
  final TimerDuration restDuration;
  final RoundCount rounds;
  const TabataTimer(this.workDuration, this.restDuration, this.rounds);
}

class CustomTimer extends TimerType {
  final List<TimerInterval> intervals;
  const CustomTimer(this.intervals);
}
```

### Repository Interface

Define contracts in domain layer:

```dart
// domain/repositories/i_workout_repository.dart
import 'package:fpdart/fpdart.dart';

abstract class IWorkoutRepository {
  /// Get all saved workout presets
  Future<Either<WorkoutFailure, List<Workout>>> getPresets();

  /// Save a workout preset
  Future<Either<WorkoutFailure, Unit>> savePreset(Workout workout);

  /// Delete a workout preset
  Future<Either<WorkoutFailure, Unit>> deletePreset(UniqueId id);

  /// Watch presets for real-time updates
  Stream<Either<WorkoutFailure, List<Workout>>> watchPresets();
}
```

---

## Error Handling

### The Either Pattern (Preferred)

Use `fpdart`'s `Either` for type-safe error handling:

```dart
// domain/failures/timer_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_failure.freezed.dart';

@freezed
sealed class TimerFailure with _$TimerFailure {
  const factory TimerFailure.invalidStateTransition() = _InvalidStateTransition;
  const factory TimerFailure.storageError(String message) = _StorageError;
  const factory TimerFailure.audioPlaybackFailed() = _AudioPlaybackFailed;
  const factory TimerFailure.unexpected() = _Unexpected;
}
```

### Use Case Error Handling

```dart
// application/usecases/start_timer.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class StartTimer {
  final ITimerRepository _timerRepository;
  final IAudioService _audioService;

  StartTimer(this._timerRepository, this._audioService);

  Future<Either<TimerFailure, TimerSession>> call(Workout workout) async {
    // Chain operations with flatMap
    return TaskEither<TimerFailure, TimerSession>.tryCatch(
      () async {
        final session = TimerSession.create(workout);
        await _audioService.playStartBeep();
        return session;
      },
      (error, _) => const TimerFailure.unexpected(),
    ).run();
  }
}
```

### Presentation Error Display

```dart
// presentation/widgets/timer_failure_dialog.dart
String mapFailureToMessage(TimerFailure failure) {
  return switch (failure) {
    _InvalidStateTransition() => 'Cannot perform this action right now',
    _StorageError(:final message) => 'Storage error: $message',
    _AudioPlaybackFailed() => 'Failed to play audio cue',
    _Unexpected() => 'An unexpected error occurred',
  };
}
```

---

## State Management

### Riverpod (Recommended)

Use Riverpod with code generation:

```dart
// application/providers/timer_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_provider.g.dart';

@riverpod
class TimerNotifier extends _$TimerNotifier {
  @override
  TimerSession? build() => null;

  Future<void> startWorkout(Workout workout) async {
    final startTimer = ref.read(startTimerUseCaseProvider);
    final result = await startTimer(workout);

    result.fold(
      (failure) => ref.read(errorNotifierProvider.notifier).show(failure),
      (session) => state = session,
    );
  }

  void tick(Duration elapsed) {
    if (state == null) return;
    state = state!.copyWith(
      elapsed: TimerDuration.fromSeconds(elapsed.inSeconds),
    );
  }
}

@riverpod
StartTimer startTimerUseCase(Ref ref) {
  return StartTimer(
    ref.watch(timerRepositoryProvider),
    ref.watch(audioServiceProvider),
  );
}
```

---

## Dependency Injection

### get_it + injectable Setup

```dart
// injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() async => getIt.init();
```

### Registration Annotations

```dart
// Domain services - interfaces only, no registration
abstract class ITimerRepository { ... }

// Infrastructure implementations
@LazySingleton(as: ITimerRepository)
class TimerRepository implements ITimerRepository {
  final LocalDataSource _localDataSource;

  TimerRepository(this._localDataSource);
  // ...
}

// Application services
@injectable
class StartTimer {
  final ITimerRepository _timerRepository;

  StartTimer(this._timerRepository);
  // ...
}

// Singletons for services that need single instance
@singleton
class AudioService implements IAudioService {
  // ...
}
```

---

## Dart 3+ Idioms

### Records for Multiple Return Values

```dart
// Instead of creating a class for simple grouped data
(TimerDuration elapsed, int currentRound) getTimerProgress(TimerSession session) {
  return (session.elapsed, session.currentRound);
}

// Usage with destructuring
final (elapsed, round) = getTimerProgress(session);
```

### Pattern Matching

```dart
// Exhaustive switch with sealed classes
String getTimerTypeLabel(TimerType type) => switch (type) {
  AmrapTimer() => 'AMRAP',
  ForTimeTimer(countUp: true) => 'For Time (Count Up)',
  ForTimeTimer(countUp: false) => 'For Time',
  EmomTimer() => 'EMOM',
  TabataTimer() => 'Tabata',
  CustomTimer() => 'Custom',
};
```

### Extension Types for Type Safety

```dart
// Zero-cost type wrapper for compile-time safety
extension type Seconds(int value) {
  Seconds operator +(Seconds other) => Seconds(value + other.value);
  Milliseconds toMilliseconds() => Milliseconds(value * 1000);
}

extension type Milliseconds(int value) {
  Seconds toSeconds() => Seconds(value ~/ 1000);
}
```

---

## Testing Strategy

### Test Structure

```
test/
├── core/
│   └── domain/
│       └── value_objects/
│           └── timer_duration_test.dart
├── features/
│   └── timer/
│       ├── domain/
│       │   └── entities/
│       │       └── workout_test.dart
│       ├── application/
│       │   └── usecases/
│       │       └── start_timer_test.dart
│       └── infrastructure/
│           └── repositories/
│               └── timer_repository_test.dart
├── widget_test/
│   └── timer/
│       └── timer_display_test.dart
└── integration_test/
    └── timer_flow_test.dart
```

### Unit Test Example

```dart
// test/features/timer/domain/value_objects/timer_duration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('TimerDuration', () {
    test('should create valid duration', () {
      final result = TimerDuration.create(60);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (duration) {
          expect(duration.seconds, 60);
          expect(duration.minutes, 1);
          expect(duration.remainingSeconds, 0);
        },
      );
    });

    test('should reject negative duration', () {
      final result = TimerDuration.create(-1);

      expect(result.isLeft(), true);
    });
  });
}
```

---

## Code Style & Linting

### analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/injection.config.dart"

linter:
  rules:
    public_member_api_docs: false
    avoid_dynamic_calls: true
    prefer_single_quotes: true
    require_trailing_commas: true
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes, Enums | UpperCamelCase | `TimerSession`, `TimerType` |
| Files, Packages | snake_case | `timer_session.dart` |
| Variables, Functions | lowerCamelCase | `currentRound`, `startTimer()` |
| Constants | lowerCamelCase | `maxRounds`, `defaultPrepTime` |
| Private members | Leading underscore | `_internalState` |
| Booleans | `is`/`has`/`should` prefix | `isRunning`, `hasRestPeriod` |
| Interfaces | `I` prefix | `ITimerRepository` |
| Failures | `Failure` suffix | `TimerFailure` |

---

## Performance Guidelines

### Widget Optimization

```dart
// DO: Use const constructors
const TimerDisplay(elapsed: elapsed);

// DO: Extract static subtrees
class TimerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TimerHeader(), // Static - won't rebuild
        TimerDisplay(elapsed: elapsed), // Dynamic
        const TimerControls(), // Static
      ],
    );
  }
}

// DO: Use ListView.builder for long lists
ListView.builder(
  itemCount: presets.length,
  itemBuilder: (context, index) => PresetTile(preset: presets[index]),
);
```

---

## Quick Reference Checklist

### Before Creating a New Feature

- [ ] Create feature folder with all 4 layers
- [ ] Define domain entities and value objects first
- [ ] Define repository interfaces in domain layer
- [ ] Create failures as sealed classes
- [ ] Implement use cases in application layer
- [ ] Implement repository in infrastructure layer
- [ ] Create BLoC/Provider in application layer
- [ ] Build UI last

### Before Each Commit

- [ ] Run `flutter analyze` - no warnings
- [ ] Run `flutter test` - all pass
- [ ] Run build_runner if models changed
- [ ] Domain layer has no Flutter imports
- [ ] All Either results are handled
- [ ] No `dynamic` types used
