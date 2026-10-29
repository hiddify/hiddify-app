import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Rewrites local file references in a profile into an in-memory resource map for
/// privileged VPN engines that cannot read the app's working directory.
Future<(String, Map<String, Uint8List>)> snapshotVpnConfiguration(String path, Directory workingDirectory) async {
  final content = await File(path).readAsString();
  final resources = <String, Uint8List>{};
  final document = jsonDecode(content);
  var totalBytes = 0;
  Future<void> collect(dynamic value, String? parent) async {
    if (value is List) {
      for (final item in value) {
        await collect(item, parent);
      }
    } else if (value is Map<String, dynamic>) {
      for (final key in value.keys.toList()) {
        final item = value[key];
        final isFile =
            const {
              'certificate_path',
              'key_path',
              'client_certificate_path',
              'client_key_path',
              'private_key_path',
            }.contains(key) ||
            (key == 'path' && (value['type'] == 'local' || parent == 'geoip' || parent == 'geosite'));
        if (isFile && item is String && item.isNotEmpty) {
          final source = File(p.isAbsolute(item) ? item : p.join(workingDirectory.path, item));
          final bytes = await source.readAsBytes();
          totalBytes += bytes.length;
          if (totalBytes > 32 * 1024 * 1024) {
            throw StateError(
              'Local VPN resources exceed the 32 MB snapshot limit. Use remote rule sets for large files.',
            );
          }
          final name = '${resources.length}-${p.basename(item).replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_')}';
          resources[name] = bytes;
          value[key] = 'resources/$name';
        } else {
          await collect(item, key);
        }
      }
    }
  }

  await collect(document, null);
  return (jsonEncode(document), resources);
}
