import 'package:flutter/material.dart';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogViewerPage extends HookConsumerWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logStream = ref.watch(logStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => ref.read(logServiceProvider).clearLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ref.read(logServiceProvider).exportLogs(),
          ),
        ],
      ),
      body: logStream.when(
        data: (logs) => ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) => Text(
                logs[index], 
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
          ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

final logStreamProvider = StreamProvider<List<String>>((ref) => ref.read(logServiceProvider).streamLogs());
