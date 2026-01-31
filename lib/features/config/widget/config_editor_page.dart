import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';



class ConfigEditorPage extends HookConsumerWidget {
  const ConfigEditorPage({required this.config, super.key});

  final Config config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Config Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Config',
            onPressed: () => _copyConfig(context),
          ),
        ],
      ),
      body: _ConfigEditorBody(config: config, colorScheme: colorScheme),
    );
  }

  Future<void> _copyConfig(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: config.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config copied to clipboard')),
      );
    }
  }
}

class _ConfigEditorBody extends StatefulWidget {
  const _ConfigEditorBody({required this.config, required this.colorScheme});

  final Config config;
  final ColorScheme colorScheme;

  @override
  State<_ConfigEditorBody> createState() => _ConfigEditorBodyState();
}

class _ConfigEditorBodyState extends State<_ConfigEditorBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _jsonController;
  late Map<String, dynamic> _parsedConfig;
  bool _isJsonValid = true;
  String _jsonError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jsonController = TextEditingController(text: widget.config.content);
    _parseConfig();
  }

  void _parseConfig() {
    try {
      final content = _jsonController.text.trim();
      if (content.startsWith('{')) {
        _parsedConfig = jsonDecode(content) as Map<String, dynamic>;
        _isJsonValid = true;
      } else {
        _parsedConfig = {'uri': content, '_type': 'uri'};
        _isJsonValid = true;
      }
    } catch (e) {
      _parsedConfig = {};
      _isJsonValid = false;
      _jsonError = e.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Visual Editor', icon: Icon(Icons.tune)),
          Tab(text: 'Raw JSON', icon: Icon(Icons.code)),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _VisualEditor(
              config: _parsedConfig,
              colorScheme: widget.colorScheme,
              onChanged: (key, value) {
                setState(() {
                  _parsedConfig[key] = value;
                  try {
                    if (_jsonController.text.trim().startsWith('{')) {
                      _jsonController.text = const JsonEncoder.withIndent(
                        '  ',
                      ).convert(_parsedConfig);
                    }
                  } catch (_) {}
                });
              },
            ),
            _RawJsonEditor(
              controller: _jsonController,
              isValid: _isJsonValid,
              error: _jsonError,
              colorScheme: widget.colorScheme,
              onChanged: (val) {
                setState(_parseConfig);
              },
            ),
          ],
        ),
      ),
    ],
  );
}


class _VisualEditor extends StatelessWidget {
  const _VisualEditor({
    required this.config,
    required this.colorScheme,
    required this.onChanged,
  });

