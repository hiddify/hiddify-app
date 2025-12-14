import 'dart:convert';

import 'package:hiddify/features/config/logic/config_extractor.dart';
import 'package:hiddify/features/config/logic/config_import_result.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

class ConfigImportService {
  static const _uuid = Uuid();

  static ConfigImportResult importContent(
    String content, {
    required String source,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return const ConfigImportResult(
        items: <ImportItem>[],
        failures: <ImportFailure>[],
        remainingText: '',
      );
    }

    final maybeDecoded = _decodeBase64IfLooksLikeSubscription(trimmed);

    final jsonResult = _tryImportJson(maybeDecoded, source: source);
    if (jsonResult != null) return jsonResult;

    final yamlResult = _tryImportClashYaml(maybeDecoded, source: source);
    if (yamlResult != null) return yamlResult;

    return _importFromText(maybeDecoded, source: source);
  }

  static ConfigImportResult _importFromText(
    String text, {
    required String source,
  }) {
    final separation = ConfigExtractor.separateConfigsFromText(
      text,
      source: source,
    );

    final unique = _deduplicateByContent(separation.configs);

    final items = <ImportItem>[];
    final failures = <ImportFailure>[];

    for (final config in unique) {
      final lower = config.content.trimLeft().toLowerCase();
      if (lower.startsWith('ssr://')) {
        failures.add(
          ImportFailure(
            raw: config.content,
            issue: const ImportIssue(
              level: ImportIssueLevel.error,
              message: 'ShadowsocksR (ssr://) is not supported yet',
            ),
          ),
        );
        continue;
      }

      if (lower.startsWith('naive+https://')) {
        failures.add(
          ImportFailure(
            raw: config.content,
            issue: const ImportIssue(
              level: ImportIssueLevel.error,
              message: 'Naive (naive+https://) is not supported yet',
            ),
          ),
        );
        continue;
      }

      if (lower.startsWith('tuic://')) {
        failures.add(
          ImportFailure(
            raw: config.content,
            issue: const ImportIssue(
              level: ImportIssueLevel.error,
              message: 'TUIC (tuic://) is recognized but connection is not supported yet',
            ),
          ),
        );
        continue;
      }

      items.add(ImportItem(config: config));
    }

    return ConfigImportResult(
      items: items,
      failures: failures,
      remainingText: separation.remainingText,
    );
  }

  static List<Config> _deduplicateByContent(List<Config> configs) {
    final seen = <String>{};
    final result = <Config>[];

    for (final config in configs) {
      if (seen.add(config.content)) {
        result.add(config);
      }
    }

    return result;
  }

  static String _decodeBase64IfLooksLikeSubscription(String input) {
    final compact = input.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 48) return input;

    final base64Regex = RegExp(r'^[A-Za-z0-9+/=_-]+$');
    if (!base64Regex.hasMatch(compact)) return input;

    final decoded = _tryDecodeBase64(compact);
    if (decoded == null) return input;

    final looksLikeList = decoded.contains('://');
    final looksLikeClash = decoded.contains('proxies:') || decoded.contains('proxy-groups:');
    final looksLikeJson = decoded.trimLeft().startsWith('{') || decoded.trimLeft().startsWith('[');

    if (looksLikeList || looksLikeClash || looksLikeJson) {
      return decoded;
    }

