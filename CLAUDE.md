# Hiddify App — Claude project instructions

## Localization / translations (slang)

The app uses **slang** (v4.8.1) for i18n — a type-safe framework that turns the JSON translation files into Dart code, with tooling for analysis, applying translations, and structural key edits. Config is in `build.yaml` under `slang_build_runner`.

Project setup:
- Base locale: `en`. Sources: `assets/translations/<locale>.i18n.json`.
- Locales (11): `en` (base) + `ar`, `es`, `fa`, `fr`, `id`, `pt-BR`, `ru`, `tr`, `zh-CN`, `zh-TW`.
- Generated code (`lib/gen/translations*.g.dart`) and the analyze reports (`_missing_translations*.json`, `_unused_translations*.json`) are **git-ignored** — never committed, no cleanup needed.
- `fallback_strategy: base_locale` → a missing secondary string shows English at runtime.
- Namespaces are off → plain key paths, e.g. `t.profile.add.title`.

### Working on translations

- **Context first.** Hiddify is a **v2ray / VPN client**. Translate every string in that context.
- **Read before you write.** The docs linked below: slang for the JSON syntax, the M3 files for the
  wording, the M1 files for what M3 does not cover. **M3 wins wherever the two disagree.**
- **English first.** Write the `en` string, then translate the other 10 locales from that English
  text — never from one of the other locales.
- **Long strings wait.** Propose the English wording and stop. Translate the rest only after I
  approve it.
- **Let the commands do the mechanical work** — regenerating the Dart code, finding what is missing
  or extra, writing translations back, moving or deleting a key. Each one is listed below with what
  it is for.
- **Commit `en` on its own** — one commit holding only `assets/translations/en.i18n.json`. The other
  10 locales go in a separate commit afterwards.

### slang documentation

All of slang is documented on one page — **https://pub.dev/packages/slang** — so nothing from it is
copied here. Open the section you need; the descriptions below are only there to tell you which one
that is.

**Inside the JSON**
- [String interpolation](https://pub.dev/packages/slang#-string-interpolation) — `$name`, `${name}`
- [Linked translations](https://pub.dev/packages/slang#-linked-translations) — one string referring to another
- [Pluralization](https://pub.dev/packages/slang#-pluralization) — CLDR forms (`zero one two few many other`), count parameter `n`
- [Custom contexts / enums](https://pub.dev/packages/slang#-custom-contexts--enums) — gender and similar variants
- [Modifiers](https://pub.dev/packages/slang#-modifiers) — `(ordinal)`, `(param=…)`, `(rich)` and the rest
- [Typed parameters](https://pub.dev/packages/slang#-typed-parameters) — a parameter with a Dart type
- [Lists](https://pub.dev/packages/slang#-lists) · [Maps](https://pub.dev/packages/slang#-maps)

**Commands**
- [Main command](https://pub.dev/packages/slang#-main-command) — `dart run slang` regenerates the Dart code. Run it after **any** JSON change, or the app stops compiling.
- [Analyze](https://pub.dev/packages/slang#-analyze-translations) — `analyze [--split] [--full]`, writes `_missing_translations*.json` and `_unused_translations*.json` into `assets/translations/`.
- [Apply](https://pub.dev/packages/slang#-apply-translations) — `apply [--locale=fa]`, writes the translated strings back into the locale files.
- [Edit](https://pub.dev/packages/slang#-edit-translations) — `edit add|delete|move|copy`, for renaming or moving a key across every locale at once instead of by hand.
- [Normalize](https://pub.dev/packages/slang#-normalize-translations) · [Outdated](https://pub.dev/packages/slang#-outdated-translations) · [Clean](https://pub.dev/packages/slang#-clean-translations) · [Statistics](https://pub.dev/packages/slang#-statistics)

### Writing rules — Material Design 3, and Material 1 for the rest

The M3 rules live in three local files, taken from the M3 style guide. **Read all three before you
write or translate any string** — they are short:

- [Grammar and punctuation](.claude/writing/m3-grammar-and-punctuation.md) — periods, contractions, commas, colons, exclamation points, ellipses, parentheses, ampersands, dashes, hyphens, italics, caps.
- [UX writing best practices](.claude/writing/m3-ux-writing-best-practices.md) — consequences, scannable text, sentence case, abbreviations.
- [Word choice](.claude/writing/m3-word-choice.md) — pronouns.

Each file carries its source URL and capture date, so it can be refreshed from the site later.

The M3 style guide has only those three pages. Six more subjects come from the older Material site,
captured the same way. Read the one that matches the string you are writing:

- [Writing style](.claude/writing/m1-writing.md) — voice and tone, word choice, present tense, no jargon, writing for translation.
- [Errors](.claude/writing/m1-errors.md) — what an error must say, blame, retry, form fields, offline.
- [Confirmation and acknowledgement](.claude/writing/m1-confirmation-and-acknowledgement.md) — when to confirm, dialog titles.
- [Permissions](.claude/writing/m1-permissions.md) — when to ask, how to explain, what to do on refusal.
- [Empty states](.claude/writing/m1-empty-states.md) — the tagline, and what to show instead of nothing.
- [Data formats](.claude/writing/m1-data-formats.md) — dates, times, ranges, durations, numbers.
