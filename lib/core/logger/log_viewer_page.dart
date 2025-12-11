import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced Log Viewer with live updates and utility buttons
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _autoScroll = true;
  bool _isLogging = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Logs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'App', icon: Icon(Icons.phone_android, size: 18)),
            Tab(text: 'Core', icon: Icon(Icons.memory, size: 18)),
            Tab(text: 'Access', icon: Icon(Icons.swap_horiz, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(context, colorScheme),
          // Log content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AppLogsTab(colorScheme: colorScheme, autoScroll: _autoScroll, isLogging: _isLogging),
                _CoreLogsTab(colorScheme: colorScheme),
                _AccessLogsTab(colorScheme: colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ColorScheme colorScheme) {
    return Consumer(
      builder: (context, ref, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(coreLogsProvider);
                ref.invalidate(accessLogsProvider);
              },
            ),
            // Clear
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 20),
              tooltip: 'Clear Logs',
              onPressed: () => _showClearDialog(context, ref),
            ),
            const VerticalDivider(width: 16),
            // Auto scroll toggle
            IconButton(
              icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center, size: 20),
              tooltip: _autoScroll ? 'Auto Scroll: ON' : 'Auto Scroll: OFF',
              color: _autoScroll ? colorScheme.primary : null,
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
            ),
            // Pause/Resume logging
            IconButton(
              icon: Icon(_isLogging ? Icons.pause : Icons.play_arrow, size: 20),
              tooltip: _isLogging ? 'Pause Logging' : 'Resume Logging',
              color: _isLogging ? null : colorScheme.error,
              onPressed: () => setState(() => _isLogging = !_isLogging),
            ),
            const Spacer(),
            // Open folder
            IconButton(
              icon: const Icon(Icons.folder_open, size: 20),
              tooltip: 'Open Log Folder',
              onPressed: () async {
                final dir = await ref.read(logServiceProvider).getLogDirectory();
                if (Platform.isWindows) {
                  unawaited(Process.run('explorer', [dir]));
                } else {
                  unawaited(launchUrl(Uri.file(dir)));
                }
              },
            ),
            // Copy all
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy All Logs',
              onPressed: () async {
                final logs = await ref.read(logServiceProvider).readCoreLogs();
                final text = logs.map((e) => '${e.formattedTime} [${e.level.label}] ${e.message}').join('\n');
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs copied to clipboard')),
                  );
                }
              },
            ),
            // Export/Share
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              tooltip: 'Export Logs',
              onPressed: () => ref.read(logServiceProvider).exportLogs(),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    unawaited(showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              unawaited(ref.read(logServiceProvider).clearLogs());
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    ));
  }
}

class _AppLogsTab extends HookConsumerWidget {
  const _AppLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logStream = ref.watch(logStreamProvider);

    return logStream.when(
      data: (logs) {
        if (!isLogging) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pause_circle_outline, size: 48, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text('Logging paused', style: TextStyle(color: colorScheme.outline)),
              ],
            ),
          );
        }
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 48, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text('No app logs yet', style: TextStyle(color: colorScheme.outline)),
                const SizedBox(height: 8),
                Text('Logs will appear here', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: logs.length,
          reverse: autoScroll,
          itemBuilder: (context, index) {
            final logIndex = autoScroll ? logs.length - 1 - index : index;
            return _LogTile(log: logs[logIndex], colorScheme: colorScheme);
          },
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('Waiting for logs...', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CoreLogsTab extends HookConsumerWidget {
  const _CoreLogsTab({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreLogsStream = ref.watch(coreLogsStreamProvider);

    return coreLogsStream.when(
      data: (logs) => logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.memory, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No core logs', style: TextStyle(color: colorScheme.outline)),
                  const SizedBox(height: 8),
                  Text('Connect to generate logs', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              reverse: true,
              itemBuilder: (context, index) => _LogEntryTile(
                entry: logs[logs.length - 1 - index],
                colorScheme: colorScheme,
              ),
            ),
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading core logs...', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _AccessLogsTab extends HookConsumerWidget {
  const _AccessLogsTab({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessLogsStream = ref.watch(accessLogsStreamProvider);

    return accessLogsStream.when(
      data: (logs) => logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No access logs', style: TextStyle(color: colorScheme.outline)),
                  const SizedBox(height: 8),
                  Text('Traffic logs will appear here', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              reverse: true,
              itemBuilder: (context, index) => _LogEntryTile(
                entry: logs[logs.length - 1 - index],
                colorScheme: colorScheme,
              ),
            ),
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading access logs...', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.colorScheme});
  final String log;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        unawaited(Clipboard.setData(ClipboardData(text: log)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          log,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry, required this.colorScheme});
  final LogEntry entry;
  final ColorScheme colorScheme;

  Color get levelColor {
    switch (entry.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.none:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        unawaited(Clipboard.setData(ClipboardData(text: entry.message)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.formattedTime,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.level.label.substring(0, 1),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final logStreamProvider = StreamProvider<List<String>>(
  (ref) => ref.read(logServiceProvider).streamLogs(),
);

final coreLogsProvider = FutureProvider<List<LogEntry>>(
  (ref) => ref.read(logServiceProvider).readCoreLogs(),
);

final accessLogsProvider = FutureProvider<List<LogEntry>>(
  (ref) => ref.read(logServiceProvider).readAccessLogs(),
);

/// Real-time core logs stream provider
final coreLogsStreamProvider = StreamProvider<List<LogEntry>>(
  (ref) => ref.read(logServiceProvider).watchCoreLogs(),
);

/// Real-time access logs stream provider
final accessLogsStreamProvider = StreamProvider<List<LogEntry>>(
  (ref) => ref.read(logServiceProvider).watchAccessLogs(),
);
