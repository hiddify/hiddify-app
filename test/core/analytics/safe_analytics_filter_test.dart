import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/analytics/analytics_filter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

const _hostileMarkers = <String>[
  'https://private.example.invalid/sub?token=fixture-secret',
  '10.23.45.67',
  '123e4567-e89b-12d3-a456-426614174000',
  'fixture-private-key',
  'ProfileConfig{password: fixture-secret}',
];

class _PoisonException {
  @override
  String toString() => throw StateError('unsafe exception was serialized');
}

class _RecordingTransport implements Transport {
  _RecordingTransport(this.options);

  final SentryOptions options;
  final envelopes = <String>[];
  final itemTypes = <List<String>>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    itemTypes.add(envelope.items.map((item) => item.header.type).toList());
    final bytes = <int>[];
    await for (final chunk in envelope.envelopeStream(options)) {
      bytes.addAll(chunk);
    }
    envelopes.add(utf8.decode(bytes));
    return envelope.header.eventId;
  }
}

class _NativePlaceholderTransport implements Transport {
  int calls = 0;

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    calls += 1;
    return envelope.header.eventId;
  }
}

class _RecordingHttpClient extends http.BaseClient {
  final List<String> requests = [];
  final List<Uri> requestUrls = [];
  final List<String?> sentryAuthHeaders = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestUrls.add(request.url);
    sentryAuthHeaders.add(request.headers['X-Sentry-Auth']);
    requests.add(utf8.decode(await request.finalize().toBytes()));
    return http.StreamedResponse(Stream.value(utf8.encode('{"id":"0123456789abcdef0123456789abcdef"}')), 200);
  }
}

