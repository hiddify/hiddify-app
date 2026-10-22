import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/analytics/telemetry_delivery_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hiddify/features/diagnostics/telemetry_delivery_labels.dart';
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
    final pingTrace = ref.watch(iosPingTraceProvider);
    final pingSnapshot = useStream(pingTrace.changes, initialData: pingTrace.snapshot).data ?? pingTrace.snapshot;
    final events = useStream(journal.changes, initialData: journal.events).data ?? journal.events;
    final delivery = ref.watch(telemetryDeliveryStatusProvider).valueOrNull ?? const TelemetryDeliveryStatus.disabled();
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    final message = useState<String?>(null);
    final sendingTest = useState(false);
    final followTest = useState(false);
    final liveTestOutcome = delivery.lastTestOutcome;
    final displayedMessage = followTest.value && !sendingTest.value && liveTestOutcome != null
        ? testOutcomeLabel(liveTestOutcome, russian: russian)
        : message.value;
    final refresh = useState(0);
    final preview = journal.exportJson(
      version: metadata.version,
      buildNumber: metadata.buildNumber,
      homePresentation: homePresentation,
      iosPing: pingSnapshot,
      telemetryDelivery: delivery,
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
        followTest.value = false;
        message.value = t.copySuccess;
      } on Object {
        if (!context.mounted) return;
        followTest.value = false;
        message.value = t.copyError;
      }
    }

    Future<void> clearReport() async {
      journal.clear();
      pingTrace.clear();
      await journal.flush();
      if (context.mounted) {
        followTest.value = false;
        refresh.value++;
      }
    }

    return BlizzardPresentation(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.title),
          actions: [
            IconButton(
              key: const Key('safe-diagnostics-send-test'),
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: russian ? 'Отправить тестовое событие' : 'Send test event',
              onPressed: sendingTest.value
                  ? null
                  : () async {
                      sendingTest.value = true;
                      followTest.value = false;
                      message.value = russian ? 'Проверяем отправку…' : 'Checking delivery…';
                      try {
                        final result = await ref.read(analyticsControllerProvider.notifier).sendTestEvent();
                        if (context.mounted) {
                          message.value = testOutcomeLabel(result.outcome, russian: russian);
                          followTest.value = switch (result.outcome) {
                            TelemetryTestOutcome.pending ||
                            TelemetryTestOutcome.persisted ||
                            TelemetryTestOutcome.budgetLimited ||
                            TelemetryTestOutcome.budgetStateInvalid ||
                            TelemetryTestOutcome.budgetStorageFailed ||
                            TelemetryTestOutcome.outboxStorageFailed => true,
                            _ => false,
                          };
                        }
                      } on Object {
                        if (context.mounted) {
                          message.value = russian
                              ? 'Не удалось завершить проверку отправки'
                              : 'Could not complete the delivery test';
                        }
                      } finally {
                        if (context.mounted) sendingTest.value = false;
                      }
                    },
            ),
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
              const SizedBox(height: 16),
              _DeliveryCard(status: delivery, russian: russian),
              if (events.isEmpty && pingSnapshot.events.isEmpty) ...[const SizedBox(height: 16), Text(t.empty)],
              if (journal.persistenceFailed) ...[
                const SizedBox(height: 16),
                Text(t.storageError, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (displayedMessage case final value?) ...[const SizedBox(height: 16), Text(value)],
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

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.status, required this.russian});
  final TelemetryDeliveryStatus status;
  final bool russian;

  @override
  Widget build(BuildContext context) {
    String text(String en, String ru) => russian ? ru : en;
    String time(DateTime date) => '${date.toUtc().toIso8601String().replaceFirst('T', ' ').substring(0, 19)} UTC';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text('Remote delivery', 'Удалённая отправка'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(deliveryStateLabel(status.state, russian: russian), key: const Key('telemetry-delivery-status')),
            const SizedBox(height: 8),
            Text('${text('Queue', 'В очереди')}: ${status.pendingCount}'),
            if (status.oldestPendingAgeSeconds case final age?)
              Text('${text('Oldest event age', 'Возраст старейшего события')}: $age ${text('sec', 'сек')}'),
            Text(
              '${text('Spent today', 'Израсходовано за сутки')}: ${status.budgetUsedBytes} ${text('bytes', 'байт')}',
            ),
            Text('${text('Remaining', 'Осталось')}: ${status.budgetRemainingBytes} ${text('bytes', 'байт')}'),
            if (status.nextAttemptAt case final date?)
              Text('${text('Next attempt no earlier than', 'Следующая попытка не раньше')}: ${time(date)}'),
            if (status.lastAttemptAt case final date?)
              Text('${text('Last request', 'Последний запрос')}: ${time(date)}'),
            if (status.lastHttpCode case final code?) Text('HTTP: $code'),
            if (status.attemptStorageState != TelemetryAttemptStorageState.unconfigured)
              Text(
                '${text('Receipt', 'Квитанция')}: ${attemptStorageLabel(status.attemptStorageState, russian: russian)}',
              ),
            if (status.lastAttempt case final attempt?) ...[
              Text('${text('Attempt build', 'Сборка запроса')}: ${attempt.appVersion} (${attempt.buildNumber})'),
              Text(
                '${text('Request stage', 'Стадия запроса')}: ${attempt.stage == TelemetryTransportStage.beforeRequest ? text('Started', 'Начат') : text('Completed', 'Завершён')}',
              ),
              if (attempt.outcome case final outcome?)
                Text(
                  '${text('Request result', 'Результат запроса')}: ${transportOutcomeLabel(outcome, russian: russian)}',
                ),
            ],
            if (status.testAttemptStorageState != TelemetryAttemptStorageState.unconfigured)
              Text(
                '${text('Test receipt', 'Квитанция теста')}: ${attemptStorageLabel(status.testAttemptStorageState, russian: russian)}',
              ),
            if (status.lastTestAttempt case final attempt?) ...[
              Text('${text('Test event', 'Тестовое событие')}: ${attempt.testEventId}'),
              Text('${text('Test request', 'Запрос теста')}: ${time(attempt.attemptedAt)}'),
              if (attempt.outcome case final outcome?)
                Text('${text('Test result', 'Результат теста')}: ${transportOutcomeLabel(outcome, russian: russian)}'),
              if (attempt.httpCode case final code?) Text('HTTP (${text('test', 'тест')}): $code'),
              Text(
                '${text('Test event accepted', 'Тестовое событие принято')}: ${attempt.ackOwnEvent == true ? text('Yes', 'Да') : text('No', 'Нет')}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
