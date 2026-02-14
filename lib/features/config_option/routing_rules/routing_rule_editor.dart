import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RoutingRuleEditor extends HookConsumerWidget {
  const RoutingRuleEditor({
    super.key,
    this.initialRule,
    required this.onSave,
  });

  final SingboxRule? initialRule;
  final void Function(SingboxRule rule) onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    
    final domainsController = useTextEditingController(text: initialRule?.domains ?? '');
    final ipController = useTextEditingController(text: initialRule?.ip ?? '');
    final portController = useTextEditingController(text: initialRule?.port ?? '');
    final protocolController = useTextEditingController(text: initialRule?.protocol ?? '');
    final outbound = useState(initialRule?.outbound ?? RuleOutbound.proxy);
    final network = useState(initialRule?.network ?? RuleNetwork.tcpAndUdp);

    return AlertDialog(
      title: Text(initialRule == null ? t.config.addCustomRule : t.config.editCustomRule),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Domains field
            TextField(
              controller: domainsController,
              decoration: InputDecoration(
                labelText: t.config.domains,
                hintText: 'example.com, *.google.com, geosite:ir',
                helperText: t.config.domainsHint,
              ),
            ),
            const SizedBox(height: 16),
            
            // IP field
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: t.config.ip,
                hintText: '192.168.1.1, geoip:ir',
                helperText: t.config.ipHint,
              ),
            ),
            const SizedBox(height: 16),
            
            // Port field
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: t.config.port,
                hintText: '80, 443, 8080',
                helperText: t.config.portHint,
              ),
            ),
            const SizedBox(height: 16),
            
            // Protocol field
            TextField(
              controller: protocolController,
              decoration: InputDecoration(
                labelText: t.config.protocol,
                hintText: 'http, https, tcp, udp',
                helperText: t.config.protocolHint,
              ),
            ),
            const SizedBox(height: 16),
            
            // Outbound selection
            DropdownButtonFormField<RuleOutbound>(
              value: outbound.value,
              decoration: InputDecoration(
                labelText: t.config.outbound,
              ),
              items: RuleOutbound.values.map((outbound) {
                return DropdownMenuItem(
                  value: outbound,
                  child: Row(
                    children: [
                      Icon(_getOutboundIcon(outbound)),
                      const SizedBox(width: 8),
                      Text(_getOutboundText(outbound, t)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  outbound.value = value;
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Network selection
            DropdownButtonFormField<RuleNetwork>(
              value: network.value,
              decoration: InputDecoration(
                labelText: t.config.network,
              ),
              items: RuleNetwork.values.map((network) {
                return DropdownMenuItem(
                  value: network,
                  child: Text(_getNetworkText(network)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  network.value = value;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.general.cancel),
        ),
        FilledButton(
          onPressed: () {
            final rule = SingboxRule(
              domains: domainsController.text.trim().isEmpty ? null : domainsController.text.trim(),
              ip: ipController.text.trim().isEmpty ? null : ipController.text.trim(),
              port: portController.text.trim().isEmpty ? null : portController.text.trim(),
              protocol: protocolController.text.trim().isEmpty ? null : protocolController.text.trim(),
              outbound: outbound.value,
              network: network.value,
            );
            onSave(rule);
            Navigator.of(context).pop();
          },
          child: Text(t.general.save),
        ),
      ],
    );
  }

  IconData _getOutboundIcon(RuleOutbound outbound) {
    switch (outbound) {
      case RuleOutbound.proxy:
        return Icons.vpn_key;
      case RuleOutbound.bypass:
        return Icons.direct_route;
      case RuleOutbound.block:
        return Icons.block;
    }
  }

  String _getOutboundText(RuleOutbound outbound, Translations t) {
    switch (outbound) {
      case RuleOutbound.proxy:
        return t.config.proxy;
      case RuleOutbound.bypass:
        return t.config.direct;
      case RuleOutbound.block:
        return t.config.block;
    }
  }

  String _getNetworkText(RuleNetwork network) {
    switch (network) {
      case RuleNetwork.tcpAndUdp:
        return 'TCP/UDP';
      case RuleNetwork.tcp:
        return 'TCP';
      case RuleNetwork.udp:
        return 'UDP';
    }
  }
}

