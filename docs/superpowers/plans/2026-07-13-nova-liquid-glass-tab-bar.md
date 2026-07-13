# Nova Liquid Glass Tab Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat Nova prototype bottom bar with a token-driven floating Liquid Glass dock while leaving the existing Woman in Red Hero visually and behaviorally unchanged.

**Architecture:** Extend the existing Nova token stack with reusable navigation-material primitives and a `--tabbar-*` component-token layer. Keep the current bundled `TabBar` public interface (`items`, `value`, `onChange`, `style`), update its rendering and accessibility in place, then supply visible labels from `App.jsx` and add only the bottom clearance needed by the overlay.

**Tech Stack:** CSS custom properties, React 18 UMD prototype, generated plain-JavaScript design-system bundle, Babel JSX browser preview, Nova token CSS.

## Global Constraints

- `Home.jsx`, `RitualHero.jsx`, `RadarField.jsx`, connection states, and Hero motion remain visually unchanged.
- The existing Nova Design System is the only source of visual values.
- The `TabBar` component contains no raw color, spacing, radius, shadow, blur, duration, or font values.
- Four stable destinations remain visible: `Главная`, `Серверы`, `Правила`, `Настройки`.
- The power control remains in the Hero and is never used as a tab icon.
- The dock uses a 64 px tokenized height, 12 px tokenized horizontal inset, and 8 px tokenized gap above the safe area.
- Each tab has at least the existing `--touch-min` 44 px target.
- The active state uses foreground, background lens, icon weight, and `aria-current`; it does not rely on red alone.
- Existing unrelated changes in `ios/Podfile.lock` and `ios/Runner.xcodeproj/project.pbxproj` are never staged.

---

## File Map

- Create `design/tokens/components.css`: component aliases for the Nova `TabBar`.
- Modify `design/tokens/colors.css`: reusable `--glass-regular` navigation material primitive.
- Modify `design/tokens/elevation.css`: reusable `--shadow-dock` and `--blur-nav` primitives.
- Modify `design/styles.css`: import component tokens after all foundation tokens.
- Modify `design/_ds_bundle.js`: render the floating accessible dock using only `--tabbar-*` aliases.
- Modify `design/ui_kits/nova-ios/App.jsx`: supply Russian labels for all four destinations.
- Modify `design/ui_kits/nova-ios/Home.jsx`: change only bottom padding so scroll content clears the overlay.

---

### Task 1: Extend the Nova token architecture

**Files:**
- Create: `design/tokens/components.css`
- Modify: `design/tokens/colors.css`
- Modify: `design/tokens/elevation.css`
- Modify: `design/styles.css`

**Interfaces:**
- Consumes: existing primitive and semantic tokens in `design/tokens/*.css`.
- Produces: `--glass-regular`, `--shadow-dock`, `--blur-nav`, and the complete `--tabbar-*` component-token contract used by Task 2.

- [ ] **Step 1: Run the precondition check and confirm the tokens do not exist**

Run:

```bash
! rg -n -- '--glass-regular|--shadow-dock|--blur-nav|--tabbar-height' design/tokens design/styles.css
```

Expected: exit 0 because none of the new tokens exists yet.

- [ ] **Step 2: Add reusable material primitives**

Add to the primitive section of `design/tokens/colors.css`:

```css
  /* ---- Translucent navigation materials ---- */
  --glass-regular: rgba(18, 18, 22, 0.62);
```

Add to `design/tokens/elevation.css`:

```css
  --shadow-dock: 0 12px 32px rgba(0, 0, 0, 0.34);
  --blur-nav: 28px; /* @kind other */
```

- [ ] **Step 3: Create the component-token layer**

Create `design/tokens/components.css` with:

```css
/* ============================================================
   NOVA VPN — COMPONENT TOKENS
   Component aliases consume semantic/foundation tokens only.
   ============================================================ */

:root {
  /* Floating iPhone tab bar */
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
  --tabbar-transition-reduced: var(--dur-1) var(--ease-out);
}
```

- [ ] **Step 4: Import component tokens after the foundations**

In `design/styles.css`, insert this immediately after `tokens/motion.css` and before `base.css`:

```css
@import url("tokens/components.css");
```

- [ ] **Step 5: Verify the token dependency chain**

Run:

```bash
rg -n -- '--glass-regular|--shadow-dock|--blur-nav|--tabbar-' design/tokens design/styles.css
```

Expected: the three primitives appear once, all component aliases appear in `components.css`, and `styles.css` imports the file once.

