# Development Guide

## Prerequisites

- Flutter SDK `>=3.35.0`
- Dart SDK `>=3.9.0`
- LLVM (for ffigen)
- Android Studio / Xcode (for mobile development)
- Visual Studio (for Windows development)

## Setup

```bash
# Clone the repository
git clone <repo-url>
cd Hiddify-Optimized

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs
```

## Development Commands

### Code Generation

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter pub run build_runner clean
```

### Analysis & Formatting

```bash
# Run analyzer
flutter analyze

# Format code
dart format lib/

# Check formatting without changes
dart format --set-exit-if-changed lib/
```

### Running the App

```bash
# Development mode
flutter run

# Production mode
flutter run --release

# Specific platform
flutter run -d windows
flutter run -d android
flutter run -d ios
flutter run -d macos
flutter run -d linux
```

### Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Project Structure

```
lib/
├── core/           # Core utilities, models, and services
├── features/       # Feature modules (feature-first architecture)
├── gen/            # Generated code (flutter_gen)
├── singbox/        # Singbox integration layer
└── utils/          # Application utilities
```

### Feature Structure

Each feature follows this pattern:

```
feature_name/
├── data/           # Repository and data sources
├── model/          # Domain models
├── notifier/       # Riverpod state management
├── widget/         # UI components
└── overview/       # Page-level widgets
```

## Code Style

### Imports Order

1. Dart SDK imports
2. Flutter imports
3. Package imports (alphabetical)
4. Project imports (alphabetical)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `profile_repository.dart` |
| Classes | PascalCase | `ProfileRepository` |
| Functions | camelCase | `getActiveProfile()` |
| Constants | lowerCamelCase | `defaultTimeout` |
| Private | _prefix | `_internalState` |

### State Management

Use Riverpod with code generation:

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  FutureOr<MyState> build() async {
    // Initialize state
  }
  
  Future<void> doSomething() async {
    // Mutate state
  }
}
```

### Error Handling

Use fpdart for functional error handling:

```dart
TaskEither<Failure, Success> myOperation() {
  return exceptionHandler(() async {
    // Operation logic
    return right(result);
  }, MyFailure.new);
}
```

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/profile/profile_test.dart

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Troubleshooting

### Build Runner Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Platform-Specific Issues

**Windows:**
- Ensure Visual Studio is installed with C++ development tools
- Run `flutter doctor` to verify setup

**macOS/iOS:**
- Ensure Xcode is installed and configured
- Run `sudo xcode-select --switch /Applications/Xcode.app`

**Android:**
- Ensure Android SDK is properly configured
- Accept licenses: `flutter doctor --android-licenses`

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Run `flutter analyze` and fix any issues
4. Run `dart format lib/`
5. Run tests: `flutter test`
6. Submit a pull request

## License

See [LICENSE.md](../LICENSE.md) for details.
