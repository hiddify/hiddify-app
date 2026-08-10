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

1. **Material Design 3 (top priority):** the full rule set is in the next section. It governs every string.
2. **Context-based:** Hiddify is a **v2ray / VPN client**. Keep technical terms in **English** — VPN, proxy, DNS, TUN, WARP, Psiphon, VLESS, VMess, Trojan, Shadowsocks, Reality, XTLS, sing-box, inbound / outbound, TLS, ping, etc.
3. **Preserve non-text exactly:** placeholders (`$name`, `${host}`), links, plural / context blocks, modifiers. Translate values only, never keys. Keep valid JSON.

### Material Design 3 writing rules

Sources: [Material writing style](https://m1.material.io/style/writing.html) · [M3 grammar and punctuation](https://m3.material.io/foundations/content-design/style-guide/grammar-and-punctuation) · [Material error patterns](https://m1.material.io/patterns/errors.html)

**Capitalization**
- Sentence case everywhere — titles, headings, labels, menu items, buttons. Only the first word and proper nouns are capitalized.
- No all-caps.

**Punctuation**
- **Period** — none after a *single* sentence in a label, tooltip, list item or dialog body. Required when a string holds **two or more sentences**, and when a sentence is followed by a link (the period goes *before* the link).
- **Colon** — skip after a label. Use one only to introduce a list.
- **Exclamation point** — avoid; it reads as shouting. Only for a greeting or congratulation.
- **Ellipsis** — the single character `…`, no space before it, for an action in progress (`Downloading…`). Never on a menu item or button that opens a dialog.
- **Dashes** — en dash `–` for ranges, no spaces (`3–5 kg`). Hyphen for compounds and negative numbers.
- **Quotes** — curly `“ ”` and `’`, not straight. A comma goes inside the quotes.

**Voice and tone**
- Second person (`you`, `your`). Never mix with `me` / `my`. Avoid `we` unless a real person is acting for the user.
- Active voice, present tense — what the product does, not what it will do.
- Friendly, humble, positive, essential. Say only what the user needs to decide or act.

**Word choice**
- Short sentences, common words, objective first.
- Contractions when they read easier (`it's`, `can't`, `don't`). Not `it'll`, `should've`.
- No jargon: `Preparing video…`, not `Buffering…`.
- `Turn on` / `Turn off`, not `Enable` / `Disable`.
- Numerals, not words: `1, 2, 3`.
- Drop `please`, `sorry`, filler intros, and absolutes like `never`.
- Name a UI element by its label, not its widget type.
- Gender-neutral `they`; never `his/her`.

**Errors**
- Say what happened *and* how to fix it — give the user an action.
- Never blame the user or imply fault.
- Don't offer a retry that is known to fail.

**Buttons and actions**
- Prefer the standard set where it fits: `Cancel`, `Done`, `Next`, `Back`, `OK`, `Skip`, `Got it`, `Learn more`, `No thanks`, `Not now`.
- Same action, same verb, everywhere.

**How this applies to the other 10 locales.** All of it, except where a language genuinely differs:
- Capitalization rules bind Latin, Cyrillic and Greek scripts only — Arabic, Persian and CJK have no letter case.
- Contractions and singular `they` are English-only.
- Each language keeps its own quotation marks (`« »`, `「 」`, `„ “`, `» «`) and its own spacing (French keeps a space before `: ; ? !`).
- Follow the target language's own orthography where it conflicts: Spanish and Portuguese continue lowercase after a colon, Turkish capitalizes a full sentence after one.
- Plurals use that language's real CLDR forms, not a copy of English's two.

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
