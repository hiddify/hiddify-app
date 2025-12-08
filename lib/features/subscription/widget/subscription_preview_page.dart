import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../config/model/config.dart';
import '../../config/controller/config_controller.dart';
import '../service/subscription_service.dart';
import '../model/subscription.dart';

class SubscriptionPreviewPage extends HookConsumerWidget {
  final String url;

  const SubscriptionPreviewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConfigs = ref.watch(fetchConfigsProvider(url));

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Preview')),
      body: asyncConfigs.when(
        data: (configs) => _SubscriptionPreviewBody(configs: configs, url: url),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

final fetchConfigsProvider = FutureProvider.family<List<Config>, String>((ref, url) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.fetchConfigs(url);
});

class _SubscriptionPreviewBody extends ConsumerStatefulWidget {
  final List<Config> configs;
  final String url;

  const _SubscriptionPreviewBody({required this.configs, required this.url});

  @override
  ConsumerState<_SubscriptionPreviewBody> createState() => _SubscriptionPreviewBodyState();
}

class _SubscriptionPreviewBodyState extends ConsumerState<_SubscriptionPreviewBody> {
  late List<Config> _selectedConfigs;
  bool _isPingTesting = false;

  @override
  void initState() {
    super.initState();
    _selectedConfigs = List.from(widget.configs);
  }

  Future<void> _testPing() async {
    setState(() {
      _isPingTesting = true;
    });
    // Mock ping test
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isPingTesting = false;
    });
     // In real app, update configs with ping results
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
           padding: const EdgeInsets.all(8.0),
           child: Row(
             children: [
               Expanded(child: Text('Found ${widget.configs.length} configs')),
               ElevatedButton(
                 onPressed: _isPingTesting ? null : _testPing,
                 child: const Text('Test Ping'),
               )
             ],
           ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.configs.length,
            itemBuilder: (context, index) {
              final config = widget.configs[index];
              final isSelected = _selectedConfigs.contains(config);
              return CheckboxListTile(
                title: Text(config.name),
                subtitle: Text(config.type),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedConfigs.add(config);
                    } else {
                      _selectedConfigs.remove(config);
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final sub = Subscription(
                  id: const Uuid().v4(),
                  name: 'Imported Subscription',
                  url: widget.url,
                  lastUpdated: DateTime.now(),
                  configs: _selectedConfigs,
                );
                
                final controller = ref.read(configControllerProvider.notifier);
                for (final c in _selectedConfigs) {
                  await controller.add(c);
                }
                
                // TODO: Save subscription object
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configs added!')));
                }
              },
              child: const Text('Import Selected'),
            ),
          ),
        )
      ],
    );
  }
}
