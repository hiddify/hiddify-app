import 'dart:io';

import 'package:path/path.dart' as p;

class ProfilePathResolver {
  const ProfilePathResolver(this._workingDir);

  final Directory _workingDir;

  Directory get directory => Directory(p.join(_workingDir.path, "configs"));

  File file(String fileName) {
    return File(p.join(directory.path, "$fileName.json"));
  }

  File tempFile(String fileName) => file("$fileName.tmp");

  /// Path of the merged config file used by the multi-profile
  /// "pool fastest across all active profiles" feature.
  ///
  /// All outbound entries from every active profile are merged into this
  /// single JSON, with a top-level `urltest` group named `select` that
  /// contains every (prefixed) outbound tag. The sing-box core then
  /// auto-picks the lowest-delay one across ALL active profiles.
  File mergedFile() {
    return File(p.join(directory.path, "_merged.json"));
  }
}
