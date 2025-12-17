import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesPage extends HookConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(configControllerProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Profiles'), centerTitle: false),

          configsAsync.when(
            data: (configs) {
              if (configs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'No Profiles Found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Add a new profile to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final config = configs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          unawaited(
                            ref
                                .read(configControllerProvider.notifier)
                                .select(config.id),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected ${config.name}')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _buildPingIndicator(config.ping, theme, tokens),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
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
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            config.type.toUpperCase(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                        const Gap(8),
                                        Text(
                                          '${config.ping} ms',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.outline,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute<void>(
                                          builder: (ctx) =>
                                              ConfigEditorPage(config: config),
                                        ),
                                      )
                                      .then((saved) {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: theme.colorScheme.error,
                                onPressed: () =>
                                    _deleteConfig(context, ref, config.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: configs.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(child: Text('Error loading profiles: $e')),
            ),
          ),

          const SliverGap(80), 
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddConfigSheet.show(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Profile'),
      ),
    );
  }

  Widget _buildPingIndicator(int ping, ThemeData theme, AppTokens tokens) {
    Color color;
    if (ping <= 0) {
      color = theme.colorScheme.outline;
    } else if (ping < 300) {
      color = tokens.status.success;
    } else if (ping < 600) {
      color = tokens.status.warning;
    } else {
      color = tokens.status.danger;
    }

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _deleteConfig(BuildContext context, WidgetRef ref, String id) {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Profile'),
          content: const Text('Are you sure you want to delete this profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                unawaited(
                  ref.read(configControllerProvider.notifier).remove(id),
                );
                Navigator.pop(context);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
