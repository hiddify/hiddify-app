import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hiddify/features/connection/connection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConfigCard extends HookConsumerWidget {
  const ConfigCard({required this.configsAsync, required this.t, super.key});

  final AsyncValue<List<Config>> configsAsync;
  final TranslationsEn t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return configsAsync.when(
      data: (configs) {
        if (configs.isEmpty) {
          return _buildEmptyCard(context, colors, tokens);
        }
        return _buildConfigCard(context, configs.first, colors, tokens);
      },
      loading: () => _buildLoadingCard(tokens),
      error: (e, _) => _buildErrorCard(e, colors),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    ColorScheme colors,
    AppTokens tokens,
  ) => Card(
    color: tokens.surface.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(tokens.radius.md),
      onTap: () => AddConfigSheet.show(context),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.x5),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: colors.primary, size: 28),
            Gap(tokens.spacing.x4),
            Expanded(
              child: Text(
                t.home.addFirstConfig,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  Widget _buildConfigCard(
    BuildContext context,
    Config config,
    ColorScheme colors,
    AppTokens tokens,
  ) => Card(
    color: tokens.surface.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(tokens.radius.md),
      onTap: () => ConfigSelectorSheet.show(context),
      onLongPress: () {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CoreConfigViewer(config: config),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.x4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(tokens.radius.sm),
              ),
              child: Icon(Icons.dns_rounded, color: colors.primary, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          config.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (config.ping > 0) ...[
                        const Gap(10),
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 14,
                          color: _pingColor(config.ping, tokens),
                        ),
                        const Gap(4),
                        Text(
                          '${config.ping}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: _pingColor(config.ping, tokens),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.unfold_more, color: colors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    ),
  );

  Widget _buildLoadingCard(AppTokens tokens) => Card(
    color: tokens.surface.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
    child: const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );

  Widget _buildErrorCard(Object error, ColorScheme colors) => Card(
    color: colors.errorContainer.withValues(alpha: 0.35),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Error: $error', style: TextStyle(color: colors.error)),
    ),
  );

  Color _pingColor(int ping, AppTokens tokens) {
    if (ping < 100) return tokens.status.success;
    if (ping < 300) return tokens.status.warning;
    return tokens.status.danger;
  }
}
