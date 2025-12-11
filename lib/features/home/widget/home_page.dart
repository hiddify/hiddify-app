import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/logger/log_viewer_page.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/config/widget/add_config_sheet.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Helper to show error dialog
void _showErrorDialog(BuildContext context, String error) {
  unawaited(showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
      title: const Text('Connection Error'),
      content: SingleChildScrollView(
        child: SelectableText(error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  ));
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final connectionState = ref.watch(connectionProvider);
    final configsAsync = ref.watch(configControllerProvider);

    // Listen for errors and show SnackBar
    ref.listen<ConnectionStatus>(connectionProvider, (previous, next) {
      if (next == ConnectionStatus.error) {
        final errorMsg = ref.read(lastConnectionErrorProvider);
        if (errorMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  _showErrorDialog(context, errorMsg);
                },
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Config Selector Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildConfigSelector(context, configsAsync, colorScheme),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                const Spacer(),

                // Connection Button
                _buildConnectionButton(
                  context,
                  ref,
                  connectionState,
                  configsAsync,
                  colorScheme,
                ),

                const Spacer(),

                // Stats Row
                _buildStatsRow(connectionState, colorScheme)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Action Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Add Config Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              showDragHandle: true,
                              builder: (_) => const AddConfigSheet(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Config'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Logs Button
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LogViewerPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.terminal_rounded),
                        label: const Text('Logs'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigSelector(
    BuildContext context,
    AsyncValue<List<Config>> configsAsync,
    ColorScheme colorScheme,
  ) => configsAsync.when(
      data: (configs) {
        if (configs.isEmpty) {
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No configurations yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a config to start connecting',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final currentConfig = configs.first;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // TODO: Show config selector
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentConfig.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentConfig.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.signal_cellular_alt_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${currentConfig.ping}ms',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error: $e'),
        ),
      ),
    );

  Widget _buildConnectionButton(
    BuildContext context,
    WidgetRef ref,
    ConnectionStatus connectionState,
    AsyncValue<List<Config>> configsAsync,
    ColorScheme colorScheme,
  ) {
    final buttonColor = _getButtonColor(connectionState);
    final isConnecting = connectionState == ConnectionStatus.connecting;

    return GestureDetector(
      onTap: () {
        final configs = configsAsync.asData?.value;
        final configList = configs;
        if (configList != null && configList.isNotEmpty) {
          final notifier = ref.read(connectionProvider.notifier);
          if (connectionState == ConnectionStatus.disconnected ||
              connectionState == ConnectionStatus.error) {
            unawaited(notifier.connect(configList.first));
            } else if (connectionState == ConnectionStatus.connected ||
              connectionState == ConnectionStatus.connecting) {
            unawaited(notifier.disconnect());
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please add a config first'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              buttonColor,
              buttonColor.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.2),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isConnecting)
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Assets.images.logo.svg(
                  width: 70,
                  height: 70,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getStatusText(connectionState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildStatsRow(ConnectionStatus connectionState, ColorScheme colorScheme) {
    final isConnected = connectionState == ConnectionStatus.connected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.arrow_upward_rounded,
              label: 'Upload',
              value: isConnected ? '0 KB/s' : '--',
              colorScheme: colorScheme,
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Icons.arrow_downward_rounded,
              label: 'Download',
              value: isConnected ? '0 KB/s' : '--',
              colorScheme: colorScheme,
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: isConnected ? '00:00:00' : '--',
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return const Color(0xFF22C55E);
      case ConnectionStatus.connecting:
        return const Color(0xFFF97316);
      case ConnectionStatus.error:
        return const Color(0xFFEF4444);
      case ConnectionStatus.disconnected:
        return const Color(0xFF4A4D8B);
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING...';
      case ConnectionStatus.error:
        return 'ERROR';
      case ConnectionStatus.disconnected:
        return 'TAP TO CONNECT';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
}
