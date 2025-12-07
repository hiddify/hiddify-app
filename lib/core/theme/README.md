# Hiddify Design System

This directory contains the core design system for the Hiddify application.
The system is built on top of Material 3 and includes custom extensions for specific application needs.

## Architecture

- **AppTheme** (`app_theme.dart`): The entry point for theme generation. It handles:
  - Material 3 `ColorScheme` generation from seed colors.
  - Light and Dark mode variations.
  - Font family configuration.
  - Platform-specific adaptations (e.g., disabling page transitions on desktop).

- **AppColors** (`app_colors.dart`): Central registry for all application colors.
  - modifying colors here propagates throughout the app.
  - Includes semantic colors (success, error, warning) and brand colors.

- **ThemeExtensions** (`theme_extensions.dart`): Custom theme extensions for components not covered by standard Material ThemeData.
  - `ConnectionButtonTheme`: Theming for the main connection toggle.
  - `JsonEditorTheme`: Theming for the JSON configuration editor.

## Usage

### Applying the Theme

The theme is provided via `AppTheme` class:

```dart
final appTheme = AppTheme(mode, 'Shabnam');
return MaterialApp(
  theme: appTheme.lightTheme(null),
  darkTheme: appTheme.darkTheme(null),
  ...
);
```

### Accessing Colors

Use `Theme.of(context).colorScheme` for standard Material colors.
For custom semantic colors, prefer using the `AppColors` directly or map them to the `ColorScheme` if possible.

### Adding New Colors

1. Add the color constant to `AppColors`.
2. If it's a component-specific color, consider adding a new `ThemeExtension` in `theme_extensions.dart`.

## Best Practices

- Avoid hardcoding generic colors (e.g., `Colors.red`) in widgets. Use `ColorScheme.error` or `AppColors.error`.
- Use `Theme.of(context)` to access current theme data.