- [ ] **Step 6: Commit the token layer only**

```bash
git add design/tokens/colors.css design/tokens/elevation.css design/tokens/components.css design/styles.css
git commit -m "feat(design): add Nova navigation glass tokens"
```

---

### Task 2: Convert the bundled TabBar into a floating dock

**Files:**
- Modify: `design/_ds_bundle.js:1435-1494`

**Interfaces:**
- Consumes: the `--tabbar-*` contract from Task 1 and the existing `Icon` component.
- Produces: unchanged `TabBar({ items, value, onChange, style })` API with visible labels, selected lens, semantic ARIA state, and floating placement.

- [ ] **Step 1: Record the failing static expectations**

Run:

```bash
rg -n 'background: "rgba\(16,16,21,0.86\)"|borderTop:|drop-shadow\(0 0 8px' design/_ds_bundle.js
```

Expected: all three obsolete treatments are present.

- [ ] **Step 2: Replace the `TabBar` implementation**

Keep the current function signature and replace its returned structure with:

```js
  const reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  return /*#__PURE__*/React.createElement("div", {
    role: "tablist",
    "aria-label": "Основная навигация",
    style: {
      position: "absolute",
      left: "var(--tabbar-inset-x)",
      right: "var(--tabbar-inset-x)",
      bottom: "calc(var(--safe-bottom) + var(--tabbar-bottom-gap))",
      zIndex: 18,
      display: "flex",
      alignItems: "center",
      justifyContent: "space-around",
      height: "var(--tabbar-height)",
      padding: "0 var(--sp-2)",
      boxSizing: "border-box",
      background: "var(--tabbar-bg)",
      border: "1px solid var(--tabbar-border)",
      borderRadius: "var(--tabbar-radius)",
      boxShadow: "var(--tabbar-highlight), var(--tabbar-shadow)",
      backdropFilter: "blur(var(--tabbar-blur))",
      WebkitBackdropFilter: "blur(var(--tabbar-blur))",
      ...style
    }
  }, items.map(it => {
    const active = it.id === value;
    const label = it.label || it.id;
    return /*#__PURE__*/React.createElement("button", {
      key: it.id,
      type: "button",
      role: "tab",
      "aria-label": label,
      "aria-selected": active,
      "aria-current": active ? "page" : undefined,
      onClick: () => onChange && onChange(it.id),
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        flex: 1,
        minWidth: 0,
        minHeight: "var(--tabbar-item-min-target)",
        padding: 0,
        cursor: "pointer",
        border: 0,
        background: "transparent",
        color: active ? "var(--tabbar-item-selected-fg)" : "var(--tabbar-item-fg)",
        WebkitTapHighlightColor: "transparent"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: "var(--tabbar-item-gap)",
        minWidth: "var(--tabbar-item-min-target)",
        padding: "var(--tabbar-item-padding)",
        boxSizing: "border-box",
        borderRadius: "var(--tabbar-item-radius)",
        background: active ? "var(--tabbar-item-selected-bg)" : "transparent",
        transform: reduceMotion ? "none" : active ? "scale(1.02)" : "scale(1)",
        transition: reduceMotion
          ? "color var(--tabbar-transition-reduced), background var(--tabbar-transition-reduced)"
          : "color var(--tabbar-transition), background var(--tabbar-transition), transform var(--tabbar-transition)"
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: it.icon,
      size: "var(--tabbar-icon-size)",
      stroke: active ? 2 : 1.75
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        font: "var(--tabbar-label-font)",
        letterSpacing: "var(--ls-tight)",
        whiteSpace: "nowrap"
      }
    }, label)));
  }));
```

- [ ] **Step 3: Verify JavaScript syntax and removal of obsolete treatments**

Run:

```bash
node --check design/_ds_bundle.js
! rg -n 'background: "rgba\(16,16,21,0.86\)"|borderTop:|drop-shadow\(0 0 8px' design/_ds_bundle.js
rg -n 'role: "tablist"|"aria-selected"|var\(--tabbar-bg\)' design/_ds_bundle.js
```

Expected: syntax check exits 0, obsolete treatments have no matches, and all three new contracts are present.

- [ ] **Step 4: Commit the component change**

```bash
git add design/_ds_bundle.js
git commit -m "feat(design): turn Nova tab bar into glass dock"
```

---

### Task 3: Supply labels and reserve overlay clearance

