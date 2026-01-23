# WOD Timer

A workout timer app for functional fitness, built with Flutter following Domain-Driven Design (DDD) principles.

## Features (Planned)

- **AMRAP Timer** - As Many Rounds As Possible
- **For Time Timer** - Countdown/count-up timer
- **EMOM Timer** - Every Minute On the Minute
- **Tabata Timer** - 20/10 high-intensity intervals
- **Custom Voice Cues** - Use friend's voices as workout cues (future)
- **Preset Management** - Save and reuse workout configurations

## Architecture

This project follows Domain-Driven Design (DDD) with a feature-first structure. See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed guidelines.

```
lib/
├── core/                    # Shared kernel
│   ├── domain/              # Core domain concepts
│   ├── infrastructure/      # Core infrastructure
│   └── presentation/        # Shared UI
├── features/                # Feature modules
│   ├── timer/               # Timer feature (DDD layers)
│   └── presets/             # Presets feature (DDD layers)
├── injection.dart           # DI configuration
└── main.dart                # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Dart SDK ^3.8.1

### Installation

```bash
# Clone the repository
git clone https://github.com/garethbaumgart/wod-timer.git
cd wod-timer

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Development Commands

```bash
# Run code generation (watch mode)
dart run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Run analysis
flutter analyze

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Tech Stack

- **State Management**: Riverpod
- **Functional Programming**: fpdart (Either, Option)
- **Code Generation**: freezed, json_serializable, injectable
- **Dependency Injection**: get_it + injectable
- **Routing**: go_router
- **Storage**: shared_preferences
- **Audio**: audioplayers
- **Linting**: very_good_analysis

## Contributing

1. Check [GITHUB_ISSUES.md](./GITHUB_ISSUES.md) for available tasks
2. Follow the patterns in [ARCHITECTURE.md](./ARCHITECTURE.md)
3. Run `flutter analyze` before committing
4. Write tests for new features

## License

MIT