  final Map<String, dynamic> config;
  final ColorScheme colorScheme;
  final void Function(String key, dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (config.isEmpty) {
      return const Center(child: Text('No config to edit'));
    }
    final sections = _groupSettings(config);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(config: config, colorScheme: colorScheme),
        const Gap(16),
        for (final section in sections.entries) ...[
          AppSectionHeader(
            title: section.key,
            icon: _getSectionIcon(section.key),
          ),
          const Gap(8),
          AppSettingsCard(
            children: [
              for (var i = 0; i < section.value.entries.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64),
                _SettingField(
                  fieldKey: section.value.entries.elementAt(i).key,
                  value: section.value.entries.elementAt(i).value,
                  colorScheme: colorScheme,
                  onChanged: (v) => onChanged(
                    section.value.entries.elementAt(i).key,
                    v,
                  ),
                  isSensitive: _isSensitiveField(
                    section.value.entries.elementAt(i).key,
                  ),
                ),
              ],
            ],
          ),
          const Gap(16),
        ],
      ],
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'Connection':
        return Icons.link_rounded;
      case 'Security':
        return Icons.security_rounded;
      case 'Transport':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.settings_rounded;
    }
  }

  Map<String, Map<String, dynamic>> _groupSettings(
    Map<String, dynamic> config,
  ) {
    final groups = <String, Map<String, dynamic>>{
      'Connection': <String, dynamic>{},
      'Security': <String, dynamic>{},
      'Transport': <String, dynamic>{},
      'Other': <String, dynamic>{},
    };

    for (final entry in config.entries) {
      final key = entry.key;
      if (_isConnectionField(key)) {
        groups['Connection']![key] = entry.value;
      } else if (_isSecurityField(key)) {
        groups['Security']![key] = entry.value;
      } else if (_isTransportField(key)) {
        groups['Transport']![key] = entry.value;
      } else {
        groups['Other']![key] = entry.value;
      }
    }
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  bool _isConnectionField(String key) =>
      ['address', 'port', 'server', 'host', 'sni', 'serverName'].contains(key);

  bool _isSecurityField(String key) => [
    'security',
    'tls',
    'allowInsecure',
    'fingerprint',
    'alpn',
    'flow',
    'encryption',
    'password',
    'uuid',
    'id',
  ].contains(key);

  bool _isTransportField(String key) => [
    'network',
    'type',
    'path',
    'headers',
    'serviceName',
    'mode',
  ].contains(key);

  bool _isSensitiveField(String key) => [
    'address',
    'port',
    'server',
    'host',
    'sni',
    'serverName',
    'password',
    'uuid',
    'id',
  ].contains(key);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.config, required this.colorScheme});
  final Map<String, dynamic> config;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final protocol = config['protocol'] ?? config['_protocol'] ?? 'unknown';
    final remark = config['_remark'] ?? config['ps'] ?? 'Unnamed';

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.vpn_key, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remark.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Protocol: $protocol',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.fieldKey,
    required this.value,
    required this.colorScheme,
    required this.onChanged,
    this.isSensitive = false,
  });

  final String fieldKey;
  final dynamic value;
  final ColorScheme colorScheme;
  final ValueChanged<dynamic> onChanged;
  final bool isSensitive;

  @override
  Widget build(BuildContext context) => AppSettingsTile(
        title: fieldKey,
        subtitle: isSensitive ? 'Changing may break connection' : null,
        icon:
            isSensitive ? Icons.warning_amber_rounded : Icons.settings_rounded,
        isDanger: isSensitive,
        trailing: _buildValueWidget(context),
      );

  Widget _buildValueWidget(BuildContext context) {
    if (value is bool) {
      return Switch(
        value: value as bool,
        onChanged: (v) => _handleChange(context, v),
      );
    }

    if (value is int) {
      return SizedBox(
        width: 80,
        child: TextField(
          controller: TextEditingController(text: value.toString()),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (v) => _handleChange(context, int.tryParse(v) ?? value),
        ),
      );
    }

    if (value is String) {
      return SizedBox(
        width: 150,
        child: TextField(
          controller: TextEditingController(text: value as String),
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (v) => _handleChange(context, v),
        ),
      );
    }
    return Text(
      value.runtimeType.toString(),
      style: TextStyle(color: colorScheme.outline),
    );
  }

  void _handleChange(BuildContext context, dynamic newValue) {
    if (isSensitive) {
      unawaited(
        showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning_amber, color: Colors.orange),
            title: const Text('Warning'),
            content: Text(
              'Changing "$fieldKey" may break your connection.\n\n'
              'Are you sure you want to change it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Change'),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed ?? false) {
            onChanged(newValue);
          }
        }),
      );
    } else {
      onChanged(newValue);
    }
  }
}


class _RawJsonEditor extends StatelessWidget {
  const _RawJsonEditor({
    required this.controller,
    required this.isValid,
    required this.error,
    required this.colorScheme,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final String error;
  final ColorScheme colorScheme;
  final ValueChanged<String> onChanged;

  String _formatJson(String content) {
    try {
      if (content.trim().startsWith('{')) {
        final parsed = jsonDecode(content);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
    } catch (_) {}
    return content;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isValid
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              size: 16,
              color: isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isValid ? 'Valid JSON' : 'Invalid: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: isValid ? Colors.green : Colors.red,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_left, size: 18),
              tooltip: 'Format JSON',
              onPressed: () {
                final formatted = _formatJson(controller.text);
                controller.text = formatted;
                onChanged(formatted);
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: onChanged,
        ),
      ),
    ],
  );
}
