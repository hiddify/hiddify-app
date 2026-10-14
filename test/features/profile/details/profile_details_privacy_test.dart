import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/analytics/analytics_filter.dart' as analytics;
import 'package:hiddify/core/analytics/analytics_logger.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/details/profile_details_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:toastification/toastification.dart';

// Artificial markers only; the repository/core boundary never reads user files.
const _canaries = ['fixture-vless-credential', 'fixture-proxy-password', 'fixture-endpoint-private-key'];
const _safeDiagnostic = 'synthetic profile diagnostic probe';
final _outbounds = [
  {'type': 'vless', 'tag': 'fixture-vless', 'server': 'vpn.example.invalid', 'uuid': _canaries[0]},
  {'type': 'shadowsocks', 'tag': 'fixture-proxy', 'server': 'proxy.example.invalid', 'password': _canaries[1]},
];
final _endpoints = [
  {'type': 'wireguard', 'tag': 'fixture-endpoint', 'private_key': _canaries[2]},
];
final _configuration = jsonEncode({
  'outbounds': [
    ..._outbounds,
    {'type': 'selector', 'tag': 'fixture-selector'},
    {'type': 'direct', 'tag': 'direct'},
  ],
  'endpoints': _endpoints,
});

class _SyntheticProfiles implements ProfileRepository {
  _SyntheticProfiles({this.generationFails = false, String? content}) : content = content ?? _configuration;

  final bool generationFails;
  final String content;
  int rawReads = 0;
  final saved = <(ProfileEntity, String)>[];
  final profile = ProfileEntity.local(
    id: 'synthetic-profile',
    active: false,
    name: 'Offline diagnostic fixture',
    lastUpdate: DateTime.utc(2026, 10, 14),
  );

