import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class ConfigSelectorSheet {
  static void show(BuildContext context) {
    unawaited(
      WoltModalSheet.show<void>(
        context: context,
        pageListBuilder: (context) => [
          WoltModalSheetPage(
            topBarTitle: const Text(
              'Select Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            isTopBarLayerAlwaysVisible: true,
            child: const _ConfigSelectorListWrapper(),
          ),
        ],
      ),
    );
  }
}

class _ConfigSelectorListWrapper extends ConsumerWidget {
  const _ConfigSelectorListWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(configControllerProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return configsAsync.when(
      data: (configs) {
        if (configs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                List.generate(configs.length, (index) {
                    final config = configs[index];
                    final isSelected = config.id == configs.first.id;

                    return Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            )
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          unawaited(
                            ref
                                .read(configControllerProvider.notifier)
                                .select(config.id),
                          );
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.dns_rounded,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainer,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.outline
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Text(
                                            config.type.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        if (config.ping > 0) ...[
                                          const Gap(8),
                                          Icon(
                                            Icons.signal_cellular_alt,
                                            size: 12,
                                            color: _pingColor(
                                              config.ping,
                                              tokens,
                                            ),
                                          ),
                                          const Gap(2),
                                          Text(
                                            '${config.ping}ms',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _pingColor(
                                                config.ping,
                                                tokens,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).expand((widget) => [widget, const Gap(8)]).toList()
                  ..removeLast(), 
          ),
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
    );
  }

  Color _pingColor(int ping, AppTokens tokens) {
    if (ping < 100) return tokens.status.success;
    if (ping < 300) return tokens.status.warning;
    return tokens.status.danger;
  }
}
