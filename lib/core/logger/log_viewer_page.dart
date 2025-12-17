import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/log_bus.dart';
import 'package:hiddify/core/logger/log_bus_providers.dart';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _autoScroll = true;
  bool _isLogging = true;

  List<LogEvent> _pausedEvents = const <LogEvent>[];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sourceFilter;
  final Set<LogSeverity> _severityFilter = LogSeverity.values.toSet();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'App', icon: Icon(Icons.phone_android, size: 18)),
            Tab(text: 'Core', icon: Icon(Icons.memory, size: 18)),
            Tab(text: 'Access', icon: Icon(Icons.swap_horiz, size: 18)),
            Tab(text: 'Process', icon: Icon(Icons.terminal_rounded, size: 18)),
            Tab(text: 'System', icon: Icon(Icons.settings, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildToolbar(context, colorScheme),
          _buildFilters(colorScheme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AppLogsTab(
                  colorScheme: colorScheme,
                  autoScroll: _autoScroll,
                  isLogging: _isLogging,
                  frozenEvents: _isLogging ? null : _pausedEvents,
                  searchQuery: _searchQuery,
                  sourceFilter: _sourceFilter,
                  severityFilter: _severityFilter,
                ),
                _CoreLogsTab(
                  colorScheme: colorScheme,
                  autoScroll: _autoScroll,
                  isLogging: _isLogging,
                  frozenEvents: _isLogging ? null : _pausedEvents,
                  searchQuery: _searchQuery,
                  sourceFilter: _sourceFilter,
                  severityFilter: _severityFilter,
                ),
                _AccessLogsTab(
                  colorScheme: colorScheme,
                  autoScroll: _autoScroll,
                  isLogging: _isLogging,
                  frozenEvents: _isLogging ? null : _pausedEvents,
                  searchQuery: _searchQuery,
                  sourceFilter: _sourceFilter,
                  severityFilter: _severityFilter,
                ),
                _ProcessLogsTab(
                  colorScheme: colorScheme,
                  autoScroll: _autoScroll,
                  isLogging: _isLogging,
                  frozenEvents: _isLogging ? null : _pausedEvents,
                  searchQuery: _searchQuery,
                  sourceFilter: _sourceFilter,
                  severityFilter: _severityFilter,
                ),
                _SystemLogsTab(
                  colorScheme: colorScheme,
                  autoScroll: _autoScroll,
                  isLogging: _isLogging,
                  frozenEvents: _isLogging ? null : _pausedEvents,
                  searchQuery: _searchQuery,
                  sourceFilter: _sourceFilter,
                  severityFilter: _severityFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme colorScheme) => Consumer(
    builder: (context, ref, child) {
      final events = _isLogging
          ? ref
                .watch(logBusStreamProvider)
                .maybeWhen(
                  data: (events) => events,
                  orElse: () => const <LogEvent>[],
                )
          : _pausedEvents;

      final sources = <String>{
        for (final e in events)
          if (e.source.trim().isNotEmpty) e.source,
      }.toList()..sort();

      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _severityChip(colorScheme, LogSeverity.debug, 'D', Colors.grey),
                _severityChip(colorScheme, LogSeverity.info, 'I', Colors.blue),
                _severityChip(
                  colorScheme,
                  LogSeverity.warning,
                  'W',
                  Colors.orange,
                ),
                _severityChip(colorScheme, LogSeverity.error, 'E', Colors.red),
                if (sources.isNotEmpty)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _sourceFilter,
                      isDense: true,
                      hint: const Text('All sources'),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('All sources'),
                        ),
                        for (final s in sources)
                          DropdownMenuItem<String?>(value: s, child: Text(s)),
                      ],
                      onChanged: (value) =>
                          setState(() => _sourceFilter = value),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _severityChip(
    ColorScheme colorScheme,
    LogSeverity severity,
    String label,
    Color color,
  ) {
    final selected = _severityFilter.contains(severity);

    return FilterChip(
      label: Text(label, style: const TextStyle(fontFamily: 'monospace')),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.18),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontFamily: 'monospace',
        color: selected ? color : colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (value) {
        setState(() {
          if (value) {
            _severityFilter.add(severity);
          } else {
            _severityFilter.remove(severity);
          }
        });
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    ColorScheme colorScheme,
  ) => Consumer(
    builder: (context, ref, child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(logBusStreamProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, size: 20),
            tooltip: 'Clear Logs',
            onPressed: () => _showClearDialog(context, ref),
          ),
          const VerticalDivider(width: 16),
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
              size: 20,
            ),
            tooltip: _autoScroll ? 'Auto Scroll: ON' : 'Auto Scroll: OFF',
            color: _autoScroll ? colorScheme.primary : null,
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: Icon(_isLogging ? Icons.pause : Icons.play_arrow, size: 20),
            tooltip: _isLogging ? 'Pause Logging' : 'Resume Logging',
            color: _isLogging ? null : colorScheme.error,
            onPressed: () {
              setState(() {
                if (_isLogging) {
                  _pausedEvents = ref.read(logBusProvider).currentBuffer;
                } else {
                  _pausedEvents = const <LogEvent>[];
                }
                _isLogging = !_isLogging;
              });
            },
          ),
          const Spacer(),
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
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy All Logs',
            onPressed: () async {
              final logs = ref.read(logBusProvider).currentBuffer;
              final text = logs
                  .map(
                    (e) =>
                        '${e.timestamp.toIso8601String()} [${e.kind.name}] [${e.severity.name}] [${e.source}] ${e.message}',
                  )
                  .join('\n');
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            tooltip: 'Export Logs',
            onPressed: () => ref.read(logServiceProvider).exportLogs(),
          ),
        ],
      ),
    ),
  );

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    unawaited(
      showDialog<void>(
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
                setState(() => _pausedEvents = const <LogEvent>[]);
                unawaited(ref.read(logServiceProvider).clearLogs());
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEventTile extends StatelessWidget {
  const _LogEventTile({required this.event, required this.colorScheme});
  final LogEvent event;
  final ColorScheme colorScheme;

  Color get levelColor {
    switch (event.severity) {
      case LogSeverity.debug:
        return Colors.grey;
      case LogSeverity.info:
        return Colors.blue;
      case LogSeverity.warning:
        return Colors.orange;
      case LogSeverity.error:
        return Colors.red;
    }
  }

  String get formattedTime {
    final t = event.timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onLongPress: () {
      unawaited(Clipboard.setData(ClipboardData(text: event.message)));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedTime,
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
              event.severity.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              event.source,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.message,
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

class _LogBusKindTab extends HookConsumerWidget {
  const _LogBusKindTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.kind,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });

  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final LogKind kind;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget buildForEvents(List<LogEvent> events) {
      final query = searchQuery.trim().toLowerCase();

      final logs = events.where((e) {
        if (e.kind != kind) return false;
        if (!severityFilter.contains(e.severity)) return false;
        if (sourceFilter != null && e.source != sourceFilter) return false;
        if (query.isEmpty) return true;
        return e.message.toLowerCase().contains(query) ||
            e.source.toLowerCase().contains(query);
      }).toList();

      if (logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(emptyTitle, style: TextStyle(color: colorScheme.outline)),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: logs.length,
        reverse: autoScroll,
        itemBuilder: (context, index) {
          final logIndex = autoScroll ? logs.length - 1 - index : index;
          return _LogEventTile(event: logs[logIndex], colorScheme: colorScheme);
        },
      );
    }

    final frozen = frozenEvents;
    if (frozen != null) {
      return buildForEvents(frozen);
    }

    final busStream = ref.watch(logBusStreamProvider);

    return busStream.when(
      data: buildForEvents,
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Waiting for logs...',
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _AppLogsTab extends StatelessWidget {
  const _AppLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context) => _LogBusKindTab(
    colorScheme: colorScheme,
    autoScroll: autoScroll,
    isLogging: isLogging,
    frozenEvents: frozenEvents,
    kind: LogKind.app,
    emptyIcon: Icons.article_outlined,
    emptyTitle: 'No app logs yet',
    emptySubtitle: 'Logs will appear here',
    searchQuery: searchQuery,
    sourceFilter: sourceFilter,
    severityFilter: severityFilter,
  );
}

class _CoreLogsTab extends StatelessWidget {
  const _CoreLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context) => _LogBusKindTab(
    colorScheme: colorScheme,
    autoScroll: autoScroll,
    isLogging: isLogging,
    frozenEvents: frozenEvents,
    kind: LogKind.core,
    emptyIcon: Icons.memory,
    emptyTitle: 'No core logs',
    emptySubtitle: 'Connect to generate logs',
    searchQuery: searchQuery,
    sourceFilter: sourceFilter,
    severityFilter: severityFilter,
  );
}

class _AccessLogsTab extends StatelessWidget {
  const _AccessLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context) => _LogBusKindTab(
    colorScheme: colorScheme,
    autoScroll: autoScroll,
    isLogging: isLogging,
    frozenEvents: frozenEvents,
    kind: LogKind.access,
    emptyIcon: Icons.swap_horiz,
    emptyTitle: 'No access logs',
    emptySubtitle: 'Traffic logs will appear here',
    searchQuery: searchQuery,
    sourceFilter: sourceFilter,
    severityFilter: severityFilter,
  );
}

class _ProcessLogsTab extends StatelessWidget {
  const _ProcessLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context) => _LogBusKindTab(
    colorScheme: colorScheme,
    autoScroll: autoScroll,
    isLogging: isLogging,
    frozenEvents: frozenEvents,
    kind: LogKind.process,
    emptyIcon: Icons.terminal_rounded,
    emptyTitle: 'No process logs',
    emptySubtitle: 'tun2socks/hysteria logs will appear here',
    searchQuery: searchQuery,
    sourceFilter: sourceFilter,
    severityFilter: severityFilter,
  );
}

class _SystemLogsTab extends StatelessWidget {
  const _SystemLogsTab({
    required this.colorScheme,
    required this.autoScroll,
    required this.isLogging,
    required this.frozenEvents,
    required this.searchQuery,
    required this.sourceFilter,
    required this.severityFilter,
  });
  final ColorScheme colorScheme;
  final bool autoScroll;
  final bool isLogging;
  final List<LogEvent>? frozenEvents;
  final String searchQuery;
  final String? sourceFilter;
  final Set<LogSeverity> severityFilter;

  @override
  Widget build(BuildContext context) => _LogBusKindTab(
    colorScheme: colorScheme,
    autoScroll: autoScroll,
    isLogging: isLogging,
    frozenEvents: frozenEvents,
    kind: LogKind.system,
    emptyIcon: Icons.settings,
    emptyTitle: 'No system logs',
    emptySubtitle: 'System/bootstrap logs will appear here',
    searchQuery: searchQuery,
    sourceFilter: sourceFilter,
    severityFilter: severityFilter,
  );
}
