# Self-host assets before ship (privacy gate) — U3

**Why:** Woman in Red is a privacy/VPN product. It must not depend on third-party
CDNs at runtime — every CDN request leaks the user's IP / User-Agent / referer and
creates a fingerprint surface. The `design/` **preview kit** (loaded via `index.html`)
currently uses three CDNs; that is fine for the preview (a dev tool, never shipped),
but **the shipped Flutter app must self-host all three.** This file is the spec the
Flutter port follows so the privacy gate is closed by default.

Status: preview keeps using CDNs (so it stays viewable offline-of-assets); each site is
marked `TODO(privacy)` in source. The binary vendoring below could not be done in the
authoring session (no network for binaries) — it is the one carried-forward blocker.

---

## 1. Fonts — Geist + Geist Mono

**Now (preview):** `design/tokens/fonts.css` `@import`s from `fonts.googleapis.com`.
**Ship:** self-host.

- Download the Geist + Geist Mono `.woff2` (OFL, self-hosting allowed) for the weights
  actually used: sans `300/400/500/600/700`, mono `400/500/600`.
- Preview kit: drop into `design/assets/fonts/geist/`, replace the `@import` in
  `fonts.css` with local `@font-face` rules (`src: url("../assets/fonts/geist/...woff2") format("woff2")`).
- **Flutter app:** put the `.ttf`/`.otf` under `assets/fonts/` and declare them in
  `pubspec.yaml` `flutter: fonts:` (families `Geist`, `Geist Mono`). Ship the OFL license file.

## 2. Flags — country flags in `ServerRow` / `Flag`

**Now (preview):** `Flag` builds `https://flagcdn.com/w80/<cc>.png` per render.
**Ship:** bundle a local flag set keyed by ISO alpha-2.

- Use a local SVG flag set (e.g. `flag-icons`, MIT) — one asset per country code.
- Preview kit: change `Flag` in `_ds_bundle.js` to reference `design/assets/flags/<cc>.svg`.
- **Flutter app:** bundle the SVGs under `assets/flags/` (declare in `pubspec.yaml`), render
  with `flutter_svg`; key by the same ISO code. Keep the rounded hairline-ring treatment.
- Also set `Flag` `alt` to the country **name**, not the ISO code (a11y — review L3).

## 3. Icons — Lucide (`Icon`)

**Now (preview):** `index.html` loads `https://unpkg.com/lucide@latest` at runtime;
`Icon` reads `window.lucide`.
**Ship:** bundle only the icons used, no runtime fetch.

- Enumerate the Lucide names the kit uses (`power`, `shield-check`, `shield-off`,
  `chevron-right/left/down`, `settings`, `grip`, `search`, `refresh-cw`, `pencil`,
  `download`, `book-open`, `circle-help`, `list-checks`, `graduation-cap`, `shield`,
  `gauge`, `activity`, `plus`, `layers`, `eye-off`, `house-wifi`, `building-2`, …).
- Preview kit: vendor `lucide` locally (npm package or a pinned single file) instead of
  `unpkg@latest`; keep the `Icon` API (`name`, `size`, `stroke`, `color`) unchanged.
- **Flutter app:** use `lucide_icons` (or bundle the SVG subset); do not fetch at runtime.

## 4. Preview harness runtime (lower priority)

`index.html` also loads React / ReactDOM / Babel-standalone from `unpkg`. This is the
**preview harness only** — it is never part of the shipped Flutter app, so it carries no
end-user privacy cost. Vendor these locally only if a fully-offline preview is wanted.

---

## Ship verification (the privacy gate)

Exercise every screen with the network inspector open (or offline): **zero** requests to
`googleapis` / `gstatic` / `flagcdn` / `unpkg`. In the Flutter app, a release build makes
no network call for fonts, flags, or icons.
