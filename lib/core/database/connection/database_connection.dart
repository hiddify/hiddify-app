import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    // final dbDir = await AppDirectories.getDatabaseDirectory();
    // final file = File(p.join(dbDir.path, 'db.sqlite'));
    return driftDatabase(
      name: "db",
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  });
}
