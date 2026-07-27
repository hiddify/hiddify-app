# Hiddify App — Claude project instructions

## Localization / translations (slang)

The app uses **slang** (v4.8.1) for i18n — a type-safe framework that turns the JSON translation files into Dart code, with tooling for analysis, applying translations, and structural key edits. Config is in `build.yaml` under `slang_build_runner`.

**Official docs: https://pub.dev/packages/slang** — read them whenever you need slang's syntax or features (plurals, context, linked translations, modifiers, interpolation). Learn the framework's rules yourself; they are not repeated here.

Project setup:
- Base locale: `en`. Sources: `assets/translations/<locale>.i18n.json`.
- Locales (11): `en` (base) + `ar`, `es`, `fa`, `fr`, `id`, `pt-BR`, `ru`, `tr`, `zh-CN`, `zh-TW`.
- Generated code (`lib/gen/translations*.g.dart`) and the analyze reports (`_missing_translations*.json`, `_unused_translations*.json`) are **git-ignored** — never committed, no cleanup needed.
- `fallback_strategy: base_locale` → a missing secondary string shows English at runtime.
- Namespaces are off → plain key paths, e.g. `t.profile.add.title`.

### Essential commands

- `dart run slang` — generate the Dart code from the JSON. Run after **any** JSON change so the app compiles.
- `dart run slang analyze [--split] [--full]` — compare every locale against `en`. Writes `_missing_translations*.json` (in `en`, missing elsewhere) and `_unused_translations*.json` (in a locale, not in `en`) into `assets/translations/`. `--split` = one file per locale; `--full` = also flag `en` keys unused in `lib/` source.
- `dart run slang apply [--locale=fa]` — write the **translated** `_missing_translations*.json` back into each locale file (keeps `en`'s key order).

slang also has `edit add/delete/move/copy`, `clean`, `normalize`, `outdated`, and `stats` — use these (see docs) for structural edits instead of hand-editing every locale.

### Translation principles (priority order)

1. **Material Design 3 (top priority):** sentence case, concise, no trailing period on short UI strings, action-oriented.
2. **Context-based:** Hiddify is a **v2ray / VPN client**. Keep technical terms in **English** — VPN, proxy, DNS, TUN, WARP, Psiphon, VLESS, VMess, Trojan, Shadowsocks, Reality, XTLS, sing-box, inbound / outbound, TLS, ping, etc.
3. **Preserve non-text exactly:** placeholders (`$name`, `${host}`), links, plural / context blocks, modifiers. Translate values only, never keys. Keep valid JSON.

### During development — English only

- Edit **only** `assets/translations/en.i18n.json` — text and JSON structure.
- Leave the other 10 locales untouched (fallback shows English). This saves tokens and time.
- For **important or long** strings, propose the English wording and **wait for my approval**.
- To rename / move / delete an existing key, run `dart run slang edit move|delete <path>` (token-free, keeps existing translations).
- Run `dart run slang` after editing so the app compiles.

### Committing translation edits

This applies to **any commit that contains translation edits** — not every commit. A code-only change is committed normally. Translation edits go in their own commit(s), never mixed with code, for a clean translation history:

1. **English / source — on its own, first.** Stage and commit **only** `assets/translations/en.i18n.json`. During development you edit only `en`, so at commit time it is normally the only changed translation file — that is why English comes first.
2. **Other 10 locales — together, afterwards.** When you translate them: `dart run slang analyze --split` → translate the missing strings (principles above) → `dart run slang apply` → `dart run slang` → stage all the other `assets/translations/*.i18n.json` files and commit them in one commit.

### Final check (after both commits)

`dart run slang analyze --full` → both reports should hold no locale entries (only the `@@info` header): nothing missing, nothing extra. If something shows up, tell me and fix it in a follow-up.
