import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/notifier/core_settings_notifier.dart';

class CoreSettingsPage extends HookConsumerWidget {
  const CoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(coreSettingsNotifierProvider);
    final notifier = ref.read(coreSettingsNotifierProvider.notifier);
    
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocol Configuration'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, "General"),
          ListTile(
            title: const Text('Bind Address'),
            subtitle: Text(settings.bindAddress),
            trailing: const Icon(Icons.edit),
            onTap: () => _editString(context, "Bind Address", settings.bindAddress, notifier.updateBindAddress),
          ),
          ListTile(
            title: const Text('DNS Address'),
            subtitle: Text(settings.dnsAddress),
            trailing: const Icon(Icons.edit),
            onTap: () => _editString(context, "DNS Address", settings.dnsAddress, notifier.updateDnsAddress),
          ),
           SwitchListTile(
            title: const Text('Verbose Logging'),
            value: settings.verbose,
            onChanged: notifier.toggleVerbose,
          ),
          
          _buildSectionHeader(context, "Protocol Selection"),
          RadioListTile<String>(
            title: const Text('Standard Mode (Warp)'),
            subtitle: const Text('Basic connection'),
            value: 'standard',
            groupValue: _getCurrentMode(settings),
            onChanged: (_) {
              notifier.toggleGool(false);
              notifier.togglePsiphon(false);
              notifier.toggleMasque(false);
            },
          ),
           RadioListTile<String>(
            title: const Text('Gool Mode'),
            subtitle: const Text('Warp-in-Warp chaining'),
            value: 'gool',
            groupValue: _getCurrentMode(settings),
            onChanged: (_) => notifier.toggleGool(true),
          ),
           RadioListTile<String>(
            title: const Text('Psiphon Mode'),
            subtitle: const Text('Warp over Psiphon'),
            value: 'psiphon',
            groupValue: _getCurrentMode(settings),
            onChanged: (_) => notifier.togglePsiphon(true),
          ),
          if (settings.enablePsiphon)
             ListTile(
              title: const Text('Psiphon Country'),
              subtitle: Text(settings.psiphonCountry),
               trailing: const Icon(Icons.flag),
               onTap: () => _editString(context, "Country Code (iso2)", settings.psiphonCountry, notifier.updatePsiphonCountry),
            ),

           RadioListTile<String>(
            title: const Text('Masque Mode'),
             subtitle: const Text('Warp over MASQUE/QUIC'),
            value: 'masque',
            groupValue: _getCurrentMode(settings),
            onChanged: (_) => notifier.toggleMasque(true),
          ),
          
          if (settings.enableMasque) ...[
             SwitchListTile(
              title: const Text('Auto Fallback'),
              subtitle: const Text('Fallback to WireGuard if Masque fails'),
              value: settings.masqueAutoFallback,
               onChanged: notifier.toggleMasqueAutoFallback,
            ),
             SwitchListTile(
              title: const Text('Prefer Masque'),
              value: settings.masquePreferred,
              onChanged: notifier.toggleMasquePreferred,
            ),
             SwitchListTile(
              title: const Text('Noize Obfuscation'),
               subtitle: const Text('Enable traffic noise padding'),
              value: settings.enableMasqueNoize,
              onChanged: notifier.toggleMasqueNoize,
            ),
             if (settings.enableMasqueNoize)
              ListTile(
                title: const Text('Noize Preset'),
                subtitle: Text(settings.masqueNoizePreset.toUpperCase()),
                trailing: PopupMenuButton<String>(
                  onSelected: notifier.updateMasqueNoizePreset,
                  itemBuilder: (context) => ['light', 'medium', 'heavy', 'stealth', 'gfw', 'firewall'].map((e) => 
                    PopupMenuItem(value: e, child: Text(e.toUpperCase()))
                  ).toList(),
                ),
              ),
          ],
          
           _buildSectionHeader(context, "Endpoints & Security"),
          ListTile(
            title: const Text('License Key'),
             subtitle: Text(settings.licenseKey.isEmpty ? "Unset" : "********"),
             trailing: const Icon(Icons.key),
            onTap: () => _editString(context, "License Key", settings.licenseKey, notifier.updateLicenseKey),
          ),
           ListTile(
            title: const Text('Custom Endpoint'),
             subtitle: Text(settings.customEndpoint.isEmpty ? "Auto" : settings.customEndpoint),
             trailing: const Icon(Icons.cloud),
            onTap: () => _editString(context, "Endpoint", settings.customEndpoint, notifier.updateCustomEndpoint),
          ),
          
          _buildSectionHeader(context, "Advanced"),
           ListTile(
            title: const Text('SOCKS5 Proxy Chain'),
             subtitle: Text(settings.proxyAddress.isEmpty ? "Disabled" : settings.proxyAddress),
            onTap: () => _editString(context, "Proxy Address (e.g. socks5://1.2.3.4:1080)", settings.proxyAddress, notifier.updateProxyAddress),
          ),
           SwitchListTile(
            title: const Text('Endpoint Scanning'),
            value: settings.enableScan,
            onChanged: notifier.toggleScan,
          ),
          if (settings.enableScan)
             ListTile(
            title: const Text('Max RTT (ms)'),
             subtitle: Text('${settings.scanRtt} ms'),
             trailing: const Icon(Icons.timer),
             onTap: () => _editString(context, "RTT Threshold (ms)", settings.scanRtt.toString(), (v) => notifier.updateScanRtt(int.tryParse(v) ?? 1000)),
          ),
        ],
      ),
    );
  }

  String _getCurrentMode(CoreSettings s) {
    if (s.enableGool) return 'gool';
    if (s.enablePsiphon) return 'psiphon';
    if (s.enableMasque) return 'masque';
    return 'standard';
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _editString(BuildContext context, String label, String currentVal, Function(String) onSave) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $label"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            onSave(controller.text);
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
