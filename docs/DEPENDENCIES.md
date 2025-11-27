# Dependencies Guide

## Overview

This document provides a comprehensive guide to all dependencies used in the Hiddify project, their purpose, and why they were chosen over alternatives.

---

## State Management

### Riverpod 3.x ✅ (Best Choice)
```yaml
flutter_riverpod: ^3.0.3
hooks_riverpod: ^3.0.3
riverpod_annotation: ^3.0.3
riverpod_generator: ^3.0.3
```

**Why Riverpod over alternatives:**
| Feature | Riverpod | Provider | Bloc | GetX |
|---------|----------|----------|------|------|
| Compile-time safety | ✅ | ❌ | ✅ | ❌ |
| Code generation | ✅ | ❌ | ✅ | ❌ |
| Testability | ✅✅ | ✅ | ✅ | ❌ |
| Performance | ✅✅ | ✅ | ✅ | ✅ |
| Learning curve | Medium | Easy | Hard | Easy |
| Community | Growing | Large | Large | Large |

**Key benefits:**
- Type-safe dependency injection
- Built-in caching and data-binding
- Excellent DevTools support
- No BuildContext required for accessing state

---

## Navigation

### Go Router 17.x ✅ (Official Flutter Package)
```yaml
go_router: ^17.0.0
go_router_builder: ^4.1.1
```

**Why Go Router:**
- Official Flutter team package
- Type-safe routes with code generation
- Deep linking support
- Navigation 2.0 based
- StatefulShellRoute for nested navigation

**Alternatives considered:**
- `auto_route` - Good but not official
- `beamer` - More complex
- Manual Navigator 2.0 - Too verbose

---

## Database

### Drift 2.x ✅ (Best SQLite ORM)
```yaml
drift: ^2.29.0
drift_dev: ^2.29.0
sqlite3_flutter_libs: ^0.5.40
```

**Why Drift:**
- Type-safe SQL queries
- Reactive streams support
- Migration support
- Cross-platform (mobile, desktop, web)
- Great documentation

**Alternatives:**
- `sqflite` - Lower level, no type safety
- `floor` - Good but less active
- `isar` - NoSQL (different use case)
- `hive` - NoSQL (different use case)

---

## Networking

### Dio 5.x ✅ (Most Feature-Rich)
```yaml
dio: ^5.9.0
dio_smart_retry: ^7.0.1
```

**Why Dio:**
- Interceptors support
- Request cancellation
- Form data support
- File upload/download
- Global configuration

### gRPC 5.x ✅
```yaml
grpc: ^5.0.0
protobuf: ^5.1.0
```

For Singbox communication via Protocol Buffers.

---

## Data Classes & Serialization

### Freezed 3.x ✅ (Best-in-Class)
```yaml
freezed_annotation: ^3.1.0
freezed: ^3.2.3
json_annotation: ^4.9.0
json_serializable: ^6.11.1
```

**Why Freezed:**
- Immutable data classes
- Union types / sealed classes
- copyWith support
- JSON serialization
- toString, == , hashCode generation

**Example:**
```dart
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## Localization

### Slang 4.x ✅ (Type-Safe i18n)
```yaml
slang: ^4.10.0
slang_flutter: ^4.10.0
slang_build_runner: ^4.10.0
```

**Why Slang over alternatives:**
| Feature | Slang | easy_localization | flutter_i18n |
|---------|-------|-------------------|--------------|
| Type-safe | ✅ | ❌ | ❌ |
| Compile-time checks | ✅ | ❌ | ❌ |
| Pluralization | ✅ | ✅ | ✅ |
| Hot reload | ✅ | ✅ | ✅ |
| Code generation | ✅ | ❌ | ❌ |

---

## UI Components

### Icons
```yaml
fluentui_system_icons: ^1.1.273  # Microsoft Fluent icons
cupertino_icons: ^1.0.6          # iOS-style icons
```

### Animations
```yaml
flutter_animate: ^4.5.2  # Declarative animations
```

### Theming
```yaml
dynamic_color: ^1.8.1  # Material You / Dynamic Color
```

### Modals & Sheets
```yaml
wolt_modal_sheet: ^0.11.0  # Advanced modal sheets
toastification: ^3.0.3     # Toast notifications
```

---

## Platform Integration

### Cross-Platform
```yaml
path_provider: ^2.1.5
shared_preferences: ^2.5.3
url_launcher: ^6.3.2
share_plus: ^12.0.1
permission_handler: ^12.0.1
package_info_plus: ^9.0.0
```

### Desktop-Specific
```yaml
window_manager: ^0.5.1     # Window controls
tray_manager: ^0.5.2       # System tray
launch_at_startup: ^0.5.1  # Auto-start
win32: ^5.15.0             # Windows API
```

### Mobile-Specific
```yaml
mobile_scanner: ^7.1.3       # QR/Barcode scanning
flutter_displaymode: ^0.7.0  # High refresh rate (Android)
in_app_review: ^2.0.11       # App Store reviews
```

---

## Logging & Analytics

### Logging
```yaml
loggy: ^2.0.3
flutter_loggy: ^2.0.3+1
flutter_loggy_dio: ^3.1.0
```

**Why Loggy:**
- Lightweight
- Customizable output
- Dio integration
- Flutter DevTools integration

### Error Tracking
```yaml
sentry_flutter: ^9.8.0
sentry_dart_plugin: ^3.2.0
```

**Why Sentry:**
- Industry standard
- Free tier available
- Source map support
- Performance monitoring

---

## Utilities

### Functional Programming
```yaml
fpdart: ^1.2.0  # Either, Option, TaskEither
```

### Reactive Extensions
```yaml
rxdart: ^0.28.0  # Streams, BehaviorSubject
```

### Collection Extensions
```yaml
dartx: ^1.2.0  # Kotlin-like extensions
```

---

## Version Compatibility Matrix

| Package | Min Flutter | Min Dart | Status |
|---------|-------------|----------|--------|
| riverpod 3.x | 3.0.0 | 3.0 | ✅ Stable |
| go_router 17.x | 3.29 | 3.7 | ✅ Stable |
| drift 2.29 | 3.16 | 3.3 | ✅ Stable |
| dio 5.x | 3.0.0 | 3.0 | ✅ Stable |
| freezed 3.x | 3.0.0 | 3.0 | ✅ Stable |

---

## Upgrade Strategy

### Safe to Upgrade (Patch/Minor)
Run periodically:
```bash
flutter pub upgrade
```

### Major Version Upgrades
Check changelog and test thoroughly:
```bash
flutter pub upgrade --major-versions --dry-run
```

### Check for Outdated
```bash
flutter pub outdated
```

---

## Known Constraints

Some packages have version constraints that prevent upgrading others:

1. **build_runner** - Locked to work with current analyzer version
2. **meta** - Must match Flutter SDK's version
3. **analyzer** - Constrained by build_runner and drift_dev

These are transitive dependencies and will update when the ecosystem is ready.

---

## Removed/Replaced Packages

| Old Package | Replaced With | Reason |
|-------------|---------------|--------|
| provider | riverpod | Better type safety |
| auto_route | go_router | Official support |
| moor | drift | Package renamed |
| http | dio | More features |

---

## Security Considerations

- All packages are from pub.dev (verified)
- Critical packages (sentry, grpc) are from known publishers
- Custom fork (circle_flags) is from hiddify-com organization
- No deprecated packages with known vulnerabilities
