import 'dart:io';

import 'package:path/path.dart' as p;

class GeoAssetPathResolver {
  const GeoAssetPathResolver(this._workingDir);

  final Directory _workingDir;

  Directory get directory => Directory(p.join(_workingDir.path, "geo-assets"));

  File file(String providerName, String fileName) {
    final prefix = providerName.replaceAll("/", "-").toLowerCase().trim();
    return File(
      p.join(
        directory.path,
        "$prefix${prefix.isEmpty ? "" : "-"}$fileName",
      ),
    );
  }

  /// geoasset's path relative to working directory
  String relativePath(String providerName, String fileName) {
    final fullPath = file(providerName, fileName).path;
    return p.relative(fullPath, from: _workingDir.path);
  }

  String resolvePath(String path) {
    return p.absolute(_workingDir.path, path);
  }
}
