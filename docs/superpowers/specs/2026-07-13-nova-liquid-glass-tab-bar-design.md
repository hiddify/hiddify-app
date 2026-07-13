# Nova Liquid Glass Tab Bar

## Goal

Replace the flat full-width Nova bottom navigation with a floating, Apple-inspired Liquid Glass dock while preserving the existing Woman in Red Hero, radar field, server card, connection states, and red/black visual identity.

The dock must support clear top-level navigation without competing with the central connection ritual.

## Baseline

The Nova prototype already provides the intended product design:

- `Home.jsx` assembles the existing Home screen.
- `RitualHero.jsx` owns the connection ritual and its `off`, `connecting`, `on`, and `error` states.
- `RadarField.jsx` provides the atmospheric background.
- `App.jsx` exposes four top-level sections: Home, Servers, Rules, and Settings.

The current `TabBar` in `design/_ds_bundle.js` is a 64 px, edge-to-edge dark strip. It has four icon-only items, a top border, and a red glow on the selected icon. This treatment is visually detached from the Hero and does not communicate the tab names clearly.

## Approaches Considered

### A. Refined full-width strip

Keep the existing bar footprint, add labels, soften the border, and improve safe-area spacing.

This is the lowest-risk implementation, but it keeps the web/Material-like silhouette and does not create the desired modern iOS hierarchy.

### B. Floating regular-glass dock — selected

Place four labeled tabs in a floating dark glass capsule above the home indicator. Use restrained blur, a subtle highlight stroke, and a compact selected lens.

This best separates navigation from content while allowing the Nova radar and cards to remain perceptible underneath. It also preserves the Hero as the strongest element on the screen.

### C. Ritual dock

Extend option B with an animated radar pulse under the selected tab.

This is distinctive, but it creates a second ritual-like focal point and risks competing with the connection Hero. It is deferred until the restrained version has been validated.

## Selected Design

### Nova Design System Integration

The existing Nova Design System is the source of truth. The dock must extend it rather than introduce a parallel set of inline values.

The implementation follows the existing primitive-to-semantic structure in `design/tokens/` and adds a component-token layer for navigation:

- Existing primitives remain in `colors.css`, `spacing.css`, `radius.css`, `elevation.css`, `motion.css`, and `typography.css`.
- Existing semantic aliases such as `--accent`, `--accent-fill`, `--text-primary`, `--text-tertiary`, `--border`, and `--bg-sheet` remain the meaning layer.
- New `--tabbar-*` component aliases are defined in `design/tokens/components.css` and imported by `design/styles.css` after the foundational token files.
- `TabBar` consumes only Nova tokens. Raw colors, spacing, radii, shadows, blur values, duration values, and font declarations are not hard-coded in the component.

Initial component-token mapping:

```css
--tabbar-height: var(--sp-11);
--tabbar-inset-x: var(--sp-4);
--tabbar-bottom-gap: var(--sp-3);
--tabbar-radius: calc(var(--tabbar-height) / 2);
--tabbar-bg: var(--glass-regular);
--tabbar-border: var(--border);
--tabbar-highlight: var(--sheen-top);
--tabbar-shadow: var(--shadow-dock);
--tabbar-blur: var(--blur-nav);
--tabbar-item-fg: var(--text-tertiary);
--tabbar-item-selected-fg: var(--accent-hover);
--tabbar-item-selected-bg: var(--accent-fill);
--tabbar-item-radius: var(--r-xl);
--tabbar-item-min-target: var(--touch-min);
--tabbar-item-padding: var(--sp-2) var(--sp-3);
--tabbar-item-gap: var(--sp-1);
--tabbar-icon-size: var(--sp-6);
--tabbar-label-font: var(--w-medium) var(--fs-micro)/1 var(--font-sans);
--tabbar-transition: var(--dur-2) var(--ease-out);
```

The three missing foundation values — `--glass-regular`, `--shadow-dock`, and `--blur-nav` — are added beside their related color/elevation primitives. They are reusable navigation-surface primitives, not TabBar-only literals.

### Structure

- Four stable destinations: `Главная`, `Серверы`, `Правила`, `Настройки`.
- The connection power control remains exclusively inside the Hero and is never used as a tab icon.
- The dock floats 8 px above the iPhone home-indicator safe area.
- Horizontal screen inset uses `--tabbar-inset-x`, mapped to the existing 12 px rhythm step.
- Dock height uses `--sp-11` (64 px); corner radius derives from half the component height.
- Each tab receives an equal-width area and a minimum 44 x 44 px interaction target.

### Material

