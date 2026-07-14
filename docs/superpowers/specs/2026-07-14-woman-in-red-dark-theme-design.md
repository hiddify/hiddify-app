# Woman in Red Dark Theme Design

## Goal

Make the entire mobile application visually coherent with the approved Woman in Red home screen by shipping a dark-only interface for the current release. Preserve the existing Flutter architecture and business behavior while replacing the accidental mix of a forced-dark Home screen and system-themed secondary screens with one global semantic theme.

## Product decision

- The application is dark-only for this phase.
- The app does not follow the device light appearance yet.
- Woman in Red red (`#FF2D3E`) is the global interactive tint, not a decorative text color.
- A future light appearance remains possible because components consume semantic theme roles rather than hard-coded dark colors.

## Apple design principles

The implementation follows the intent of Apple Human Interface Guidelines within Flutter:

- Use a stable hierarchy of semantic background, surface, label, fill, and separator roles.
- Keep navigation and controls visually distinct from content.
- Reserve Liquid Glass treatment for the floating tab bar and transient interactive layers; content cards use opaque or standard-material surfaces.
- Use color consistently: red communicates selection or interactivity, while green, yellow, and destructive red communicate status.
- Preserve legibility under increased contrast and reduced-transparency accessibility settings.
- Keep interactive targets at least 44 points on iOS.

References:

- Apple HIG: Color — https://developer.apple.com/design/human-interface-guidelines/color
- Apple HIG: Materials — https://developer.apple.com/design/human-interface-guidelines/materials
- Apple HIG: Dark Mode — https://developer.apple.com/design/human-interface-guidelines/dark-mode
- Apple HIG: Tab bars — https://developer.apple.com/design/human-interface-guidelines/tab-bars

## Theme architecture

### Global ownership

`AppTheme` owns the application-wide dark `ThemeData`, `ColorScheme`, component themes, system-overlay appearance, and `NovaThemeData`. The app root selects the dark theme for every route. Individual screens must not create private `ThemeData`, force a separate brightness, or hard-code a parallel palette.

The existing Home-only `Theme` wrapper and the dock's direct `NovaThemeData.dark` reference are removed. Both consume `Theme.of(context)` and `NovaThemeData.of(context)` so they share the same contract as Servers, Rules, Settings, sheets, and dialogs.

### Semantic palette

The theme exposes these roles:

| Role | Intended appearance | Usage |
| --- | --- | --- |
| Background | Near-black | Root scaffolds and full-screen content |
| Grouped background | Slightly lifted black | Settings and grouped lists |
| Surface | Dark gray | Cards, list rows, sheets |
| Elevated surface | Lighter dark gray | Dialogs, selected rows, elevated controls |
| Primary label | Near-white | Titles and primary values |
| Secondary label | Mid gray | Descriptions and inactive labels |
| Tertiary label | Dim gray | Metadata and supporting hints |
| Separator | Low-contrast light stroke | Group and row separation |
| Accent | `#FF2D3E` | Primary actions, selection, links, progress |
| Accent pressed | Darker red | Pressed and focused states |
| Accent fill | Transparent red tint | Selected backgrounds and subtle emphasis |

Raw palette values live only in theme tokens. Feature widgets consume semantic roles.

### Component themes

The global theme defines dark variants for:

- `Scaffold`, `AppBar`, navigation rail, floating dock, and system overlays;
- list tiles, cards, dividers, grouped settings sections, and selection states;
- filled, tonal, outlined, text, and icon buttons;
- switches, radio buttons, checkboxes, sliders, and progress indicators;
- text fields, search fields, menus, dialogs, snackbars, bottom sheets, and pickers.

Red is used for enabled interactive emphasis and selected state. Disabled controls use semantic low-emphasis fills and labels. Destructive actions use the theme error role and must remain distinguishable from ordinary Woman in Red accent actions through copy, iconography, and context.

## Screen treatment

### Home

