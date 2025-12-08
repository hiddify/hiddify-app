import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/widget/settings_page.dart';
import '../../connection/logic/connection_notifier.dart';
import '../../config/controller/config_controller.dart';
import '../../config/widget/add_config_sheet.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionNotifierProvider);
    final configsAsync = ref.watch(configControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiddify v3 Preview'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Config Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: configsAsync.when(
                  data: (configs) {
                    if (configs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No configs added. Add one to connect.'),
                        ),
                      );
                    }
                    
                    final currentConfig = configs.first; 
                    
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.shield),
                        title: Text(currentConfig.name),
                        subtitle: Text('${currentConfig.type} - ${currentConfig.ping}ms'),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () {
                          // TODO: Show config selector
                        },
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading configs: $e'),
                ),
              ),
              
              const Spacer(),
              
              // Big Connect Button
              Center(
                child: GestureDetector(
                  onTap: () {
                     final configs = configsAsync.valueOrNull;
                     if (configs != null && configs.isNotEmpty) {
                       final notifier = ref.read(connectionNotifierProvider.notifier);
                       if (connectionState == ConnectionStatus.disconnected || connectionState == ConnectionStatus.error) {
                         notifier.connect(configs.first);
                       } else if (connectionState == ConnectionStatus.connected || connectionState == ConnectionStatus.connecting) {
                         notifier.disconnect();
                       }
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a config first')));
                     }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getButtonColor(connectionState),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor(connectionState).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new, 
                          size: 80, 
                          color: Colors.white
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getStatusText(connectionState),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Add Config Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                     showModalBottomSheet(
                       context: context, 
                       isScrollControlled: true,
                       builder: (_) => const AddConfigSheet()
                     );
                  }, 
                  icon: const Icon(Icons.add),
                  label: const Text('Add Config'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected: return Colors.green;
      case ConnectionStatus.connecting: return Colors.orange;
      case ConnectionStatus.error: return Colors.red;
      case ConnectionStatus.disconnected: return Colors.grey;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected: return 'CONNECTED';
      case ConnectionStatus.connecting: return 'CONNECTING...';
      case ConnectionStatus.error: return 'ERROR';
      case ConnectionStatus.disconnected: return 'TAP TO CONNECT';
    }
  }
}
