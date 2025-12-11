import 'package:flutter/material.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class ConfigSelectorSheet extends HookConsumerWidget {
  const ConfigSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(configControllerProvider);

    return Scaffold(
      body: configsAsync.when(
        data: (configs) {
          if (configs.isEmpty) {
            return const Center(child: Text('No configs available'));
          }
          return ListView.separated(
            itemCount: configs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final config = configs[index];
              return ListTile(
                leading: const Icon(Icons.dns_rounded),
                title: Text(config.name),
                subtitle: Text('${config.type} • ${config.ping}ms'),
                trailing: Radio<String>(
                  value: config.id,
                  // TODO: Implement active config tracking if needed, 
                  // for now we just assume the first one is active or 
                  // selecting one makes it the "target" for connection.
                  // Since ConnectionNotifier connects to a specific config, 
                  // we might want a "setSelectedConfig" in a controller.
                  // For this implementation, clicking the tile will "select" it 
                  // by re-ordering or just returning it.
                  groupValue: configs.first.id, 
                  onChanged: (_) {},
                ),
                onTap: () {
                  // Select the config by moving it to the top
                  ref.read(configControllerProvider.notifier).select(config.id);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