**Files:**
- Modify: `design/ui_kits/nova-ios/App.jsx:55-57`
- Modify: `design/ui_kits/nova-ios/Home.jsx:27`

**Interfaces:**
- Consumes: existing four tab IDs and the floating dock geometry from Tasks 1–2.
- Produces: visible Russian labels and scrollable content that clears the dock.

- [ ] **Step 1: Confirm labels and clearance are currently absent**

Run:

```bash
! rg -n 'label:"(Главная|Серверы|Правила|Настройки)"' design/ui_kits/nova-ios/App.jsx
! rg -n -- '--tabbar-height.*--safe-bottom' design/ui_kits/nova-ios/Home.jsx
```

Expected: both commands exit 0 because the required values are absent.

- [ ] **Step 2: Add the four visible labels**

Replace the `items` array in `App.jsx` with:

```jsx
items={[
  {id:"home",icon:"house",label:"Главная"},
  {id:"servers",icon:"globe",label:"Серверы"},
  {id:"rules",icon:"shield",label:"Правила"},
  {id:"settings",icon:"settings",label:"Настройки"}
]}
```

- [ ] **Step 3: Add bottom clearance without changing Home content**

In the existing Home card-stack container, change only the bottom padding:

```jsx
<div style={{ padding:"4px var(--gutter) calc(var(--tabbar-height) + var(--safe-bottom) + var(--tabbar-bottom-gap) + var(--sp-5))", display:"flex", flexDirection:"column", gap:16 }}>
```

- [ ] **Step 4: Verify labels and clearance**

Run:

```bash
rg -n 'label:"(Главная|Серверы|Правила|Настройки)"' design/ui_kits/nova-ios/App.jsx
rg -n -- 'calc\(var\(--tabbar-height\).*var\(--safe-bottom\)' design/ui_kits/nova-ios/Home.jsx
git diff --check
```

Expected: four label matches, one clearance match, and no whitespace errors.

- [ ] **Step 5: Commit the integration**

```bash
git add design/ui_kits/nova-ios/App.jsx design/ui_kits/nova-ios/Home.jsx
git commit -m "feat(design): label Nova tabs and clear home content"
```

---

### Task 4: Visual and interaction verification

**Files:**
- Inspect: `design/ui_kits/nova-ios/index.html`
- Inspect: all files changed in Tasks 1–3
- Modify only if verification exposes a concrete defect.

**Interfaces:**
- Consumes: completed Nova prototype.
- Produces: verified Hero-preserving dock at the existing `390 x 844` design size.

- [ ] **Step 1: Start the local preview**

Run from `design/`:

```bash
python3 -m http.server 4173 --bind 127.0.0.1
```

Expected: `Serving HTTP on 127.0.0.1 port 4173`.

- [ ] **Step 2: Open the Nova card and enter the app**

Open `http://127.0.0.1:4173/ui_kits/nova-ios/`, verify the Welcome screen renders, and activate the unique `Войти` button.

Expected: the existing Woman in Red Home screen appears with the unchanged Ritual Hero.

- [ ] **Step 3: Verify the dock visually**

Check all of the following at once:

- floating capsule with visible left/right void around it;
- home indicator below the dock with no overlap;
- all four Russian labels visible without truncation;
- active lens restrained enough that the Hero remains dominant;
- final Home content can scroll fully above the dock;
- no new red glow outside the active lens;
- no change to radar, connection button, status pill, copy, server card, flags, or traffic card.

- [ ] **Step 4: Verify all tab states**

Activate `Серверы`, `Правила`, `Настройки`, then `Главная`.

Expected for each activation: exactly one tab reports selected state, the corresponding screen appears, the dock remains stable, and no item shifts horizontally.

- [ ] **Step 5: Verify keyboard focus and reduced motion**

Use Tab/Shift-Tab to traverse all four destinations and confirm the existing Nova focus ring remains visible. Emulate or enable `prefers-reduced-motion: reduce` and confirm the dock does not introduce looping or bouncing motion.

- [ ] **Step 6: Run final static checks**

```bash
node --check design/_ds_bundle.js
git diff --check
git status --short
```

Expected: syntax and whitespace checks pass. Status may still show the pre-existing Xcode changes, but no uncommitted Nova implementation files remain.

- [ ] **Step 7: Commit any verification-only correction, if one was necessary**

Stage only the exact Nova files corrected during QA and use:

```bash
git commit -m "fix(design): polish Nova glass dock after visual QA"
```

If no correction was necessary, do not create an empty commit.
