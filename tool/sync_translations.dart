import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final translationsDir = Directory('assets/translations');
  final enPath = File('${translationsDir.path}/en.i18n.json');
  final faPath = File('${translationsDir.path}/fa.i18n.json');
  final placeholdersEmpty = args.contains('--empty');

  if (!await enPath.exists()) {
    stderr.writeln('Missing file: ${enPath.path}');
    exitCode = 1;
    return;
  }
  if (!await faPath.exists()) {
    stderr.writeln('Missing file: ${faPath.path}');
    exitCode = 1;
    return;
  }

  final enJson = jsonDecode(await enPath.readAsString());
  final faJson = jsonDecode(await faPath.readAsString());

  // Create a simple backup before writing changes
  final backupFile = File('${translationsDir.path}/fa.i18n.json.bak');
  await backupFile.writeAsString(await faPath.readAsString());

  final merged = _merge(enJson, faJson, placeholdersEmpty: placeholdersEmpty);

  const encoder = JsonEncoder.withIndent('  ');
  await faPath.writeAsString('${encoder.convert(merged)}\n');
  stdout.writeln(
    '✅ fa.i18n.json synced. Backup: ${backupFile.path}. Placeholder mode: ${placeholdersEmpty ? 'empty' : 'english'}',
  );
}

/// Recursively merges [en] into [fa], preserving existing FA values and
/// adding any missing keys from EN with EN values as placeholders.
dynamic _merge(dynamic en, dynamic fa, {required bool placeholdersEmpty}) {
  if (en is Map<String, dynamic> && fa is Map<String, dynamic>) {
    final result = <String, dynamic>{};
    // Keep English order; fill from FA when available.
    for (final String key in en.keys) {
      final enVal = en[key];
      final hasFa = fa.containsKey(key);
      final faVal = hasFa ? fa[key] : null;
      result[key] = _merge(
        enVal,
        hasFa ? faVal : enVal,
        placeholdersEmpty: placeholdersEmpty,
      );
    }
    // Preserve extra FA-only keys if any exist
    for (final String key in fa.keys) {
      result.putIfAbsent(key, () => fa[key]);
    }
    return result;
  }
  if (en is List && fa is List) {
    final length = en.length > fa.length ? en.length : fa.length;
    return List.generate(
      length,
      (i) => _merge(
        i < en.length ? en[i] : null,
        i < fa.length ? fa[i] : null,
        placeholdersEmpty: placeholdersEmpty,
      ),
    );
  }
  // For primitives or mismatched structures: prefer FA when present; otherwise use EN.
  if (fa != null) return fa;
  if (placeholdersEmpty && (en is String || en == null)) return '';
  return en;
}
