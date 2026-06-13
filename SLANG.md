# Custom Command: update-slang
Requirements: Master Flutter's `slang` framework. Perform all translations strictly based on project context (Hiddify VPN client).

Execute these phases sequentially when `update-slang` is triggered:

1. **Analyze:** 
   - Scan added files for hardcoded, deleted, or relocated keys.
   - Run `dart run slang analyze --split --full` and analyze the generated `missing_translations_*.json` and `unused_translations_*.json` files inside `assets/translations/` to identify structural gaps.

2. **Propose & Pause (CRITICAL STOP):** 
   - Based on Phase 1 data, propose the updated English translation and JSON hierarchy changes.
   - **Do NOT exit this phase or modify any other files until the user explicitly approves this English update.**

3. **MD3 Translation & Sync:** 
   - Once approved, generate translations for all other remaining languages based on the English reference.
   - Strictly follow Material Design 3 guidelines (sentence case, concise, no periods) and update the respective translation files (keep technical networking terms in English).

4. **Refactor & Build:** 
   - Update the source code, replacing hardcoded strings with `t.path.to.key`.
   - Run `dart run slang` to regenerate localization files.
   - Delete the generated `missing_translations_*.json` and `unused_translations_*.json` files from `assets/translations/` to clean up the workspace.