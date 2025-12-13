import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class ConfigSelectorSheet {
  static void show(BuildContext context) {
    unawaited(WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text(
            'Select Configuration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isTopBarLayerAlwaysVisible: true,
          child: const _ConfigSelectorContent(),
        ),
      ],
    ));
  }
}

class _ConfigSelectorContent extends ConsumerWidget {
  const _ConfigSelectorContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(configControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: configsAsync.when(
        data: (configs) {
          if (configs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const Gap(16),
                    Text(
                      'No configs available',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: configs.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 64,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final config = configs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.dns_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  config.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        config.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const Gap(4),
                    Text(
                      '${config.ping}ms',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                trailing: Radio<String>(
                  value: config.id,
                  // ignore: deprecated_member_use
                  groupValue: configs.first.id, // TODO: Real active config
                  // ignore: deprecated_member_use
                  onChanged: (_) {
                    unawaited(ref
                        .read(configControllerProvider.notifier)
                        .select(config.id));
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  // Select the config by moving it to the top
                  unawaited(ref
                      .read(configControllerProvider.notifier)
                      .select(config.id));
                  Navigator.of(context).pop();
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }
}
