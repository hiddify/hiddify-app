import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';

String deliveryStateLabel(TelemetryDeliveryState state, {required bool russian}) {
  final (en, ru) = switch (state) {
    TelemetryDeliveryState.disabled => ('Disabled', 'Выключена'),
    TelemetryDeliveryState.idle => ('Ready to send', 'Готова к отправке'),
    TelemetryDeliveryState.pending => ('Waiting to send', 'Ожидает отправки'),
    TelemetryDeliveryState.sending => ('Sending', 'Отправка'),
    TelemetryDeliveryState.retryWaiting => ('Waiting to retry', 'Ожидает повторной попытки'),
    TelemetryDeliveryState.budgetLimited => ('Daily limit reached', 'Суточный лимит исчерпан'),
    TelemetryDeliveryState.budgetStateInvalid => (
      'Saved budget could not be read',
      'Не удалось прочитать сохранённый бюджет',
    ),
    TelemetryDeliveryState.budgetStorageFailed => (
      'Local budget could not be saved',
      'Не удалось сохранить бюджет на устройстве',
    ),
    TelemetryDeliveryState.outboxStorageFailed => ('Local storage unavailable', 'Локальное хранилище недоступно'),
    TelemetryDeliveryState.accepted => ('Last batch accepted by the ingest server', 'Последний пакет принят сервером'),
    TelemetryDeliveryState.rejected => ('Ingest server rejected the request', 'Сервер отклонил запрос'),
    TelemetryDeliveryState.droppedExpired => ('Queued events expired', 'Истёк срок хранения событий'),
    TelemetryDeliveryState.droppedOverflow => ('Queue capacity reached', 'Достигнут предел очереди'),
  };
  return russian ? ru : en;
}

String testOutcomeLabel(TelemetryTestOutcome outcome, {required bool russian}) {
  final (en, ru) = switch (outcome) {
    TelemetryTestOutcome.disabled => ('Remote diagnostics are disabled', 'Удалённая диагностика выключена'),
    TelemetryTestOutcome.persisted ||
    TelemetryTestOutcome.pending => ('Saved locally; waiting to send', 'Сохранено на устройстве; ожидает отправки'),
    TelemetryTestOutcome.accepted => ('Ingest server accepted the test event', 'Сервер приёма принял тестовое событие'),
    TelemetryTestOutcome.budgetLimited => (
      'Daily limit reached; test is waiting',
      'Суточный лимит исчерпан; тест ожидает отправки',
    ),
    TelemetryTestOutcome.budgetStateInvalid => (
      'Saved budget could not be read',
      'Не удалось прочитать сохранённый бюджет',
    ),
    TelemetryTestOutcome.budgetStorageFailed => (
      'Local budget could not be saved',
      'Не удалось сохранить бюджет на устройстве',
    ),
    TelemetryTestOutcome.outboxStorageFailed => (
      'Local storage unavailable; test was not saved',
      'Хранилище недоступно; тест не сохранён',
    ),
    TelemetryTestOutcome.rejected => ('Ingest server rejected the test event', 'Сервер отклонил тестовое событие'),
    TelemetryTestOutcome.droppedExpired => (
      'Test event expired before sending',
      'Срок хранения тестового события истёк',
    ),
    TelemetryTestOutcome.droppedOverflow => (
      'Queue capacity reached; test was removed',
      'Очередь заполнена; тестовое событие удалено',
    ),
  };
  return russian ? ru : en;
}

String transportOutcomeLabel(TelemetryTransportOutcome outcome, {required bool russian}) {
  final (en, ru) = switch (outcome) {
    TelemetryTransportOutcome.http => ('HTTP response received', 'Получен ответ HTTP'),
    TelemetryTransportOutcome.timeout => ('Timed out', 'Таймаут'),
    TelemetryTransportOutcome.network => ('Network error', 'Сетевая ошибка'),
    TelemetryTransportOutcome.tls => ('Secure connection error', 'Ошибка защищённого соединения'),
    TelemetryTransportOutcome.other => ('Other transport error', 'Другая ошибка отправки'),
  };
  return russian ? ru : en;
}

String attemptStorageLabel(TelemetryAttemptStorageState state, {required bool russian}) {
  final (en, ru) = switch (state) {
    TelemetryAttemptStorageState.unconfigured => ('Not configured', 'Не настроено'),
    TelemetryAttemptStorageState.pending => ('Saving on this device', 'Сохраняется на устройстве'),
    TelemetryAttemptStorageState.persisted => ('Saved on this device', 'Сохранено на устройстве'),
    TelemetryAttemptStorageState.failed => ('Could not save on this device', 'Не удалось сохранить на устройстве'),
  };
  return russian ? ru : en;
}
