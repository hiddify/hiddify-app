import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef SafeDiagnosticCopy = Future<void> Function(String text);

class SafeDiagnosticsPage extends HookConsumerWidget {
  const SafeDiagnosticsPage({super.key, this.copyText});

  final SafeDiagnosticCopy? copyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue.pages.logs.safeDiagnostics;
    final journal = ref.watch(safeDiagnosticJournalProvider);
    final metadata = ref.watch(safeDiagnosticMetadataProvider);
    final homePresentation = ref.watch(homePresentationSnapshotProvider);
    final events = useStream(journal.changes, initialData: journal.events).data ?? journal.events;
    final message = useState<String?>(null);
    final refresh = useState(0);
    final preview = journal.exportJson(
      version: metadata.version,
      buildNumber: metadata.buildNumber,
      homePresentation: homePresentation,
    );

    useEffect(() {
      var cancelled = false;
      journal.flush().then((_) {
        if (!cancelled && context.mounted) refresh.value++;
      });
      return () => cancelled = true;
    }, [journal, events]);

    Future<void> copyReport() async {
      try {
        final copy = copyText ?? (text) => Clipboard.setData(ClipboardData(text: text));
        await copy(preview);
        if (!context.mounted) return;
        message.value = t.copySuccess;
      } on Object {
        if (!context.mounted) return;
        message.value = t.copyError;
      }
    }

    Future<void> clearReport() async {
      journal.clear();
      await journal.flush();
      if (context.mounted) refresh.value++;
    }

    return BlizzardPresentation(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.title),
          actions: [
            IconButton(
              key: const Key('safe-diagnostics-copy'),
              onPressed: copyReport,
              icon: const Icon(Icons.copy),
              tooltip: t.copy,
            ),
            IconButton(
              key: const Key('safe-diagnostics-clear'),
              onPressed: clearReport,
              icon: const Icon(Icons.delete_outline),
              tooltip: t.clear,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t.description),
              if (events.isEmpty) ...[const SizedBox(height: 16), Text(t.empty)],
              if (journal.persistenceFailed) ...[
                const SizedBox(height: 16),
                Text(t.storageError, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (message.value case final value?) ...[const SizedBox(height: 16), Text(value)],
              const SizedBox(height: 24),
              Text(t.preview, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(preview, key: const Key('safe-diagnostics-preview')),
            ],
          ),
        ),
      ),
    );
  }
}
