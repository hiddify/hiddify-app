import 'dart:convert';

/// Config validation and warning system
/// Identifies sensitive settings that may break connections
class ConfigValidator {
  /// Settings that are critical and should not be modified
  static const List<String> criticalSettings = [
    'address',
    'server',
    'port',
    'uuid',
    'id',
    'password',
    'publicKey',
    'privateKey',
  ];

  /// Settings that may affect connection but are safer to modify
  static const List<String> sensitiveSettings = [
    'sni',
    'serverName',
    'host',
    'path',
    'serviceName',
    'flow',
    'encryption',
    'security',
  ];

  /// Settings that are safe to modify
  static const List<String> safeSettings = [
    'fingerprint',
    'alpn',
    'allowInsecure',
    'network',
    'type',
    'mode',
    'headerType',
    '_remark',
    'ps',
    'tag',
  ];

  /// Check if a setting is critical (will break connection if changed)
  static bool isCritical(String key) => criticalSettings.contains(key);

  /// Check if a setting is sensitive (may affect connection)
  static bool isSensitive(String key) => sensitiveSettings.contains(key);

  /// Check if a setting is safe to modify
  static bool isSafe(String key) => safeSettings.contains(key);

  /// Get warning level for a setting
  static WarningLevel getWarningLevel(String key) {
    if (isCritical(key)) return WarningLevel.critical;
    if (isSensitive(key)) return WarningLevel.warning;
    return WarningLevel.safe;
  }

  /// Validate a config and return list of issues
  static List<ValidationIssue> validate(String configContent) {
    final issues = <ValidationIssue>[];

    try {
      if (configContent.trim().startsWith('{')) {
        final config = jsonDecode(configContent) as Map<String, dynamic>;
        _validateJson(config, issues);
      } else {
        _validateUri(configContent, issues);
      }
    } catch (e) {
      issues.add(ValidationIssue(
        type: IssueType.error,
        message: 'Invalid config format: $e',
        field: null,
      ));
    }

    return issues;
  }

  static void _validateJson(Map<String, dynamic> config, List<ValidationIssue> issues) {
    // Check for required fields
    if (!config.containsKey('protocol') && !config.containsKey('_protocol')) {
      issues.add(const ValidationIssue(
        type: IssueType.warning,
        message: 'Missing protocol field',
        field: 'protocol',
      ));
    }

    // Check outbounds
    if (config.containsKey('outbounds')) {
      final outbounds = config['outbounds'] as List?;
      if (outbounds == null || outbounds.isEmpty) {
        issues.add(const ValidationIssue(
          type: IssueType.error,
          message: 'No outbounds defined',
          field: 'outbounds',
        ));
      }
    }

    // Check for insecure settings
    if (config['allowInsecure'] == true) {
      issues.add(const ValidationIssue(
        type: IssueType.warning,
        message: 'Allow insecure is enabled - connection may be vulnerable',
        field: 'allowInsecure',
      ));
    }

    // Check TLS settings
    final streamSettings = config['streamSettings'] as Map<String, dynamic>?;
    if (streamSettings != null) {
      final security = streamSettings['security'] as String?;
      if (security == 'none') {
        issues.add(const ValidationIssue(
          type: IssueType.warning,
          message: 'No TLS security - traffic is not encrypted',
          field: 'security',
        ));
      }
    }
  }

  static void _validateUri(String uri, List<ValidationIssue> issues) {
    // Check protocol prefix
    final supportedPrefixes = [
      'vless://',
      'vmess://',
      'trojan://',
      'ss://',
      'ssr://',
      'hy2://',
      'hysteria2://',
      'hysteria://',
      'tuic://',
      'wg://',
      'wireguard://',
    ];

    final hasValidPrefix = supportedPrefixes.any((p) => uri.startsWith(p));
    if (!hasValidPrefix) {
      issues.add(const ValidationIssue(
        type: IssueType.error,
        message: 'Unknown protocol prefix',
        field: 'protocol',
      ));
    }

    // Check for @ symbol (user info separator)
    if (!uri.contains('@')) {
      issues.add(const ValidationIssue(
        type: IssueType.warning,
        message: 'Missing server address separator (@)',
        field: 'address',
      ));
    }
  }

  /// Compare two configs and find changes
  static List<ConfigChange> compareConfigs(
    Map<String, dynamic> original,
    Map<String, dynamic> modified,
  ) {
    final changes = <ConfigChange>[];

    // Find modified and added fields
    for (final entry in modified.entries) {
      if (!original.containsKey(entry.key)) {
        changes.add(ConfigChange(
          field: entry.key,
          type: ChangeType.added,
          oldValue: null,
          newValue: entry.value,
          warningLevel: getWarningLevel(entry.key),
        ));
      } else if (original[entry.key] != entry.value) {
        changes.add(ConfigChange(
          field: entry.key,
          type: ChangeType.modified,
          oldValue: original[entry.key],
          newValue: entry.value,
          warningLevel: getWarningLevel(entry.key),
        ));
      }
    }

    // Find removed fields
    for (final key in original.keys) {
      if (!modified.containsKey(key)) {
        changes.add(ConfigChange(
          field: key,
          type: ChangeType.removed,
          oldValue: original[key],
          newValue: null,
          warningLevel: getWarningLevel(key),
        ));
      }
    }

    return changes;
  }

  /// Check if changes are safe to apply
  static bool areChangesSafe(List<ConfigChange> changes) {
    return !changes.any((c) => c.warningLevel == WarningLevel.critical);
  }

  /// Get summary of changes
  static String getChangesSummary(List<ConfigChange> changes) {
    final critical = changes.where((c) => c.warningLevel == WarningLevel.critical).length;
    final warnings = changes.where((c) => c.warningLevel == WarningLevel.warning).length;
    final safe = changes.where((c) => c.warningLevel == WarningLevel.safe).length;

    return '$critical critical, $warnings warnings, $safe safe changes';
  }
}

/// Warning level for config settings
enum WarningLevel {
  critical('Critical', 'Will break connection'),
  warning('Warning', 'May affect connection'),
  safe('Safe', 'Safe to modify');

  const WarningLevel(this.label, this.description);
  final String label;
  final String description;
}

/// Type of validation issue
enum IssueType { error, warning, info }

/// Validation issue
class ValidationIssue {
  const ValidationIssue({
    required this.type,
    required this.message,
    required this.field,
  });

  final IssueType type;
  final String message;
  final String? field;
}

/// Type of config change
enum ChangeType { added, modified, removed }

/// Config change with warning level
class ConfigChange {
  const ConfigChange({
    required this.field,
    required this.type,
    required this.oldValue,
    required this.newValue,
    required this.warningLevel,
  });

  final String field;
  final ChangeType type;
  final dynamic oldValue;
  final dynamic newValue;
  final WarningLevel warningLevel;
}
