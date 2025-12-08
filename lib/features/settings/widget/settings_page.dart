import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import '../../system/data/system_optimization_service.dart';
import '../../../core/logger/log_viewer_page.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch preferences
    final coreMode = ref.watch(CorePreferences.coreMode);
    final routingRule = ref.watch(CorePreferences.routingRule);
    final enableLogging = ref.watch(CorePreferences.enableLogging);
    final logLevel = ref.watch(CorePreferences.logLevel);
    
    // Existing prefs (kept for advanced manual overrides)
    final configContent = ref.watch(CorePreferences.configContent);
    final assetPath = ref.watch(CorePreferences.assetPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Connectivity'),
          ListTile(
            title: const Text('Core Mode'),
            subtitle: Text(coreMode == 'vpn' ? 'VPN (Tunnel)' : 'Proxy Mode'),
            trailing: DropdownButton<String>(
               value: coreMode,
               items: const [
                 DropdownMenuItem(value: 'proxy', child: Text('Proxy')),
                 DropdownMenuItem(value: 'vpn', child: Text('VPN')),
               ],
               onChanged: (val) {
                 if (val != null) ref.read(CorePreferences.coreMode.notifier).update(val);
               },
            ),
          ),
          ListTile(
            title: const Text('Routing Rule'),
            subtitle: _getRoutingSubtitle(routingRule),
            trailing: DropdownButton<String>(
               value: routingRule,
               items: const [
                 DropdownMenuItem(value: 'global', child: Text('Global')),
                 DropdownMenuItem(value: 'geo_iran', child: Text('Geo Iran')),
                 DropdownMenuItem(value: 'bypass_lan', child: Text('Bypass LAN')),
               ],
               onChanged: (val) {
                 if (val != null) ref.read(CorePreferences.routingRule.notifier).update(val);
               },
            ),
          ),

          _buildSectionHeader('System'),
          ListTile(
            title: const Text('Battery Optimization'),
            subtitle: const Text('Disable for stable background connection'),
            trailing: const Icon(Icons.battery_alert),
            onTap: () async {
              await ref.read(systemOptimizationServiceProvider).requestDisableBatteryOptimization();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requested battery exemption')));
            },
          ),
          
          _buildSectionHeader('Logging & Debugging'),
          SwitchListTile(
            title: const Text('Enable Core Logs'),
            value: enableLogging,
            onChanged: (val) => ref.read(CorePreferences.enableLogging.notifier).update(val),
          ),
          if (enableLogging)
            ListTile(
              title: const Text('Log Level'),
              trailing: DropdownButton<String>(
                value: logLevel,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'error', child: Text('Error')),
                  DropdownMenuItem(value: 'warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'debug', child: Text('Debug')),
                ],
                onChanged: (val) {
                  if (val != null) ref.read(CorePreferences.logLevel.notifier).update(val);
                },
              ),
            ),
          ListTile(
            title: const Text('View Logs'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
               // Import LogViewerPage locally or ensure usage
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogViewerPage()));
            },
          ),
            
          ExpansionTile(
            title: const Text('Advanced / Legacy'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: TextEditingController(text: assetPath), // Note: Cursor resets on rebuild
                  decoration: const InputDecoration(labelText: 'Asset Path'),
                  onSubmitted: (val) => ref.read(CorePreferences.assetPath.notifier).update(val),
                ),
              ),
              Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Text("Config JSON override (Warning: Managed by App in v3)", style: TextStyle(color: Colors.orange)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _getRoutingSubtitle(String rule) {
    switch (rule) {
      case 'global': return const Text('Proxy everything');
      case 'geo_iran': return const Text('Direct Iran / Block Ads');
      case 'bypass_lan': return const Text('Bypass Local Network');
      default: return Text(rule);
    }
  }
}