    return input;
  }

  static String? _tryDecodeBase64(String compact) {
    try {
      final normalized = base64.normalize(compact);
      return utf8.decode(base64Decode(normalized));
    } catch (_) {
      try {
        final normalized = base64Url.normalize(compact);
        return utf8.decode(base64Url.decode(normalized));
      } catch (_) {
        return null;
      }
    }
  }

  static ConfigImportResult? _tryImportJson(
    String content, {
    required String source,
  }) {
    final trimmed = content.trimLeft();
    if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) return null;

    try {
      final decoded = jsonDecode(trimmed);

      if (decoded is List) {
        return _importJsonList(decoded.cast<Object?>(), source: source);
      }

      if (decoded is Map) {
        return _importJsonMap(decoded.cast<Object?, Object?>(), source: source);
      }

      return null;
    } catch (e) {
      return ConfigImportResult(
        items: const <ImportItem>[],
        failures: [
          ImportFailure(
            raw: 'json',
            issue: ImportIssue(
              level: ImportIssueLevel.error,
              message: 'Invalid JSON: $e',
            ),
          ),
        ],
        remainingText: '',
      );
    }
  }

  static ConfigImportResult _importJsonList(
    List<Object?> list, {
    required String source,
  }) {
    final items = <ImportItem>[];
    final failures = <ImportFailure>[];

    for (final entry in list) {
      if (entry is String) {
        final embedded = importContent(entry, source: source);
        items.addAll(embedded.items);
        failures.addAll(embedded.failures);
        continue;
      }

      failures.add(
        ImportFailure(
          raw: entry?.toString() ?? 'null',
          issue: const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'Unsupported JSON list entry (expected string)',
          ),
        ),
      );
    }

    return ConfigImportResult(
      items: items,
      failures: failures,
      remainingText: '',
    );
  }

  static ConfigImportResult _importJsonMap(
    Map<Object?, Object?> map, {
    required String source,
  }) {
    final root = _stringObjectMap(map);

    final outboundsValue = root['outbounds'];
    final outbounds = _asList(outboundsValue);

    if (outbounds != null && outbounds.isNotEmpty) {
      final singBoxLike = outbounds
          .map(_asMap)
          .whereType<Map<String, Object?>>()
          .any((o) => o.containsKey('type'));

      if (singBoxLike) {
        return _importSingBoxOutbounds(outbounds, source: source);
      }

      final xrayLike = outbounds
          .map(_asMap)
          .whereType<Map<String, Object?>>()
          .any((o) => o.containsKey('protocol'));

      if (xrayLike) {
        final config = Config(
          id: _uuid.v4(),
          name: 'Imported JSON',
          content: jsonEncode(root),
          type: 'json',
          source: source,
          addedAt: DateTime.now(),
        );
        return ConfigImportResult(
          items: [ImportItem(config: config)],
          failures: const <ImportFailure>[],
          remainingText: '',
        );
      }
    }

    final config = Config(
      id: _uuid.v4(),
      name: 'Imported JSON',
      content: jsonEncode(root),
      type: 'json',
      source: source,
      addedAt: DateTime.now(),
    );

    return ConfigImportResult(
      items: [ImportItem(config: config)],
      failures: const <ImportFailure>[],
      remainingText: '',
    );
  }

  static ConfigImportResult _importSingBoxOutbounds(
    List<Object?> outbounds, {
    required String source,
  }) {
    final items = <ImportItem>[];
    final failures = <ImportFailure>[];

    for (final node in outbounds) {
      final outbound = _asMap(node);
      if (outbound == null) {
        failures.add(
          ImportFailure(
            raw: node?.toString() ?? 'null',
            issue: const ImportIssue(
              level: ImportIssueLevel.warning,
              message: 'Invalid outbound entry (expected object)',
            ),
          ),
        );
        continue;
      }

      final type = _asString(outbound['type']);
      if (type == null) continue;

      if (type == 'direct' ||
          type == 'block' ||
          type == 'dns' ||
          type == 'selector' ||
          type == 'urltest') {
        continue;
      }

      final tag = _asString(outbound['tag']) ?? 'sing-box';

      final warnings = <ImportIssue>[];
      final uri = _singBoxOutboundToUri(outbound, type: type, name: tag, warnings: warnings);

      if (uri == null) {
        late final ImportIssue issue;
        if (type == 'tuic') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'TUIC (type: tuic) is recognized but connection is not supported yet',
          );
        } else if (type == 'naive') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'Naive (type: naive) is not supported yet',
          );
        } else if (type == 'ssr' || type == 'shadowsocksr') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'ShadowsocksR (type: ssr) is not supported yet',
          );
        } else {
          issue = ImportIssue(
            level: ImportIssueLevel.error,
            message: 'Unsupported or incomplete sing-box outbound: $type',
          );
        }

        failures.add(
          ImportFailure(
            raw: tag,
            issue: issue,
          ),
        );
        continue;
      }

      final config = Config(
        id: _uuid.v4(),
        name: tag,
        content: uri,
        type: ConfigExtractor.detectProtocol(uri),
        source: source,
        addedAt: DateTime.now(),
      );

      items.add(ImportItem(config: config, warnings: warnings));
    }

    return ConfigImportResult(
      items: items,
      failures: failures,
      remainingText: '',
    );
  }

  static String? _singBoxOutboundToUri(
    Map<String, Object?> outbound, {
    required String type,
    required String name,
    required List<ImportIssue> warnings,
  }) {
    switch (type) {
      case 'vless':
        return _singBoxVlessToUri(outbound, name: name, warnings: warnings);
      case 'vmess':
        return _singBoxVmessToUri(outbound, name: name, warnings: warnings);
      case 'trojan':
        return _singBoxTrojanToUri(outbound, name: name, warnings: warnings);
      case 'shadowsocks':
        return _singBoxShadowsocksToUri(outbound, name: name);
      case 'hysteria2':
        return _singBoxHysteria2ToUri(outbound, name: name, warnings: warnings);
      case 'hysteria':
        return _singBoxHysteria2ToUri(outbound, name: name, warnings: warnings);
      case 'wireguard':
        return _singBoxWireguardToUri(outbound, name: name, warnings: warnings);
      default:
        return null;
    }
  }

  static String? _singBoxVlessToUri(
    Map<String, Object?> outbound, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(outbound['server']);
    final port = _asInt(outbound['server_port']);
    final uuid = _asString(outbound['uuid']);

    if (server == null || port == null || uuid == null) return null;

    final params = <String, String>{
      'encryption': 'none',
    };

    final flow = _asString(outbound['flow']);
    if (flow != null && flow.isNotEmpty) params['flow'] = flow;

    final tls = _asMap(outbound['tls']);
    final transport = _asMap(outbound['transport']);

    final transportType = _asString(transport?['type']);
    if (transportType != null && transportType.isNotEmpty) {
      params['type'] = transportType;
    }

    if (transportType == 'ws') {
      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final headers = _asMap(transport?['headers']);
      final host = _asString(headers?['Host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (transportType == 'grpc') {
      final serviceName = _asString(transport?['service_name']);
      if (serviceName != null && serviceName.isNotEmpty) {
        params['serviceName'] = serviceName;
      }

      final multiMode = (_asBool(transport?['multi_mode']) ?? _asBool(transport?['multiMode'])) ?? false;
      if (multiMode) params['mode'] = 'multi';
    }

    if (transportType == 'http' || transportType == 'h2') {
      final hostList = _asList(transport?['host']);
      if (hostList != null) {
        final values = hostList.whereType<String>().toList();
        if (values.isNotEmpty) {
          params['host'] = values.first;
          if (values.length > 1) {
            warnings.add(
              const ImportIssue(
                level: ImportIssueLevel.warning,
                message: 'Multiple HTTP hosts found in sing-box transport; using the first host',
              ),
            );
          }
        }
      }

      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final method = _asString(transport?['method']);
      if (method != null && method.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport method is not supported in URI import and will be ignored',
          ),
        );
      }

      final headers = _asMap(transport?['headers']);
      if (headers != null && headers.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport headers are not supported in URI import and will be ignored',
          ),
        );
      }
    }

    if (transportType == 'httpupgrade') {
      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final host = _asString(transport?['host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (tls != null) {
      final enabled = _asBool(tls['enabled']) ?? false;
      if (enabled) {
        final reality = _asMap(tls['reality']);
        final realityEnabled = _asBool(reality?['enabled']) ?? false;

        if (realityEnabled) {
          params['security'] = 'reality';
          final pbk = _asString(reality?['public_key']);
          final sid = _asString(reality?['short_id']);
          final spx = _asString(reality?['spider_x']) ?? _asString(reality?['spider-x']);
          if (pbk != null && pbk.isNotEmpty) params['pbk'] = pbk;
          if (sid != null && sid.isNotEmpty) params['sid'] = sid;
          if (spx != null && spx.isNotEmpty) params['spx'] = spx;
        } else {
          params['security'] = 'tls';
        }

        final sni = _asString(tls['server_name']);
        if (sni != null && sni.isNotEmpty) {
          params['sni'] = sni;
        }

        final alpn = _asList(tls['alpn']);
        if (alpn != null) {
          final values = alpn.whereType<String>().toList();
          if (values.isNotEmpty) params['alpn'] = values.join(',');
        }

        final utls = _asMap(tls['utls']);
        final fp = _asString(utls?['fingerprint']);
        if (fp != null && fp.isNotEmpty) params['fp'] = fp;

        final insecure = _asBool(tls['insecure']) ?? false;
        if (insecure) {
          warnings.add(
            const ImportIssue(
              level: ImportIssueLevel.warning,
              message: 'TLS insecure requested in sing-box but will be controlled by app TLS settings',
            ),
          );
        }
      }
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'vless://$uuid@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static String? _singBoxVmessToUri(
    Map<String, Object?> outbound, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(outbound['server']);
    final port = _asInt(outbound['server_port']);
    final uuid = _asString(outbound['uuid']);

    if (server == null || port == null || uuid == null) return null;

    final alterId = _asInt(outbound['alter_id']) ?? 0;
    final security = _asString(outbound['security']) ?? 'auto';

    final tls = _asMap(outbound['tls']);
    final transport = _asMap(outbound['transport']);
    final transportType = _asString(transport?['type']) ?? 'tcp';

    final vmess = <String, dynamic>{
      'v': '2',
      'ps': name,
      'add': server,
      'port': port.toString(),
      'id': uuid,
      'aid': alterId.toString(),
      'scy': security,
      'net': transportType,
      'type': 'none',
      'host': '',
      'path': '',
      'tls': '',
      'sni': '',
      'alpn': '',
      'fp': 'chrome',
    };

    if (transportType == 'ws') {
      final path = _asString(transport?['path']);
      if (path != null) vmess['path'] = path;

      final headers = _asMap(transport?['headers']);
      final host = _asString(headers?['Host']);
      if (host != null) vmess['host'] = host;
    }

    if (transportType == 'grpc') {
      final serviceName = _asString(transport?['service_name']);
      if (serviceName != null) vmess['path'] = serviceName;
    }

    if (transportType == 'http' || transportType == 'h2') {
      final hostList = _asList(transport?['host']);
      if (hostList != null) {
        final values = hostList.whereType<String>().toList();
        if (values.isNotEmpty) {
          vmess['host'] = values.first;
          if (values.length > 1) {
            warnings.add(
              const ImportIssue(
                level: ImportIssueLevel.warning,
                message: 'Multiple HTTP hosts found in sing-box transport; using the first host',
              ),
            );
          }
        }
      }

      final path = _asString(transport?['path']);
      if (path != null) vmess['path'] = path;

      final method = _asString(transport?['method']);
      if (method != null && method.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport method is not supported in URI import and will be ignored',
          ),
        );
      }

      final headers = _asMap(transport?['headers']);
      if (headers != null && headers.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport headers are not supported in URI import and will be ignored',
          ),
        );
      }
    }

    if (transportType == 'httpupgrade') {
      final host = _asString(transport?['host']);
      if (host != null) vmess['host'] = host;

      final path = _asString(transport?['path']);
      if (path != null) vmess['path'] = path;
    }

    if (tls != null) {
      final enabled = _asBool(tls['enabled']) ?? false;
      if (enabled) {
        vmess['tls'] = 'tls';

        final sni = _asString(tls['server_name']);
        if (sni != null) vmess['sni'] = sni;

        final alpn = _asList(tls['alpn']);
        if (alpn != null) {
          final values = alpn.whereType<String>().toList();
          if (values.isNotEmpty) vmess['alpn'] = values.join(',');
        }

        final utls = _asMap(tls['utls']);
        final fp = _asString(utls?['fingerprint']);
        if (fp != null) vmess['fp'] = fp;

        final insecure = _asBool(tls['insecure']) ?? false;
        if (insecure) {
          warnings.add(
            const ImportIssue(
              level: ImportIssueLevel.warning,
              message: 'TLS insecure requested in sing-box but will be controlled by app TLS settings',
            ),
          );
        }
      }
    }

    final jsonStr = jsonEncode(vmess);
    final base64Str = base64.encode(utf8.encode(jsonStr));
    return 'vmess://$base64Str';
  }

  static String? _singBoxTrojanToUri(
    Map<String, Object?> outbound, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(outbound['server']);
    final port = _asInt(outbound['server_port']);
    final password = _asString(outbound['password']);

    if (server == null || port == null || password == null) return null;

    final params = <String, String>{
      'security': 'tls',
    };

    final tls = _asMap(outbound['tls']);
    final transport = _asMap(outbound['transport']);

    final transportType = _asString(transport?['type']);
    if (transportType != null && transportType.isNotEmpty) {
      params['type'] = transportType;
    }

    if (transportType == 'ws') {
      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final headers = _asMap(transport?['headers']);
      final host = _asString(headers?['Host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (transportType == 'grpc') {
      final serviceName = _asString(transport?['service_name']);
      if (serviceName != null && serviceName.isNotEmpty) {
        params['serviceName'] = serviceName;
      }

      final multiMode = (_asBool(transport?['multi_mode']) ?? _asBool(transport?['multiMode'])) ?? false;
      if (multiMode) params['mode'] = 'multi';
    }

    if (transportType == 'http' || transportType == 'h2') {
      final hostList = _asList(transport?['host']);
      if (hostList != null) {
        final values = hostList.whereType<String>().toList();
        if (values.isNotEmpty) {
          params['host'] = values.first;
          if (values.length > 1) {
            warnings.add(
              const ImportIssue(
                level: ImportIssueLevel.warning,
                message: 'Multiple HTTP hosts found in sing-box transport; using the first host',
              ),
            );
          }
        }
      }

      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final method = _asString(transport?['method']);
      if (method != null && method.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport method is not supported in URI import and will be ignored',
          ),
        );
      }

      final headers = _asMap(transport?['headers']);
      if (headers != null && headers.isNotEmpty) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'HTTP transport headers are not supported in URI import and will be ignored',
          ),
        );
      }
    }

    if (transportType == 'httpupgrade') {
      final path = _asString(transport?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final host = _asString(transport?['host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (tls != null) {
      final enabled = _asBool(tls['enabled']) ?? false;
      if (enabled) {
        final reality = _asMap(tls['reality']);
        final realityEnabled = _asBool(reality?['enabled']) ?? false;

        if (realityEnabled) {
          params['security'] = 'reality';
          final pbk = _asString(reality?['public_key']);
          final sid = _asString(reality?['short_id']);
          final spx = _asString(reality?['spider_x']) ?? _asString(reality?['spider-x']);
          if (pbk != null && pbk.isNotEmpty) params['pbk'] = pbk;
          if (sid != null && sid.isNotEmpty) params['sid'] = sid;
          if (spx != null && spx.isNotEmpty) params['spx'] = spx;
        } else {
          params['security'] = 'tls';
        }

        final sni = _asString(tls['server_name']);
        if (sni != null && sni.isNotEmpty) params['sni'] = sni;

        final alpn = _asList(tls['alpn']);
        if (alpn != null) {
          final values = alpn.whereType<String>().toList();
          if (values.isNotEmpty) params['alpn'] = values.join(',');
        }

        final utls = _asMap(tls['utls']);
        final fp = _asString(utls?['fingerprint']);
        if (fp != null && fp.isNotEmpty) params['fp'] = fp;

        final insecure = _asBool(tls['insecure']) ?? false;
        if (insecure) {
          warnings.add(
            const ImportIssue(
              level: ImportIssueLevel.warning,
              message: 'TLS insecure requested in sing-box but will be controlled by app TLS settings',
            ),
          );
        }
      }
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'trojan://$password@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static String? _singBoxShadowsocksToUri(
    Map<String, Object?> outbound, {
    required String name,
  }) {
    final server = _asString(outbound['server']);
    final port = _asInt(outbound['server_port']);
    final method = _asString(outbound['method']);
    final password = _asString(outbound['password']);

    if (server == null || port == null || method == null || password == null) {
      return null;
    }

    final userInfo = base64.encode(utf8.encode('$method:$password'));
    return 'ss://$userInfo@${_formatHostForUri(server)}:$port#${Uri.encodeComponent(name)}';
  }

  static String? _singBoxHysteria2ToUri(
    Map<String, Object?> outbound, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(outbound['server']);
    final port = _asInt(outbound['server_port']);
    final auth = _asString(outbound['password']) ??
        _asString(outbound['auth']) ??
        _asString(outbound['auth_str']) ??
        _asString(outbound['auth-str']);

    if (server == null || port == null || auth == null) return null;

    final params = <String, String>{};

    final tls = _asMap(outbound['tls']);
    if (tls != null) {
      final sni = _asString(tls['server_name']);
      if (sni != null && sni.isNotEmpty) params['sni'] = sni;

      final alpn = _asList(tls['alpn']);
      if (alpn != null) {
        final values = alpn.whereType<String>().toList();
        if (values.isNotEmpty) params['alpn'] = values.join(',');
      }

      final insecure = _asBool(tls['insecure']) ?? false;
      if (insecure) {
        params['insecure'] = '1';
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'TLS insecure requested in sing-box but will be controlled by app TLS settings',
          ),
        );
      }
    }

    final upMbps = _asIntLoose(outbound['up_mbps']) ?? _asIntLoose(outbound['up']);
    if (upMbps != null) params['up'] = upMbps.toString();

    final downMbps = _asIntLoose(outbound['down_mbps']) ?? _asIntLoose(outbound['down']);
    if (downMbps != null) params['down'] = downMbps.toString();

    final obfs = _asMap(outbound['obfs']);
    final obfsType = _asString(obfs?['type']);
    if (obfsType != null && obfsType.isNotEmpty) params['obfs'] = obfsType;

    final obfsPassword = _asString(obfs?['password']);
    if (obfsPassword != null && obfsPassword.isNotEmpty) {
      params['obfs-password'] = obfsPassword;
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final queryPart = query.isEmpty ? '' : '?$query';

    return 'hy2://${Uri.encodeComponent(auth)}@${_formatHostForUri(server)}:$port$queryPart#${Uri.encodeComponent(name)}';
  }

  static String? _singBoxWireguardToUri(
    Map<String, Object?> outbound, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final privateKey = _asString(outbound['private_key']);
    if (privateKey == null) return null;

    final peers = _asList(outbound['peers']);
    Map<String, Object?>? primaryPeer;
    if (peers != null && peers.isNotEmpty) {
      primaryPeer = _asMap(peers.first);
      if (peers.length > 1) {
        warnings.add(
          const ImportIssue(
            level: ImportIssueLevel.warning,
            message: 'Multiple WireGuard peers found in sing-box outbound; using the first peer',
          ),
        );
      }
    }

    final server = _asString(primaryPeer?['server']) ?? _asString(outbound['server']);
    final port = _asInt(primaryPeer?['server_port']) ?? _asInt(outbound['server_port']);
    if (server == null || port == null) return null;

    final publicKey = _asString(outbound['peer_public_key']) ??
        _asString(primaryPeer?['public_key']) ??
        _asString(outbound['public_key']);
    if (publicKey == null) return null;

    final preSharedKey = _asString(outbound['pre_shared_key']) ?? _asString(primaryPeer?['pre_shared_key']);
    if (preSharedKey != null && preSharedKey.isNotEmpty) {
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'WireGuard pre_shared_key exists in sing-box config but is not supported in URI import yet',
        ),
      );
    }

    final params = <String, String>{
      'publicKey': publicKey,
    };

    final localAddressRaw = outbound['local_address'];
    if (localAddressRaw is String && localAddressRaw.isNotEmpty) {
      params['address'] = localAddressRaw;
    } else {
      final localAddress = _asList(localAddressRaw);
      if (localAddress != null) {
        final values = localAddress.whereType<String>().toList();
        if (values.isNotEmpty) params['address'] = values.join(',');
      }
    }

    final mtu = _asInt(outbound['mtu']);
    if (mtu != null) params['mtu'] = mtu.toString();

    final reservedRaw = outbound['reserved'] ?? primaryPeer?['reserved'];
    if (reservedRaw is String && reservedRaw.isNotEmpty) {
      params['reserved'] = reservedRaw;
    } else {
      final reservedList = _asList(reservedRaw);
      if (reservedList != null) {
        final values = reservedList.map(_asInt).whereType<int>().toList();
        if (values.isNotEmpty) params['reserved'] = values.join(',');
      }
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'wg://${Uri.encodeComponent(privateKey)}@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static ConfigImportResult? _tryImportClashYaml(
    String content, {
    required String source,
  }) {
    final trimmed = content.trimLeft();

    if (!(trimmed.contains('proxies:') && trimmed.contains('port:'))) {
      return null;
    }

    try {
      final yaml = loadYaml(trimmed);
      final dart = _yamlToDart(yaml);

      if (dart is! Map<String, Object?>) return null;

      final proxies = _asList(dart['proxies']);
      if (proxies == null) return null;

      return _importClashProxies(proxies, source: source);
    } catch (_) {
      return null;
    }
  }

  static ConfigImportResult _importClashProxies(
    List<Object?> proxies, {
    required String source,
  }) {
    final items = <ImportItem>[];
    final failures = <ImportFailure>[];

    for (final node in proxies) {
      final proxy = _asMap(node);
      if (proxy == null) {
        failures.add(
          ImportFailure(
            raw: node?.toString() ?? 'null',
            issue: const ImportIssue(
              level: ImportIssueLevel.error,
              message: 'Invalid proxy entry (expected object)',
            ),
          ),
        );
        continue;
      }

      final type = _asString(proxy['type']);
      final name = _asString(proxy['name']) ?? 'Clash Proxy';

      if (type == null) {
        failures.add(
          ImportFailure(
            raw: name,
            issue: const ImportIssue(
              level: ImportIssueLevel.error,
              message: 'Missing proxy type',
            ),
          ),
        );
        continue;
      }

      final warnings = <ImportIssue>[];
      final uri = _clashProxyToUri(proxy, type: type, name: name, warnings: warnings);

      if (uri == null) {
        late final ImportIssue issue;
        if (type == 'tuic') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'TUIC (type: tuic) is recognized but connection is not supported yet',
          );
        } else if (type == 'ssr') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'ShadowsocksR (type: ssr) is not supported yet',
          );
        } else if (type == 'naive') {
          issue = const ImportIssue(
            level: ImportIssueLevel.error,
            message: 'Naive (type: naive) is not supported yet',
          );
        } else {
          issue = ImportIssue(
            level: ImportIssueLevel.error,
            message: 'Unsupported or incomplete Clash proxy: $type',
          );
        }

        failures.add(
          ImportFailure(
            raw: name,
            issue: issue,
          ),
        );
        continue;
      }

      final config = Config(
        id: _uuid.v4(),
        name: name,
        content: uri,
        type: ConfigExtractor.detectProtocol(uri),
        source: source,
        addedAt: DateTime.now(),
      );

      items.add(ImportItem(config: config, warnings: warnings));
    }

    return ConfigImportResult(
      items: items,
      failures: failures,
      remainingText: '',
    );
  }

  static String? _clashProxyToUri(
    Map<String, Object?> proxy, {
    required String type,
    required String name,
    required List<ImportIssue> warnings,
  }) {
    switch (type) {
      case 'vless':
        return _clashVlessToUri(proxy, name: name, warnings: warnings);
      case 'vmess':
        return _clashVmessToUri(proxy, name: name, warnings: warnings);
      case 'trojan':
        return _clashTrojanToUri(proxy, name: name, warnings: warnings);
      case 'ss':
        return _clashShadowsocksToUri(proxy, name: name);
      case 'hysteria2':
        return _clashHysteria2ToUri(proxy, name: name, warnings: warnings);
      case 'hysteria':
        return _clashHysteria2ToUri(proxy, name: name, warnings: warnings);
      case 'wireguard':
        return _clashWireguardToUri(proxy, name: name, warnings: warnings);
      default:
        return null;
    }
  }

  static String? _clashVlessToUri(
    Map<String, Object?> proxy, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final uuid = _asString(proxy['uuid']);

    if (server == null || port == null || uuid == null) return null;

    final params = <String, String>{
      'encryption': _asString(proxy['encryption']) ?? 'none',
    };

    final flow = _asString(proxy['flow']);
    if (flow != null && flow.isNotEmpty) params['flow'] = flow;

    final network = _asString(proxy['network']) ?? 'tcp';
    params['type'] = network;

    final tlsEnabled = _asBool(proxy['tls']) ?? false;

    final realityOpts = _asMap(proxy['reality-opts']);
    if (realityOpts != null) {
      params['security'] = 'reality';

      final pbk = _asString(realityOpts['public-key']);
      final sid = _asString(realityOpts['short-id']);
      final spx = _asString(realityOpts['spider-x']);

      if (pbk != null && pbk.isNotEmpty) params['pbk'] = pbk;
      if (sid != null && sid.isNotEmpty) params['sid'] = sid;
      if (spx != null && spx.isNotEmpty) params['spx'] = spx;

      final serverName = _asString(proxy['servername']) ?? _asString(proxy['sni']);
      if (serverName != null && serverName.isNotEmpty) params['sni'] = serverName;
    } else if (tlsEnabled) {
      params['security'] = 'tls';

      final serverName = _asString(proxy['servername']) ?? _asString(proxy['sni']);
      if (serverName != null && serverName.isNotEmpty) params['sni'] = serverName;

      final fp = _asString(proxy['client-fingerprint']);
      if (fp != null && fp.isNotEmpty) params['fp'] = fp;

      final alpn = _asList(proxy['alpn']);
      if (alpn != null) {
        final values = alpn.whereType<String>().toList();
        if (values.isNotEmpty) params['alpn'] = values.join(',');
      }
    }

    if (network == 'ws') {
      final wsOpts = _asMap(proxy['ws-opts']);
      final path = _asString(wsOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final headers = _asMap(wsOpts?['headers']);
      final host = _asString(headers?['Host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (network == 'grpc') {
      final grpcOpts = _asMap(proxy['grpc-opts']);
      final serviceName = _asString(grpcOpts?['grpc-service-name']);
      if (serviceName != null && serviceName.isNotEmpty) {
        params['serviceName'] = serviceName;
      }

      final mode = _asString(grpcOpts?['grpc-mode']) ??
          _asString(grpcOpts?['grpcMode']) ??
          _asString(grpcOpts?['mode']);
      if (mode != null && mode.isNotEmpty) params['mode'] = mode;
    }

    if (network == 'http' || network == 'h2') {
      final httpOpts = _asMap(proxy['h2-opts']) ?? _asMap(proxy['http-opts']);
      final path = _asString(httpOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final hostValue = httpOpts?['host'];
      if (hostValue is String && hostValue.isNotEmpty) {
        params['host'] = hostValue;
      } else {
        final hostList = _asList(hostValue);
        if (hostList != null) {
          final values = hostList.whereType<String>().toList();
          if (values.isNotEmpty) {
            params['host'] = values.first;
            if (values.length > 1) {
              warnings.add(
                const ImportIssue(
                  level: ImportIssueLevel.warning,
                  message: 'Multiple H2 hosts found in Clash proxy; using the first host',
                ),
              );
            }
          }
        }
      }
    }

    if (network == 'httpupgrade') {
      final upgradeOpts = _asMap(proxy['httpupgrade-opts']) ??
          _asMap(proxy['http-upgrade-opts']) ??
          _asMap(proxy['http-upgrade-options']);
      final path = _asString(upgradeOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final host = _asString(upgradeOpts?['host']);
      if (host != null && host.isNotEmpty) {
        params['host'] = host;
      } else {
        final headers = _asMap(upgradeOpts?['headers']);
        final hostHeader = _asString(headers?['Host']);
        if (hostHeader != null && hostHeader.isNotEmpty) params['host'] = hostHeader;
      }
    }

    final skipVerify = _asBool(proxy['skip-cert-verify']) ?? false;
    if (skipVerify) {
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'skip-cert-verify requested in Clash but will be controlled by app TLS settings',
        ),
      );
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'vless://$uuid@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static String? _clashVmessToUri(
    Map<String, Object?> proxy, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final uuid = _asString(proxy['uuid']);

    if (server == null || port == null || uuid == null) return null;

    final alterId = _asInt(proxy['alterId']) ?? 0;
    final cipher = _asString(proxy['cipher']) ?? 'auto';
    final network = _asString(proxy['network']) ?? 'tcp';

    final tlsEnabled = _asBool(proxy['tls']) ?? false;
    final serverName = _asString(proxy['servername']) ?? _asString(proxy['sni']) ?? '';

    var host = '';
    var path = '';

    if (network == 'ws') {
      final wsOpts = _asMap(proxy['ws-opts']);
      path = _asString(wsOpts?['path']) ?? '';
      final headers = _asMap(wsOpts?['headers']);
      host = _asString(headers?['Host']) ?? '';
    }

    if (network == 'grpc') {
      final grpcOpts = _asMap(proxy['grpc-opts']);
      final serviceName = _asString(grpcOpts?['grpc-service-name']);
      if (serviceName != null) {
        path = serviceName;
      }
    }

    if (network == 'http' || network == 'h2') {
      final httpOpts = _asMap(proxy['h2-opts']) ?? _asMap(proxy['http-opts']);
      path = _asString(httpOpts?['path']) ?? '';

      final hostValue = httpOpts?['host'];
      if (hostValue is String) {
        host = hostValue;
      } else {
        final hostList = _asList(hostValue);
        if (hostList != null) {
          final values = hostList.whereType<String>().toList();
          if (values.isNotEmpty) {
            host = values.first;
            if (values.length > 1) {
              warnings.add(
                const ImportIssue(
                  level: ImportIssueLevel.warning,
                  message: 'Multiple H2 hosts found in Clash proxy; using the first host',
                ),
              );
            }
          }
        }
      }
    }

    if (network == 'httpupgrade') {
      final upgradeOpts = _asMap(proxy['httpupgrade-opts']) ??
          _asMap(proxy['http-upgrade-opts']) ??
          _asMap(proxy['http-upgrade-options']);
      path = _asString(upgradeOpts?['path']) ?? '';

      final hostValue = upgradeOpts?['host'];
      if (hostValue is String) {
        host = hostValue;
      } else {
        final headers = _asMap(upgradeOpts?['headers']);
        host = _asString(headers?['Host']) ?? '';
      }
    }

    final vmess = <String, dynamic>{
      'v': '2',
      'ps': name,
      'add': server,
      'port': port.toString(),
      'id': uuid,
      'aid': alterId.toString(),
      'scy': cipher,
      'net': network,
      'type': 'none',
      'host': host,
      'path': path,
      'tls': tlsEnabled ? 'tls' : '',
      'sni': serverName,
      'alpn': '',
      'fp': 'chrome',
    };

    final alpn = _asList(proxy['alpn']);
    if (alpn != null) {
      final values = alpn.whereType<String>().toList();
      if (values.isNotEmpty) vmess['alpn'] = values.join(',');
    }

    final fp = _asString(proxy['client-fingerprint']);
    if (fp != null && fp.isNotEmpty) vmess['fp'] = fp;

    final skipVerify = _asBool(proxy['skip-cert-verify']) ?? false;
    if (skipVerify) {
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'skip-cert-verify requested in Clash but will be controlled by app TLS settings',
        ),
      );
    }

    final jsonStr = jsonEncode(vmess);
    final base64Str = base64.encode(utf8.encode(jsonStr));
    return 'vmess://$base64Str';
  }

  static String? _clashTrojanToUri(
    Map<String, Object?> proxy, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final password = _asString(proxy['password']);

    if (server == null || port == null || password == null) return null;

    final params = <String, String>{
      'security': 'tls',
    };

    final network = _asString(proxy['network']) ?? 'tcp';
    params['type'] = network;

    final sni = _asString(proxy['sni']) ?? _asString(proxy['servername']);
    if (sni != null && sni.isNotEmpty) params['sni'] = sni;

    final realityOpts = _asMap(proxy['reality-opts']);
    if (realityOpts != null) {
      params['security'] = 'reality';

      final pbk = _asString(realityOpts['public-key']);
      final sid = _asString(realityOpts['short-id']);
      final spx = _asString(realityOpts['spider-x']);

      if (pbk != null && pbk.isNotEmpty) params['pbk'] = pbk;
      if (sid != null && sid.isNotEmpty) params['sid'] = sid;
      if (spx != null && spx.isNotEmpty) params['spx'] = spx;
    }

    final fp = _asString(proxy['client-fingerprint']);
    if (fp != null && fp.isNotEmpty) params['fp'] = fp;

    final alpn = _asList(proxy['alpn']);
    if (alpn != null) {
      final values = alpn.whereType<String>().toList();
      if (values.isNotEmpty) params['alpn'] = values.join(',');
    }

    if (network == 'ws') {
      final wsOpts = _asMap(proxy['ws-opts']);
      final path = _asString(wsOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final headers = _asMap(wsOpts?['headers']);
      final host = _asString(headers?['Host']);
      if (host != null && host.isNotEmpty) params['host'] = host;
    }

    if (network == 'grpc') {
      final grpcOpts = _asMap(proxy['grpc-opts']);
      final serviceName = _asString(grpcOpts?['grpc-service-name']);
      if (serviceName != null && serviceName.isNotEmpty) {
        params['serviceName'] = serviceName;
      }

      final mode = _asString(grpcOpts?['grpc-mode']) ??
          _asString(grpcOpts?['grpcMode']) ??
          _asString(grpcOpts?['mode']);
      if (mode != null && mode.isNotEmpty) params['mode'] = mode;
    }

    if (network == 'http' || network == 'h2') {
      final httpOpts = _asMap(proxy['h2-opts']) ?? _asMap(proxy['http-opts']);
      final path = _asString(httpOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final hostValue = httpOpts?['host'];
      if (hostValue is String && hostValue.isNotEmpty) {
        params['host'] = hostValue;
      } else {
        final hostList = _asList(hostValue);
        if (hostList != null) {
          final values = hostList.whereType<String>().toList();
          if (values.isNotEmpty) {
            params['host'] = values.first;
            if (values.length > 1) {
              warnings.add(
                const ImportIssue(
                  level: ImportIssueLevel.warning,
                  message: 'Multiple H2 hosts found in Clash proxy; using the first host',
                ),
              );
            }
          }
        }
      }
    }

    if (network == 'httpupgrade') {
      final upgradeOpts = _asMap(proxy['httpupgrade-opts']) ??
          _asMap(proxy['http-upgrade-opts']) ??
          _asMap(proxy['http-upgrade-options']);
      final path = _asString(upgradeOpts?['path']);
      if (path != null && path.isNotEmpty) params['path'] = path;

      final host = _asString(upgradeOpts?['host']);
      if (host != null && host.isNotEmpty) {
        params['host'] = host;
      } else {
        final headers = _asMap(upgradeOpts?['headers']);
        final hostHeader = _asString(headers?['Host']);
        if (hostHeader != null && hostHeader.isNotEmpty) params['host'] = hostHeader;
      }
    }

    final skipVerify = _asBool(proxy['skip-cert-verify']) ?? false;
    if (skipVerify) {
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'skip-cert-verify requested in Clash but will be controlled by app TLS settings',
        ),
      );
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'trojan://$password@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static String? _clashHysteria2ToUri(
    Map<String, Object?> proxy, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final auth = _asString(proxy['password']) ??
        _asString(proxy['auth']) ??
        _asString(proxy['auth-str']) ??
        _asString(proxy['auth_str']);

    if (server == null || port == null || auth == null) return null;

    final params = <String, String>{};

    final sni = _asString(proxy['sni']) ??
        _asString(proxy['servername']) ??
        _asString(proxy['peer']);
    if (sni != null && sni.isNotEmpty) params['sni'] = sni;

    final alpnList = _asList(proxy['alpn']);
    if (alpnList != null) {
      final values = alpnList.whereType<String>().toList();
      if (values.isNotEmpty) params['alpn'] = values.join(',');
    } else {
      final alpn = _asString(proxy['alpn']);
      if (alpn != null && alpn.isNotEmpty) params['alpn'] = alpn;
    }

    final up = _asIntLoose(proxy['up']);
    if (up != null) params['up'] = up.toString();

    final down = _asIntLoose(proxy['down']);
    if (down != null) params['down'] = down.toString();

    final obfs = _asString(proxy['obfs']);
    if (obfs != null && obfs.isNotEmpty) params['obfs'] = obfs;

    final obfsPassword = _asString(proxy['obfs-password']) ?? _asString(proxy['obfs_password']);
    if (obfsPassword != null && obfsPassword.isNotEmpty) {
      params['obfs-password'] = obfsPassword;
    }

    final skipVerify = _asBool(proxy['skip-cert-verify']) ?? false;
    if (skipVerify) {
      params['insecure'] = '1';
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'skip-cert-verify requested in Clash but will be controlled by app TLS settings',
        ),
      );
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final queryPart = query.isEmpty ? '' : '?$query';

    return 'hy2://${Uri.encodeComponent(auth)}@${_formatHostForUri(server)}:$port$queryPart#${Uri.encodeComponent(name)}';
  }

  static String? _clashWireguardToUri(
    Map<String, Object?> proxy, {
    required String name,
    required List<ImportIssue> warnings,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final privateKey = _asString(proxy['private-key']) ?? _asString(proxy['private_key']);
    final publicKey = _asString(proxy['public-key']) ?? _asString(proxy['public_key']);

    if (server == null || port == null || privateKey == null || publicKey == null) {
      return null;
    }

    final presharedKey = _asString(proxy['preshared-key']) ?? _asString(proxy['preshared_key']);
    if (presharedKey != null && presharedKey.isNotEmpty) {
      warnings.add(
        const ImportIssue(
          level: ImportIssueLevel.warning,
          message: 'WireGuard preshared-key exists in Clash config but is not supported in URI import yet',
        ),
      );
    }

    final params = <String, String>{
      'publicKey': publicKey,
    };

    final addressRaw = proxy['ip'] ?? proxy['address'];
    if (addressRaw is String && addressRaw.isNotEmpty) {
      params['address'] = addressRaw;
    } else {
      final addressList = _asList(addressRaw);
      if (addressList != null) {
        final values = addressList.whereType<String>().toList();
        if (values.isNotEmpty) params['address'] = values.join(',');
      }
    }

    final mtu = _asInt(proxy['mtu']);
    if (mtu != null) params['mtu'] = mtu.toString();

    final reservedRaw = proxy['reserved'];
    if (reservedRaw is String && reservedRaw.isNotEmpty) {
      params['reserved'] = reservedRaw;
    } else {
      final reservedList = _asList(reservedRaw);
      if (reservedList != null) {
        final values = reservedList.map(_asInt).whereType<int>().toList();
        if (values.isNotEmpty) params['reserved'] = values.join(',');
      }
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'wg://${Uri.encodeComponent(privateKey)}@${_formatHostForUri(server)}:$port?$query#${Uri.encodeComponent(name)}';
  }

  static String? _clashShadowsocksToUri(
    Map<String, Object?> proxy, {
    required String name,
  }) {
    final server = _asString(proxy['server']);
    final port = _asInt(proxy['port']);
    final cipher = _asString(proxy['cipher']);
    final password = _asString(proxy['password']);

    if (server == null || port == null || cipher == null || password == null) {
      return null;
    }

    final userInfo = base64.encode(utf8.encode('$cipher:$password'));
    return 'ss://$userInfo@${_formatHostForUri(server)}:$port#${Uri.encodeComponent(name)}';
  }

  static Object? _yamlToDart(Object? node) {
    if (node is YamlMap) {
      final result = <String, Object?>{};
      for (final entry in node.entries) {
        final key = entry.key;
        if (key is String) {
          result[key] = _yamlToDart(entry.value);
        }
      }
      return result;
    }

    if (node is YamlList) {
      return node.nodes.map((e) => _yamlToDart(e.value)).toList();
    }

    return node;
  }

  static Map<String, Object?> _stringObjectMap(Map<Object?, Object?> map) {
    final result = <String, Object?>{};
    for (final entry in map.entries) {
      final key = entry.key;
      if (key is String) {
        result[key] = entry.value;
      }
    }
    return result;
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is String) {
          result[key] = entry.value;
        }
      }
      return result;
    }
    return null;
  }

  static List<Object?>? _asList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return null;
  }

  static String? _asString(Object? value) => value is String ? value : null;

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
      if (value == '1') return true;
      if (value == '0') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  static int? _asIntLoose(Object? value) {
    final direct = _asInt(value);
    if (direct != null) return direct;
    if (value is String) {
      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  static String _formatHostForUri(String host) {
    final trimmed = host.trim();
    if (trimmed.contains(':') && !trimmed.startsWith('[') && !trimmed.endsWith(']')) {
      return '[$trimmed]';
    }
    return trimmed;
  }
}
