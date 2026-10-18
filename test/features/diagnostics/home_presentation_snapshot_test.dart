import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';

void main() {
  const snapshot = HomePresentationSnapshot(
    asyncVariant: HomeAsyncVariant.error,
    connectionValue: HomeConnectionValue.connected,
    labelChoice: HomeLabelChoice.empty,
    themePlatform: HomeThemePlatform.android,
    runtimeIos: true,
    reconnect: HomeReconnectValue.unknown,
    latencyBand: HomeLatencyBand.atLimit,
    tickersEnabled: false,
    lifecycleState: HomeLifecycleState.hidden,
  );

  test('round-trips the exact closed Home presentation schema', () {
    expect(snapshot.toJson(), {
      'async_variant': 'error',
      'connection_value': 'connected',
      'label_choice': 'empty',
      'theme_platform': 'android',
      'runtime_ios': true,
      'reconnect': 'unknown',
      'latency_band': 'at_limit',
      'tickers_enabled': false,
      'lifecycle_state': 'hidden',
    });
    expect(HomePresentationSnapshot.fromJson(snapshot.toJson()), snapshot);
  });

  test('rejects extra, missing, mistyped and unknown values', () {
    final valid = snapshot.toJson();
    final invalid = <Map<String, Object?>>[
      {...valid, 'raw_label': 'private translated label'},
      Map<String, Object?>.of(valid)..remove('label_choice'),
      {...valid, 'async_variant': 'refreshing'},
      {...valid, 'connection_value': 'started'},
      {...valid, 'label_choice': 'private translated label'},
      {...valid, 'theme_platform': 'cupertino'},
      {...valid, 'runtime_ios': 'true'},
      {...valid, 'reconnect': 'null'},
      {...valid, 'latency_band': 'timeout'},
      {...valid, 'tickers_enabled': 'false'},
      {...valid, 'lifecycle_state': 'foreground'},
    ];

    for (final value in invalid) {
      expect(() => HomePresentationSnapshot.fromJson(value), throwsFormatException, reason: jsonEncode(value));
    }
  });

  test('represents true, false and unknown reconnect values distinctly', () {
    expect(HomeReconnectValue.fromNullable(true).wireValue, 'true');
    expect(HomeReconnectValue.fromNullable(false).wireValue, 'false');
    expect(HomeReconnectValue.fromNullable(null).wireValue, 'unknown');
  });

  test('classifies every latency boundary without recording the raw value', () {
    expect(HomeLatencyBand.fromDelay(-1), HomeLatencyBand.nonPositive);
    expect(HomeLatencyBand.fromDelay(0), HomeLatencyBand.nonPositive);
    expect(HomeLatencyBand.fromDelay(1), HomeLatencyBand.valid);
    expect(HomeLatencyBand.fromDelay(64999), HomeLatencyBand.valid);
    expect(HomeLatencyBand.fromDelay(65000), HomeLatencyBand.atLimit);
    expect(HomeLatencyBand.fromDelay(65001), HomeLatencyBand.aboveLimit);
  });
}
