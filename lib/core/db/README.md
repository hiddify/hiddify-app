# Local database (drift) — schema & migrations

Local SQLite via [drift](https://drift.simonbinder.eu).

> **Applies to `drift` / `drift_dev` 2.26.x** (see `pubspec.lock`). The migration
> tooling and CLI change between major versions — re-check the docs if that bumps.
>
> Official docs: [Migrations](https://drift.simonbinder.eu/Migrations/) ·
> [Migration tests](https://drift.simonbinder.eu/Migrations/tests/)

⚠️ **Migrations run on every user's device on app update.** A wrong or missing one can
crash the app on startup or lose profiles — treat every schema change as sensitive.

## Files

- `db.dart` — **the only file edited by hand**: table definitions, `schemaVersion`, and
  the `MigrationStrategy` (`stepByStep`).
- **Generated, do not edit:** `db.g.dart` (gitignored), `db.steps.dart` (versioned schema
  snapshots), `schemas/db/drift_schema_vN.json`, `test/drift/db/generated/*`.
- `test/drift/db/migration_test.dart` — hand-editable migration tests.

## How it works

On startup drift compares the DB's stored version with `schemaVersion` and runs
`stepByStep`, applying each `fromXToY` **in order** (a user on v3 → v7 runs 3→4→5→6→7).
Each step gets a `Migrator m` and the **target version's `schema` snapshot** — always use
`schema.<table>.<column>`, never the live table, so old steps keep compiling later.

## Changing the schema

1. Edit `db.dart`: change the table(s) and **bump `schemaVersion` by 1**.
   New columns **must be nullable or have `.withDefault(...)`** (SQLite can't add a
   `NOT NULL` column without a default to existing rows).
2. Regenerate snapshot + steps + test helpers (reads paths from `build.yaml`):
   ```sh
   dart run drift_dev make-migrations
   ```
   Explicit equivalents — the DB is named `db`, so snapshots live in the `schemas/db`
   subdir (`make-migrations` derives this; these commands take it directly):
   ```sh
   dart run drift_dev schema dump lib/core/db/db.dart lib/core/db/schemas/db
   dart run drift_dev schema steps lib/core/db/schemas/db lib/core/db/db.steps.dart
   dart run drift_dev schema generate --data-classes --companions lib/core/db/schemas/db test/drift/db/generated
   ```
3. Add the matching step in `stepByStep`, e.g.:
   ```dart
   from6To7: (m, schema) async {
     await m.addColumn(schema.profileEntries, schema.profileEntries.pinned);
   },
   ```
   (Other ops: `dropColumn`, `renameColumn`, `createTable`, `alterTable(TableMigration(...))`.)
4. Regenerate main code: `dart run build_runner build --delete-conflicting-outputs`
5. Test: `flutter test test/drift/db/migration_test.dart` — the "simple migrations" group
   auto-tests every version pair. Only add a data-integrity test when a step *transforms
   existing data* (changes a column's type/constraints); add-only-column steps don't need one.

## Rules

- Never hand-edit generated files. Never delete or renumber an existing `fromXToY` step or
  schema JSON — users may still be upgrading from that version.
- Every schema change needs a matching step, or users on the old version crash on upgrade.
- Commit the regenerated files **together** with the `db.dart` change.
