# Hiddify Architecture Guide

## Current Structure Analysis

```
lib/
├── bootstrap.dart          # App initialization
├── main.dart               # Dev entry point
├── main_prod.dart          # Production entry point
├── core/                   # Core utilities and shared code
│   ├── analytics/          # Analytics tracking
│   ├── app_info/           # App information
│   ├── database/           # Drift database layer
│   ├── directories/        # File system directories
│   ├── haptic/             # Haptic feedback
│   ├── http_client/        # HTTP client configuration
│   ├── localization/       # i18n translations
│   ├── logger/             # Logging utilities
│   ├── model/              # Core domain models
│   ├── notification/       # In-app notifications
│   ├── preferences/        # Shared preferences
│   ├── router/             # Go Router configuration
│   ├── theme/              # App theming
│   ├── utils/              # Core utilities
│   └── widget/             # Reusable widgets
├── features/               # Feature modules
│   ├── app/                # Main app widget
│   ├── app_update/         # App update feature
│   ├── auto_start/         # Auto-start on boot
│   ├── common/             # Shared feature widgets
│   ├── config_option/      # Configuration options
│   ├── connection/         # VPN connection management
│   ├── deep_link/          # Deep link handling
│   ├── geo_asset/          # Geo assets management
│   ├── home/               # Home page
│   ├── intro/              # Introduction screens
│   ├── log/                # Logs viewer
│   ├── per_app_proxy/      # Per-app proxy settings
│   ├── profile/            # Profile management
│   ├── proxy/              # Proxy settings
│   ├── settings/           # App settings
│   ├── shortcut/           # Keyboard shortcuts
│   ├── stats/              # Connection statistics
│   ├── system_tray/        # System tray
│   └── window/             # Window management
├── gen/                    # Generated code (flutter_gen)
├── singbox/                # Singbox integration
│   ├── generated/          # Generated bindings
│   ├── model/              # Singbox models
│   └── service/            # Singbox service layer
└── utils/                  # App utilities (to be merged)
```

## Architecture Pattern

The project follows a **Feature-First Architecture** combined with elements of **Clean Architecture**:

### Layer Structure (per feature)

```
feature/
├── data/                   # Data layer
│   ├── *_repository.dart   # Repository implementation
│   ├── *_data_source.dart  # Data sources (API, local)
│   └── *_mapper.dart       # Data mappers
├── model/                  # Domain models
│   ├── *.dart              # Entity definitions
│   ├── *.freezed.dart      # Generated immutable classes
│   └── *.g.dart            # Generated JSON serialization
├── notifier/               # State management
│   ├── *_notifier.dart     # Riverpod notifiers
│   └── *.g.dart            # Generated providers
├── widget/ or overview/    # Presentation layer
│   ├── *_page.dart         # Page widgets
│   └── *_tile.dart         # Reusable tiles
└── *.dart                  # Feature barrel file (if exists)
```

## Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.35+ |
| **State Management** | Riverpod 3.x with code generation |
| **Routing** | Go Router with type-safe routes |
| **Database** | Drift (SQLite) |
| **Networking** | Dio + gRPC |
| **Serialization** | Freezed + JSON Serializable |
| **Localization** | Slang |
| **Analytics** | Sentry |

## Naming Conventions

### Files
- `snake_case.dart` for all Dart files
- `*_page.dart` for page widgets
- `*_tile.dart` for list tile widgets
- `*_notifier.dart` for state notifiers
- `*_repository.dart` for repositories
- `*_data_source.dart` for data sources
- `*.g.dart` for generated code
- `*.freezed.dart` for Freezed generated code

### Classes
- `PascalCase` for all classes
- `*Page` suffix for page widgets
- `*Notifier` suffix for notifiers
- `*Repository` suffix for repositories
- `*Failure` suffix for failure types

### Providers
- Use `@riverpod` annotation for generation
- `*Provider` suffix (auto-generated)
- `*NotifierProvider` for notifier providers

## Best Practices

### 1. State Management
```dart
// Use @riverpod annotation
@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  @override
  FutureOr<State> build() async {
    // Initial state
  }
}
```

### 2. Error Handling
```dart
// Use fpdart for functional error handling
TaskEither<Failure, Success> operation() {
  return exceptionHandler(() async {
    // Logic
  }, SpecificFailure.new);
}
```

### 3. Routing
```dart
// Use type-safe routes
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData {
  @override
  Widget build(context, state) => const HomePage();
}
```

### 4. Models
```dart
// Use Freezed for immutable models
@freezed
abstract class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    required String id,
    required String name,
  }) = _ExampleModel;
}
```

## Recommended Improvements

### High Priority
1. ✅ Fix linter warnings (completed)
2. ✅ Update gitignore for build artifacts
3. ⏳ Merge `lib/utils/` into `lib/core/utils/`
4. ⏳ Add barrel files for all features

### Medium Priority
1. Add unit tests for repositories
2. Add widget tests for pages
3. Improve documentation coverage
4. Add CI/CD pipeline improvements

### Low Priority
1. Consider migrating to very_good_analysis
2. Add code coverage reporting
3. Consider feature flagging system

## Code Generation

Run the following to regenerate all generated files:

```bash
# Clean and regenerate
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Version Requirements

- Dart SDK: `>=3.9.0 <4.0.0`
- Flutter: `>=3.35.0 <4.0.0`
