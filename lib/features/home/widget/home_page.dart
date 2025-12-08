import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/widget/settings_page.dart';
import '../../connection/logic/connection_notifier.dart';
import '../../config/data/config_repository.dart';
import '../../config/widget/add_config_sheet.dart';


class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    final configsAsync = ref.watch(configRepositoryProvider);
    
    // We need real-time updates of configs list, but ConfigRepository is FutureProvider initially?
    // It should be a Stream or we should force refresh. 
    // Ideally ConfigRepository provides a Stream<List<Config>> or we use a StateNotifier for config list.
    // For now, let's assume we can re-read it or improvements later.
    // Actually, create a configListProvider?
    
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
          // Background?
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Config Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FutureBuilder<ConfigRepository>(
                  future: ref.read(configRepositoryProvider.future),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final repo = snapshot.data!;
                    final configs = repo.getConfigs();
                    
                    if (configs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No configs added. Add one to connect.'),
                        ),
                      );
                    }
                    
                    // Simple selector for now, ideally a modal or dropdown
                    // Just showing first or selected.
                    // Need a provider for "Selected Config".
                    // Let's pick the first one temporarily or manage selection in Notifier.
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
                          // TODO: Show config selector sheet
                        },
                      ),
                    );
                  }
                ),
              ),
              
              const Spacer(),
              
              // Big Connect Button
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Get selected config
                     ref.read(configRepositoryProvider.future).then((repo) {
                       final configs = repo.getConfigs();
                       if (configs.isNotEmpty) {
                         // Decide action based on state
                         final notifier = ref.read(connectionProvider.notifier);
                         if (connectionState == ConnectionStatus.disconnected || connectionState == ConnectionStatus.error) {
                           notifier.connect(configs.first); // Connect to first for now
                         } else if (connectionState == ConnectionStatus.connected || connectionState == ConnectionStatus.connecting) {
                           notifier.disconnect();
                         }
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a config first')));
                       }
                     });
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
