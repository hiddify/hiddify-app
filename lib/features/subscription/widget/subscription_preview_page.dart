import 'package:flutter/material.dart';
import 'package:hiddify/features/config/logic/config_import_result.dart';
import 'package:hiddify/features/config/logic/config_import_service.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/subscription/model/subscription.dart';
import 'package:hiddify/features/subscription/service/subscription_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class SubscriptionPreviewPage extends HookConsumerWidget {
  final String? url;
  final String? content;
  final String source;

  const SubscriptionPreviewPage({required String url, super.key})
    : url = url,
      content = null,
      source = url;

  const SubscriptionPreviewPage.raw({
    required this.content,
    required this.source,
    super.key,
  }) : url = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = url != null
        ? ref.watch(fetchConfigsProvider(url!))
        : AsyncValue.data(
            ConfigImportService.importContent(content ?? '', source: source),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(url != null ? 'Subscription Preview' : 'Import Preview'),
      ),
      body: asyncResult.when(
        data: (result) => _SubscriptionPreviewBody(
          result: result,
          source: source,
          subscriptionUrl: url,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

final fetchConfigsProvider = FutureProvider.family<ConfigImportResult, String>((ref, url) {
  final service = ref.read(subscriptionServiceProvider);
  return service.fetchConfigs(url);
});

class _SubscriptionPreviewBody extends ConsumerStatefulWidget {
  final ConfigImportResult result;
  final String source;
  final String? subscriptionUrl;

  const _SubscriptionPreviewBody({
    required this.result,
    required this.source,
    required this.subscriptionUrl,
  });

  @override
  ConsumerState<_SubscriptionPreviewBody> createState() => _SubscriptionPreviewBodyState();
}

class _SubscriptionPreviewBodyState extends ConsumerState<_SubscriptionPreviewBody> {
  late List<Config> _selectedConfigs;
  bool _isPingTesting = false;

  @override
  void initState() {
    super.initState();
    _selectedConfigs = widget.result.items.map((e) => e.config).toList();
  }

  Future<void> _testPing() async {
    setState(() {
      _isPingTesting = true;
    });
    // Mock ping test
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      _isPingTesting = false;
    });
     // In real app, update configs with ping results
  }

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Padding(
           padding: const EdgeInsets.all(8),
           child: Row(
             children: [
               Expanded(
                 child: Text(
                   'Importable: ${widget.result.items.length}  |  Issues: ${widget.result.failures.length}',
                 ),
               ),
               ElevatedButton(
                 onPressed: _isPingTesting ? null : _testPing,
                 child: const Text('Test Ping'),
               ),
             ],
           ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (widget.result.failures.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Not Imported (with reason)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                for (final failure in widget.result.failures)
                  ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: Text(failure.issue.message),
                    subtitle: Text(
                      failure.raw,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    dense: true,
                  ),
                const Divider(height: 1),
              ],
              for (final item in widget.result.items)
                CheckboxListTile(
                  title: Text(item.config.name),
                  subtitle: Text(
                    item.warnings.isEmpty
                        ? item.config.type
                        : '${item.config.type}  |  warnings: ${item.warnings.length}',
                  ),
                  value: _selectedConfigs.contains(item.config),
                  onChanged: (val) {
                    setState(() {
                      if (val ?? false) {
                        _selectedConfigs.add(item.config);
                      } else {
                        _selectedConfigs.remove(item.config);
                      }
                    });
                  },
                ),
              if (widget.result.remainingText.isNotEmpty) ...[
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Remaining Text',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(widget.result.remainingText),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedConfigs.isEmpty
                      ? null
                      : () async {
                        if (widget.subscriptionUrl != null) {
                          // Subscription object for future use
                          final _ = Subscription(
                            id: const Uuid().v4(),
                            name: 'Imported Subscription',
                            url: widget.subscriptionUrl!,
                            lastUpdated: DateTime.now(),
                            configs: _selectedConfigs,
                          );
                        }

                        final controller = ref.read(configControllerProvider.notifier);
                        for (final c in _selectedConfigs) {
                          await controller.add(c);
                        }

                        // TODO: Save subscription object

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configs added!')),
                          );
                        }
                      },
              child: const Text('Import Selected'),
            ),
          ),
        ),
      ],
    );
}