Keep the current radar ritual, connection control, profile card, and glass dock. Rebase them onto the global theme. Preserve the single red focal point around connection state. Radar lines and glyphs use semantic separators and tertiary labels instead of hard-coded white or blue-gray values.

### Servers

Use grouped dark surfaces for server groups and rows. Active server selection uses a restrained red tint plus a red symbol or checkmark. Latency remains status-colored and must not reuse the brand red for neutral values.

### Rules

Present routing options as dark grouped lists. Selection and enabled controls use red tint; explanatory copy uses secondary labels. Sheets and inline editors share the same surface hierarchy.

### Settings

Use an iOS-style grouped hierarchy: near-black grouped background, dark section surfaces, subtle separators, primary labels, and secondary values. Switches and selected options use Woman in Red tint. Hide the appearance picker for this dark-only phase instead of presenting light or system options that do nothing. Preserve an existing stored preference for future compatibility, but ignore it while the product decision is dark-only.

### Overlays and empty states

Dialogs, bottom sheets, menus, snackbars, QR surfaces, loading states, and empty-profile flows are part of the theme migration. A white overlay is a release-blocking visual regression unless white is functionally required for content such as a scannable QR code; in that case, white stays inside a bounded content canvas while the surrounding chrome remains dark.

## Typography and symbols

- Preserve the app's locale-aware font selection and iOS platform rendering.
- Use the existing type scale, but map every style to semantic label colors.
- Prefer platform-appropriate symbols and familiar Material/Cupertino equivalents already used by the Flutter app.
- Keep labels in sentence case and use concise action-oriented copy.
- Monospace remains limited to technical values, traffic, latency, and ritual details; it is not the general UI font.

## Motion and accessibility

- Preserve haptic selection feedback for the tab bar.
- Respect `disableAnimations` and `accessibleNavigation` for nonessential motion.
- Disable or thicken translucent glass when increased contrast or reduced transparency makes the dock difficult to read.
- Keep text contrast at least 4.5:1; target 7:1 for small secondary text where practical.
- Keep every tappable control at least 44 by 44 logical pixels.
- Do not communicate connection, error, or selection state by color alone.

## State and data flow

No business-state architecture changes are required. Riverpod providers continue to supply connection, profile, proxy, routing, and settings data. Theme data flows from the app root through Flutter's inherited theme APIs; feature widgets only read semantic theme roles.

Theme migration must not change navigation, VPN connection behavior, profile parsing, server selection, routing logic, persistence, or subscription access.

## Error handling

- Async and validation errors use the semantic error role, explicit copy, and an icon where appropriate.
- Disabled and unavailable states remain legible and explain the next action.
- Missing theme extensions fall back to the global dark Woman in Red contract rather than to a light or generic Material palette.
- Any screen that renders without the expected semantic theme is treated as a test failure.

## Testing and verification

Implementation follows test-driven development:

1. Add failing tests for the global dark theme contract and Woman in Red accent roles.
2. Add failing widget tests proving Home and the dock consume inherited theme data instead of hard-coded dark instances.
3. Add representative widget tests for Servers, Rules, Settings, dialogs, and sheets to catch light surfaces and incorrect tint.
4. Add accessibility assertions for 44-point targets, selected-state semantics, reduced motion, and high contrast.
5. Run focused tests, the full Flutter test suite, formatter, and analyzer.
6. Build and launch the iOS app on iPhone 17 Pro.
7. Visually inspect Home, Servers, Rules, Settings, and at least one dialog or bottom sheet.
8. Search runtime logs for Flutter exceptions, overflow, `ParentData`, and rendering failures.

## Acceptance criteria

- Every primary mobile route and overlay uses the same dark semantic theme.
- No route unexpectedly switches to a light scaffold, card, list, dialog, or sheet.
- Woman in Red red is the only ordinary interactive accent across the application.
- The Home screen and glass dock retain their approved visual identity without private theme overrides.
- Navigation and VPN business behavior remain unchanged.
- Automated verification passes and simulator screenshots show a coherent dark application across the required screens.