- Dark background: `--tabbar-bg`, backed by the reusable `--glass-regular` primitive.
- Backdrop blur: `--tabbar-blur`, backed by the reusable `--blur-nav` primitive.
- Saturation: keep native/default in the prototype; do not simulate glossy chromatic distortion.
- Outer stroke: existing semantic `--border` through `--tabbar-border`.
- Inner top highlight: existing `--sheen-top` through `--tabbar-highlight`.
- Shadow: `--tabbar-shadow`, backed by the reusable `--shadow-dock` elevation primitive.
- No permanent red border and no large red glow around the dock.

These values are prototype targets, not a substitute for semantic system materials in native implementation.

### Tab item

- Layout: icon above a one-word label.
- Icon size: existing 20 px rhythm value through `--tabbar-icon-size`.
- Label style: existing `--fs-micro`, `--w-medium`, and `--font-sans` through `--tabbar-label-font`.
- Gap between icon and label: existing `--sp-1` through `--tabbar-item-gap`.
- Inactive foreground: semantic `--text-tertiary` through `--tabbar-item-fg`.
- Selected foreground: semantic `--accent-hover` through `--tabbar-item-selected-fg`.
- Selected lens: semantic `--accent-fill` through `--tabbar-item-selected-bg`.
- Selected state uses color, lens shape, icon weight, and label weight together; it never relies on red alone.
- Remove the existing 8 px red drop shadow. A maximum 4 px low-opacity accent bloom is acceptable only if the active state feels too flat during visual review.

### Motion and feedback

- Selection transition: existing `--dur-2` and `--ease-out` through `--tabbar-transition`.
- Lens movement: restrained ease-out or low-bounce spring.
- Icon scale: at most `1.04` on selection.
- No looping animation in the dock.
- Native implementation should use selection haptics once per tab change.
- Reduce Motion disables lens movement and uses a cross-fade.

### Content relationship

- The existing Hero, radar, server card, status messaging, flags, and connection animations remain unchanged.
- Scrollable Home content receives enough bottom padding that its last item can clear the floating dock and home indicator.
- Content may remain visible beneath the dock to create depth, but interactive content must not be obscured by it.
- The dock remains visible across all four top-level sections and preserves each section's navigation state.

## Light, Contrast, and Accessibility

- Dark appearance is the primary Woman in Red presentation.
- A light semantic variant is defined for system compatibility but is not required to replace the primary dark product identity.
- Reduce Transparency replaces blur with an opaque `var(--surface-2)` background.
- Increase Contrast strengthens the stroke, inactive labels, and selected lens.
- All tab items expose accessible labels and selected state.
- Labels remain present in the visual UI; VoiceOver labels are not a replacement for visible labels.
- Text and icons must remain readable at 200% browser zoom in the prototype and with larger accessibility sizes in the production app.

## iPadOS Adaptation

The floating bottom dock is the iPhone compact-width treatment. It is not stretched across iPad screens.

For iPadOS, the same four destinations should adapt to a top tab bar or sidebar. The visual tokens and selected-state logic remain shared, but the layout component changes with size class.

## Prototype Implementation Boundary

The first implementation changes only the Nova prototype:

- Add reusable navigation material primitives to the relevant Nova token files.
- Add `design/tokens/components.css` with the `--tabbar-*` aliases and import it from `design/styles.css`.
- Update the bundled `TabBar` component in `design/_ds_bundle.js`.
- Add localized labels to the four items in `design/ui_kits/nova-ios/App.jsx`.
- Add bottom content clearance only if visual verification shows overlap.

Do not modify the visual content or behavior of `Home.jsx`, `RitualHero.jsx`, `RadarField.jsx`, connection logic, or the Flutter production navigation in this prototype pass. A bottom-padding-only change in `Home.jsx` is permitted if required to keep content clear of the floating dock.

Flutter integration is a follow-up implementation based on the approved and visually verified component.

## Acceptance Criteria

The prototype passes when:

1. The existing Nova Hero is visually unchanged.
2. All four destinations have visible Russian labels.
3. The dock is a floating capsule rather than an edge-to-edge strip.
4. The dock clears the home indicator and respects the bottom safe area.
5. The selected tab is identifiable without relying on color alone.
6. No Home content is unreachable or hidden beneath the dock.
7. The red selection treatment does not compete with the connection Hero.
8. The bar remains legible over the darkest and brightest visible parts of the Nova screen.
9. Keyboard focus is visible in the browser prototype.
10. Reduced-motion behavior is respected by CSS or component logic.
11. The component contains no raw visual constants that belong in the Nova token system.