void main() {
  test('safe Sentry filter rebuilds hostile events from severity alone', () async {
    final hostile = SentryEvent(
      logger: _hostileMarkers[2],
      serverName: _hostileMarkers[1],
      transaction: _hostileMarkers[0],
      level: SentryLevel.error,
      message: SentryMessage(_hostileMarkers.join(' ')),
      throwable: _PoisonException(),
      tags: {'secret': _hostileMarkers[3]},
      // ignore: deprecated_member_use
      extra: {'config': _hostileMarkers[4]},
      breadcrumbs: [
        Breadcrumb(message: _hostileMarkers[0], data: {'token': _hostileMarkers[3]}),
      ],
      user: SentryUser(id: _hostileMarkers[2], ipAddress: _hostileMarkers[1]),
      request: SentryRequest(url: _hostileMarkers[0], data: _hostileMarkers[4]),
    );

    final hint = Hint.withAttachment(SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[3]), _hostileMarkers[2]))
      ..screenshot = SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[0]), 'screenshot.txt')
      ..viewHierarchy = SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[4]), 'view.txt')
      ..set('exception', _PoisonException());
    final safe = await safeSentryBeforeSend(hostile, hint);
    final json = safe!.toJson();
    final serialized = jsonEncode(json);

    expect(json['logger'], 'safe_diagnostics');
    expect(json['level'], 'error');
    expect((json['message'] as Map<String, dynamic>)['formatted'], 'safe_diagnostic.sentry.error');
    for (final forbidden in [
      'server_name',
      'transaction',
      'tags',
      'extra',
      'breadcrumbs',
      'user',
      'request',
      'exception',
    ]) {
      expect(json, isNot(contains(forbidden)), reason: '$forbidden must not cross the iOS boundary');
    }
    for (final marker in _hostileMarkers) {
      expect(serialized, isNot(contains(marker)));
    }
    expect(hint.attachments, isEmpty);
    expect(hint.screenshot, isNull);
    expect(hint.viewHierarchy, isNull);
    expect(hint.get('exception'), isNull);
  });

  test('safe Sentry filter uses only allowlisted severity and fixed codes', () async {
    final cases = <(SentryLevel?, SentryLevel, String)>[
      (SentryLevel.debug, SentryLevel.debug, 'safe_diagnostic.sentry.debug'),
      (SentryLevel.info, SentryLevel.info, 'safe_diagnostic.sentry.info'),
      (SentryLevel.warning, SentryLevel.warning, 'safe_diagnostic.sentry.warning'),
      (SentryLevel.error, SentryLevel.error, 'safe_diagnostic.sentry.error'),
      (SentryLevel.fatal, SentryLevel.error, 'safe_diagnostic.sentry.error'),
      (null, SentryLevel.info, 'safe_diagnostic.sentry.info'),
    ];

    for (final (input, expectedLevel, expectedCode) in cases) {
      final safe = await safeSentryBeforeSend(
        SentryEvent(level: input, message: const SentryMessage('arbitrary')),
        Hint(),
      );
      expect(safe!.level, expectedLevel);
      expect(safe.message!.formatted, expectedCode);
    }
  });

  test('safe breadcrumb filter rebuilds hostile breadcrumb from severity alone', () {
    final hostile = Breadcrumb(
      message: _hostileMarkers[0],
      category: _hostileMarkers[2],
      type: _hostileMarkers[4],
      level: SentryLevel.warning,
      data: {'token': _hostileMarkers[3], 'ip': _hostileMarkers[1]},
    );

    final safe = safeSentryBeforeBreadcrumb(hostile, Hint())!;
    final json = safe.toJson();
    final serialized = jsonEncode(json);

    expect(json['message'], 'safe_diagnostic.breadcrumb.warning');
    expect(json['category'], 'safe_diagnostics');
    expect(json['type'], 'default');
    expect(json['level'], 'warning');
    expect(json, isNot(contains('data')));
    for (final marker in _hostileMarkers) {
      expect(serialized, isNot(contains(marker)));
    }
  });

  test('iOS safe Sentry options disable unsanitized native and tracing paths', () {
    final options = SentryFlutterOptions()
      ..enableNativeCrashHandling = true
      ..enableAutoNativeBreadcrumbs = true
      ..enableAutoPerformanceTracing = true
      ..enableUserInteractionTracing = true
      ..enableTimeToFullDisplayTracing = true
      ..attachThreads = true
      ..tracesSampleRate = 1
      ..profilesSampleRate = 1;

    configureIosSafeSentryOptions(options);

    expect(options.debug, isFalse);
    expect(options.reportPackages, isFalse);
    expect(options.sendClientReports, isFalse);
    expect(options.enableNativeCrashHandling, isFalse);
    expect(options.enableAutoNativeBreadcrumbs, isFalse);
    expect(options.enableAutoPerformanceTracing, isFalse);
    expect(options.enableUserInteractionTracing, isFalse);
    expect(options.enableTimeToFullDisplayTracing, isFalse);
    expect(options.attachThreads, isFalse);
    expect(options.tracesSampleRate, isNull);
    expect(options.tracesSampler, isNull);
    expect(options.profilesSampleRate, isNull);
    expect(options.beforeSend, same(safeSentryBeforeSend));
    expect(options.beforeBreadcrumb, same(safeSentryBeforeBreadcrumb));
    expect(options.beforeSendTransaction, same(dropSentryTransaction));
  });

  test('real Sentry init replaces native transport and sends only a minimal event over HTTP', () async {
    final options = SentryFlutterOptions(dsn: 'https://fixture-public-key@example.invalid/1')..compressPayload = false;
    final nativePlaceholder = _NativePlaceholderTransport();
    final httpClient = _RecordingHttpClient();
    options
      ..transport = nativePlaceholder
      ..httpClient = httpClient;

    // ignore: invalid_use_of_internal_member
    await Sentry.init(
      (configuredOptions) {
        configureIosSafeSentryOptions(configuredOptions as SentryFlutterOptions);
        expect(options.autoInitializeNativeSdk, isFalse);
        expect(options.transport, isNot(same(nativePlaceholder)));
        expect(options.integrations.first, isA<IosSafeSentryTransportIntegration>());
      },
      // ignore: invalid_use_of_internal_member
      options: options,
    );
    addTearDown(Sentry.close);

    expect(options.integrations.first, isA<IosSafeSentryTransportIntegration>());
    expect(options.transport, isA<IosSafeSentryTransport>());

    await Sentry.configureScope((scope) async {
      await scope.setUser(SentryUser(id: _hostileMarkers[2], ipAddress: _hostileMarkers[1]));
      await scope.setContexts('profile', {'config': _hostileMarkers[4]});
      await scope.setTag('url', _hostileMarkers[0]);
      // ignore: deprecated_member_use
      await scope.setExtra('token', _hostileMarkers[3]);
      await scope.addBreadcrumb(Breadcrumb(message: _hostileMarkers[0], data: {'ip': _hostileMarkers[1]}));
      scope.addAttachment(SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[3]), _hostileMarkers[2]));
    });

    await Sentry.captureException(
      StateError(_hostileMarkers.join(' ')),
      stackTrace: StackTrace.fromString(_hostileMarkers.join('\n')),
      hint: Hint.withAttachment(
        SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[4]), 'hint-${_hostileMarkers[2]}'),
      ),
    );

    expect(nativePlaceholder.calls, 0);
    expect(httpClient.requestUrls.single.host, 'example.invalid');
    expect(httpClient.requestUrls.single.path, '/api/1/envelope/');
    expect(httpClient.sentryAuthHeaders.single, contains('sentry_key=fixture-public-key'));
    final request = httpClient.requests.single;
    expect(request, contains('safe_diagnostic.sentry.error'));
    expect(request, contains('safe_diagnostics'));
    expect(request, isNot(contains('attachment')));
    for (final marker in _hostileMarkers) {
      expect(request, isNot(contains(marker)));
    }
  });

  test('safe transport sends a minimal event envelope after real SDK scope enrichment', () async {
    final options = SentryFlutterOptions(dsn: 'https://fixture-public-key@example.invalid/1');
    configureIosSafeSentryOptions(options);
    final recording = _RecordingTransport(options);
    options.transport = recording;
    installIosSafeSentryTransport(options);
    final hub = Hub(options);

    await hub.configureScope((scope) async {
      await scope.setUser(SentryUser(id: _hostileMarkers[2], ipAddress: _hostileMarkers[1]));
      await scope.setContexts('profile', {'config': _hostileMarkers[4]});
      await scope.setTag('url', _hostileMarkers[0]);
      // ignore: deprecated_member_use
      await scope.setExtra('token', _hostileMarkers[3]);
      await scope.addBreadcrumb(Breadcrumb(message: _hostileMarkers[0], data: {'ip': _hostileMarkers[1]}));
      scope.addAttachment(SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[3]), _hostileMarkers[2]));
    });

    await hub.captureException(
      StateError(_hostileMarkers.join(' ')),
      stackTrace: StackTrace.fromString(_hostileMarkers.join('\n')),
      hint: Hint.withAttachment(
        SentryAttachment.fromIntList(utf8.encode(_hostileMarkers[4]), 'hint-${_hostileMarkers[2]}'),
      ),
    );
    await hub.close();

    expect(recording.itemTypes, [
      ['event'],
    ]);
    final envelope = recording.envelopes.single;
    expect(envelope, contains('safe_diagnostic.sentry.error'));
    expect(envelope, contains('safe_diagnostics'));
    for (final marker in _hostileMarkers) {
      expect(envelope, isNot(contains(marker)));
    }
  });
}