  @override
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id) => TaskEither.right(profile);

  @override
  TaskEither<ProfileFailure, String> generateConfig(String id) => generationFails
      ? TaskEither.left(ProfileFailure.unexpected(StateError('synthetic converter unavailable')))
      : TaskEither.right(content);

  @override
  TaskEither<ProfileFailure, String> getRawConfig(String id) => TaskEither(() async {
    rawReads++;
    return right(content);
  });

  @override
  TaskEither<ProfileFailure, Unit> offlineUpdate(ProfileEntity profile, String content) => TaskEither(() async {
    saved.add((profile, content));
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SuccessNotifications extends InAppNotificationController {
  final messages = <String>[];

  @override
  ToastificationItem? showSuccessToast(String message) {
    messages.add(message);
    return null;
  }
}

class _MemoryTransport implements Transport {
  final payloads = <String>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    for (final item in envelope.items) {
      if (item.header.type == 'event') {
        payloads.add(utf8.decode(await item.dataFactory()));
      }
    }
    return envelope.header.eventId;
  }
}

class _RecordingPrinter extends LoggyPrinter {
  _RecordingPrinter(this.integration);

  final SentryLoggyIntegration integration;
  final records = <LogRecord>[];
  final pending = <Future<void>>[];

  @override
  void onLog(LogRecord record) {
    records.add(record);
    pending.add(integration.onLog(record));
  }

  Future<void> flush() async {
    while (pending.isNotEmpty) {
      final batch = List<Future<void>>.of(pending);
      pending.clear();
      await Future.wait(batch);
    }
  }

  String get recordContent =>
      records.map((record) => '${record.message}\n${record.object}\n${record.error}\n${record.stackTrace}').join('\n');
}

class _OfflineDiagnostics {
  _OfflineDiagnostics() {
    options = SentryOptions(dsn: 'https://fixture-public-key@example.invalid/1')
      ..transport = transport
      ..beforeSend = analytics.sentryBeforeSend;
    hub = Hub(options);
    final integration = SentryLoggyIntegration();
    integration(hub, options);
    printer = _RecordingPrinter(integration);
    Loggy.initLoggy(logPrinter: printer);
  }

  final transport = _MemoryTransport();
  late final SentryOptions options;
  late final Hub hub;
  late final _RecordingPrinter printer;

  Future<void> captureSafeProbe() async {
    await printer.flush();
    Loggy('privacy-probe').error(_safeDiagnostic, StateError('synthetic failure'));
    await printer.flush();
  }

  Future<void> close() async {
    await printer.flush();
    Loggy('').clearListeners();
    await hub.close();
  }
}

void _expectNoConfigurationInDiagnostics(_OfflineDiagnostics diagnostics) {
  // Read the serialized event envelope, after the real Hub and beforeSend.
  expect(diagnostics.transport.payloads, isNotEmpty);
  final serialized = diagnostics.transport.payloads.join('\n');
  expect(serialized, contains(_safeDiagnostic));
  for (final marker in _canaries) {
    expect(
      {'localLog': diagnostics.printer.recordContent.contains(marker), 'eventEnvelope': serialized.contains(marker)},
      {'localLog': false, 'eventEnvelope': false},
      reason: 'configuration must stay in the editor, outside diagnostic sinks',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _OfflineDiagnostics diagnostics;
  late ProviderContainer container;
  late _SuccessNotifications notifications;
  int networkAttempts = 0;

  Future<T> offline<T>(Future<T> Function() operation) => HttpOverrides.runZoned(
    operation,
    createHttpClient: (_) {
      networkAttempts++;
      throw StateError('HTTP disabled in offline privacy fixture');
    },
  );

  Future<void> open(_SyntheticProfiles repository) async {
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWith((ref) => repository),
        translationsProvider.overrideWith((ref) => AppLocale.en.buildSync()),
        inAppNotificationControllerProvider.overrideWith((ref) => notifications),
      ],
    );
    await container.read(profileRepositoryProvider.future);
    await container.read(profileDetailsNotifierProvider(repository.profile.id).future);
  }

  setUp(() {
    networkAttempts = 0;
    diagnostics = _OfflineDiagnostics();
    notifications = _SuccessNotifications();
  });
  tearDown(() async {
    container.dispose();
    await diagnostics.close();
    expect(networkAttempts, 0);
  });

  for (final fallback in [false, true]) {
    test(
      '${fallback ? 'raw fallback' : 'generated'} profile credentials stay in editor and out of diagnostics',
      () async {
        await offline(() async {
          final repository = _SyntheticProfiles(generationFails: fallback);
          await open(repository);
          final details = container.read(profileDetailsNotifierProvider(repository.profile.id)).requireValue;
          expect(jsonDecode(details.configContent), {'outbounds': _outbounds, 'endpoints': _endpoints});
          expect(details.profile, repository.profile);
          expect(details.isDetailsChanged, isFalse);
          expect(details.isLoading, isFalse);
          expect(repository.rawReads, fallback ? 1 : 0);
          if (fallback) {
            expect(
              diagnostics.printer.records.any(
                (record) => record.message.startsWith('Error generating config for profile'),
              ),
              isTrue,
            );
          }
          await diagnostics.captureSafeProbe();
          _expectNoConfigurationInDiagnostics(diagnostics);
        });
      },
    );
  }

  test('editing a loaded profile preserves the draft and marks it changed without logging credentials', () async {
    await offline(() async {
      final repository = _SyntheticProfiles();
      await open(repository);
      final draft = jsonEncode({'outbounds': _outbounds.reversed.toList(), 'endpoints': _endpoints});
      container.read(profileDetailsNotifierProvider(repository.profile.id).notifier).setContent(draft);
      final details = container.read(profileDetailsNotifierProvider(repository.profile.id)).requireValue;
      expect(details.configContent, draft);
      expect(details.profile, repository.profile);
      expect(details.isDetailsChanged, isTrue);
      await diagnostics.captureSafeProbe();
      _expectNoConfigurationInDiagnostics(diagnostics);
    });
  });

  test('saving an edited profile forwards its exact draft once without exposing credentials', () async {
    await offline(() async {
      final repository = _SyntheticProfiles();
      await open(repository);
      final draft = jsonEncode({'outbounds': _outbounds.reversed.toList(), 'endpoints': _endpoints});
      final notifier = container.read(profileDetailsNotifierProvider(repository.profile.id).notifier);
      notifier.setContent(draft);
      expect(await notifier.save(), isTrue);
      expect(repository.saved, [(repository.profile, draft)]);
      expect(notifications.messages, hasLength(1));
      final details = container.read(profileDetailsNotifierProvider(repository.profile.id)).requireValue;
      expect(details.configContent, draft);
      expect(details.isLoading, isFalse);
      await diagnostics.captureSafeProbe();
      _expectNoConfigurationInDiagnostics(diagnostics);
    });
  });

  test('malformed synthetic JSON preserves editable content and useful parse failure diagnostics', () async {
    await offline(() async {
      const malformed = '{"outbounds": [}';
      final repository = _SyntheticProfiles(content: malformed);
      await open(repository);
      final details = container.read(profileDetailsNotifierProvider(repository.profile.id)).requireValue;
      expect(details.configContent, malformed);
      expect(repository.rawReads, 0);
      expect(
        diagnostics.printer.records.any(
          (record) => record.message == 'Error parsing profile-content JSON' && record.error is FormatException,
        ),
        isTrue,
      );
      await diagnostics.captureSafeProbe();
      expect(diagnostics.transport.payloads.join('\n'), contains('Error parsing profile-content JSON'));
    });
  });
}
