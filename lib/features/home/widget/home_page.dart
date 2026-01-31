import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hiddify/features/connection/connection.dart';
import 'package:hiddify/features/home/widget/widgets/widgets.dart';
import 'package:hiddify/features/settings/settings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final t = ref.watch(translationsProvider);

    final connectionState = ref.watch(connectionProvider);
    final configsAsync = ref.watch(configControllerProvider);

    ref.listen<ConnectionStatus>(connectionProvider, (prev, next) {
      if (next == ConnectionStatus.error) {
        final error = ref.read(lastConnectionErrorProvider);
        if (error != null) {
          final coreMode = ref.read(CorePreferences.coreMode);
          final p = ErrorHandler.presentConnectionError(
            t: t,
            rawError: error,
            coreMode: coreMode,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.toSnackBarMessage(p, t)),
              backgroundColor: tokens.status.danger,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: t.logs.pageTitle,
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LogViewerPage(),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: tokens.surface.scaffold,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverGap(tokens.spacing.x4),
            SliverPadding(
              padding: tokens.spacing.pagePadding,
              sliver: SliverToBoxAdapter(
                child: ConfigCard(configsAsync: configsAsync, t: t),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: tokens.spacing.pagePadding,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    if (connectionState == ConnectionStatus.connected)
                      const LiveConnectionTimer().animate().fadeIn(
                        duration: 300.ms,
                      ),
                    if (connectionState == ConnectionStatus.connected)
                      const Gap(20),
                    ConnectionButton(
                      state: connectionState,
                      onTap: () => _handleConnectionTap(
                        context,
                        ref,
                        connectionState,
                        configsAsync,
                      ),
                      t: t,
                    ),
                    const Spacer(flex: 3),
                    LiveStatsSection(
                      t: t,
                      isConnected:
                          connectionState == ConnectionStatus.connected,
                    ),
                    const Gap(24),
                    BottomActions(t: t),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleConnectionTap(
    BuildContext context,
    WidgetRef ref,
    ConnectionStatus state,
    AsyncValue<List<Config>> configsAsync,
  ) {
    final configs = configsAsync.asData?.value;
    if (configs == null || configs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(translationsProvider).home.noConfigError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final notifier = ref.read(connectionProvider.notifier);
    if (state == ConnectionStatus.disconnected ||
        state == ConnectionStatus.error) {
      unawaited(notifier.connect(configs.first));
    } else {
      unawaited(notifier.disconnect());
    }
  }
}
