import 'package:hiddify/features/config/model/config.dart';

enum ImportIssueLevel { info, warning, error }

class ImportIssue {
  const ImportIssue({required this.level, required this.message});

  final ImportIssueLevel level;
  final String message;
}

class ImportItem {
  const ImportItem({
    required this.config,
    this.warnings = const <ImportIssue>[],
  });

  final Config config;
  final List<ImportIssue> warnings;
}

class ImportFailure {
  const ImportFailure({required this.raw, required this.issue});

  final String raw;
  final ImportIssue issue;
}

class ConfigImportResult {
  const ConfigImportResult({
    required this.items,
    required this.failures,
    required this.remainingText,
  });

  final List<ImportItem> items;
  final List<ImportFailure> failures;
  final String remainingText;

  bool get hasErrors => failures.isNotEmpty;
}
