import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/database/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection: connection);

    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('upgrade from v2 to v3', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection: connection);

    await verifier.migrateAndValidate(db, 3);

    // final prePopulated = await db.select(db.geoAssetEntries).get();
    await db.close();
    // expect(prePopulated.length, equals(2));
  });

  test('upgrade from v1 to v3 with pre-population', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection: connection);

    await verifier.migrateAndValidate(db, 3);

    // final prePopulated = await db.select(db.geoAssetEntries).get();
    await db.close();
    // expect(prePopulated.length, equals(2));
  });
}
