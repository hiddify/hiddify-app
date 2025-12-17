import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hiddify/features/subscription/data/subscription_repository.dart';
import 'package:hiddify/features/subscription/model/subscription.dart';
import 'package:hiddify/features/subscription/service/subscription_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class SubscriptionPreviewPage extends HookConsumerWidget {
  final String? url;
  final String? content;
  final String source;

  const SubscriptionPreviewPage({required this.url, super.key})
    : content = null,
      source = url ?? '';

  const SubscriptionPreviewPage.raw({
    required this.content,
    required this.source,
    super.key,
  }) : url = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final asyncResult = url != null
        ? ref.watch(fetchConfigsProvider(url!))
        : AsyncValue.data(
            ConfigImportService.importContent(content ?? '', source: source),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          url != null
              ? t.profile.overviewPageTitle
              : t.profile.detailsPageTitle,
        ),
        centerTitle: true,
      ),
      body: asyncResult.when(
        data: (ConfigImportResult result) => _SubscriptionPreviewBody(
          result: result,
          source: source,
          subscriptionUrl: url,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace stack) =>
            Center(child: Text('Error: $err')),
      ),
    );
  }
}

final fetchConfigsProvider = FutureProvider.family<ConfigImportResult, String>((
  Ref ref,
  String url,
) {
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
  ConsumerState<_SubscriptionPreviewBody> createState() =>
      _SubscriptionPreviewBodyState();
}

class _SubscriptionPreviewBodyState
    extends ConsumerState<_SubscriptionPreviewBody> {
  late List<Config> _selectedConfigs;
  bool _isPingTesting = false;

  @override
  void initState() {
    super.initState();
    _selectedConfigs = widget.result.items
        .map((e) => e.config)
        .toList();
  }

  Future<void> _testPing() async {
    setState(() {
      _isPingTesting = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      _isPingTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Column(
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
              FilledButton.tonal(
                onPressed: _isPingTesting ? null : _testPing,
                child: Text(
                  _isPingTesting ? '...' : t.proxies.delayTestTooltip,
                ),
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
                  onChanged: (bool? val) {
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
              onPressed: _selectedConfigs.isEmpty
                  ? null
                  : () async {
                      if (widget.subscriptionUrl != null) {
                        final repo = await ref.read(
                          subscriptionRepositoryProvider.future,
                        );

                        final url = widget.subscriptionUrl!;
                        final existingSubs = repo.getSubscriptions();
                        final existingIndex = existingSubs.indexWhere(
                          (Subscription s) => s.url == url,
                        );

                        final sub = Subscription(
                          id: existingIndex != -1
                              ? existingSubs[existingIndex].id
                              : const Uuid().v4(),
                          name: existingIndex != -1
                              ? existingSubs[existingIndex].name
                              : (Uri.tryParse(url)?.host.isNotEmpty ?? false)
                              ? Uri.parse(url).host
                              : 'Imported Subscription',
                          url: url,
                          lastUpdated: DateTime.now(),
                          configs: _selectedConfigs,
                        );

                        if (existingIndex != -1) {
                          await repo.updateSubscription(sub);
                        } else {
                          await repo.addSubscription(sub);
                        }
                      }

                      final controller = ref.read(
                        configControllerProvider.notifier,
                      );
                      await controller.addAll(_selectedConfigs);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.home.configAdded),
                            behavior: SnackBarBehavior.floating,
                          ),
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
}
