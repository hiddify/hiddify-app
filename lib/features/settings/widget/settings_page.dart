import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Core Settings'),
      ),
      body: ListView(
        children: [
          _buildGeneralSection(context, ref),
          const Divider(),
          _buildWarpModeSection(context, ref),
          const Divider(),
          _buildMasqueSection(context, ref),
          const Divider(),
          _buildPsiphonSection(context, ref),
          const Divider(),
          _buildAdvancedSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, WidgetRef ref) {
    final bindAddress = ref.watch(CorePreferences.bindAddress);
    final endpoint = ref.watch(CorePreferences.endpoint);
    final licenseKey = ref.watch(CorePreferences.licenseKey);
    final dns = ref.watch(CorePreferences.dns);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('General Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text('Bind Address'),
          subtitle: Text(bindAddress),
          leading: const Icon(Icons.network_wifi),
          onTap: () => _showEditDialog(context, ref, CorePreferences.bindAddress, "Bind Address"),
        ),
        ListTile(
          title: const Text('Endpoint'),
          subtitle: Text(endpoint.isEmpty ? 'Auto' : endpoint),
          leading: const Icon(Icons.dns),
          onTap: () => _showEditDialog(context, ref, CorePreferences.endpoint, "Endpoint"),
        ),
        ListTile(
          title: const Text('License Key'),
          subtitle: Text(licenseKey.isEmpty ? 'Not set' : '********'),
          leading: const Icon(Icons.key),
          onTap: () => _showEditDialog(context, ref, CorePreferences.licenseKey, "License Key"),
        ),
        ListTile(
          title: const Text('DNS Server'),
          subtitle: Text(dns),
          leading: const Icon(Icons.security),
          onTap: () => _showEditDialog(context, ref, CorePreferences.dns, "DNS Server"),
        ),
      ],
    );
  }

  Widget _buildWarpModeSection(BuildContext context, WidgetRef ref) {
    final gool = ref.watch(CorePreferences.goolMode);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Warp Modes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SwitchListTile(
          title: const Text('Gool Mode (Warp-in-Warp)'),
          subtitle: const Text('Chains an inner Warp connection inside an outer Warp connection (Location Change)'),
          value: gool,
          onChanged: (val) => ref.read(CorePreferences.goolMode.notifier).update(val),
        ),
      ],
    );
  }

  Widget _buildMasqueSection(BuildContext context, WidgetRef ref) {
    final masque = ref.watch(CorePreferences.masqueMode);
    final autoFallback = ref.watch(CorePreferences.masqueAutoFallback);
    final preferred = ref.watch(CorePreferences.masquePreferred);
    final noise = ref.watch(CorePreferences.masqueNoise);
    final preset = ref.watch(CorePreferences.masqueNoisePreset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('MASQUE Protocol',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SwitchListTile(
          title: const Text('Enable MASQUE'),
          subtitle: const Text('Use MASQUE proxy protocol for enhanced censorship resistance'),
          value: masque,
          onChanged: (val) => ref.read(CorePreferences.masqueMode.notifier).update(val),
        ),
        if (masque) ...[
          SwitchListTile(
             title: const Text('Auto Fallback'),
              subtitle: const Text('Fallback to WireGuard if MASQUE fails'),
             value: autoFallback,
             onChanged: (val) => ref.read(CorePreferences.masqueAutoFallback.notifier).update(val),
          ),
          SwitchListTile(
             title: const Text('Prefer MASQUE'),
              subtitle: const Text('Connect via MASQUE first if available'),
             value: preferred,
             onChanged: (val) => ref.read(CorePreferences.masquePreferred.notifier).update(val),
          ),
          SwitchListTile(
             title: const Text('Enable Noise'),
              subtitle: const Text('Use QUIC stream obfuscation'),
             value: noise,
             onChanged: (val) => ref.read(CorePreferences.masqueNoise.notifier).update(val),
          ),
           if (noise)
            ListTile(
              title: const Text('Noise Preset'),
              subtitle: Text(preset),
              trailing: DropdownButton<String>(
                value: preset,
                items: ['light', 'medium', 'heavy', 'stealth', 'gfw', 'firewall']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) ref.read(CorePreferences.masqueNoisePreset.notifier).update(val);
                }
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPsiphonSection(BuildContext context, WidgetRef ref) {
     final enabled = ref.watch(CorePreferences.psiphonEnabled);
     final country = ref.watch(CorePreferences.psiphonCountry);

     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Psiphon Integration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
         SwitchListTile(
          title: const Text('Enable Psiphon'),
          subtitle: const Text('Chain connection through Psiphon network'),
          value: enabled,
          onChanged: (val) => ref.read(CorePreferences.psiphonEnabled.notifier).update(val),
        ),
        if (enabled)
          ListTile(
            title: const Text('Country Code'),
            subtitle: Text(country),
            onTap: () => _showEditDialog(context, ref, CorePreferences.psiphonCountry, "Country Code (e.g. US, AT)"),
          )
      ]
     );
  }

  Widget _buildAdvancedSection(BuildContext context, WidgetRef ref) {
    final proxy = ref.watch(CorePreferences.proxyAddress);
    final verbose = ref.watch(CorePreferences.verboseLogging);
    final scan = ref.watch(CorePreferences.scanEnabled);
    final rtt = ref.watch(CorePreferences.scanRtt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Advanced',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
         ListTile(
          title: const Text('SOCKS5 Proxy'),
          subtitle: Text(proxy.isEmpty ? 'None' : proxy),
          leading: const Icon(Icons.data_usage),
          onTap: () => _showEditDialog(context, ref, CorePreferences.proxyAddress, "SOCKS5 Proxy Address"),
        ),
        SwitchListTile(
          title: const Text('Verbose Logging'),
          value: verbose,
          onChanged: (val) => ref.read(CorePreferences.verboseLogging.notifier).update(val),
        ),
        SwitchListTile(
          title: const Text('Enable Scanner'),
           subtitle: const Text('Scan for best endpoint before connecting'),
          value: scan,
          onChanged: (val) => ref.read(CorePreferences.scanEnabled.notifier).update(val),
        ),
        if (scan)
           ListTile(
            title: const Text('Max RTT (ms)'),
            subtitle: Text(rtt.toString()),
            onTap: () => _showEditDialog(context, ref, CorePreferences.scanRtt, "Max RTT"),
          ),
      ],
    );
  }

  Future<void> _showEditDialog<T>(BuildContext context, WidgetRef ref, dynamic provider, String title) async {
      final notifier = ref.read(provider.notifier);
      final currentVal = ref.read(provider);
      final controller = TextEditingController(text: currentVal.toString());
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: title),
            keyboardType: currentVal is int ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (currentVal is int) {
                  notifier.update(int.tryParse(controller.text) ?? currentVal);
                } else {
                  notifier.update(controller.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
  }

}
