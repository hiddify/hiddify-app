enum HomeAsyncVariant { data, loading, error }

enum HomeConnectionValue { connected, connecting, disconnected, disconnecting, none }

enum HomeLabelChoice { connected, connecting, disconnected, disconnecting, reconnect, empty, unknown }

enum HomeThemePlatform { android, fuchsia, iOS, linux, macOS, windows }

enum HomeLifecycleState { resumed, inactive, paused, hidden, detached, unknown }

enum HomeReconnectValue {
  trueValue('true'),
  falseValue('false'),
  unknown('unknown');

  const HomeReconnectValue(this.wireValue);

  final String wireValue;

  static HomeReconnectValue fromNullable(bool? value) => switch (value) {
    true => trueValue,
    false => falseValue,
    null => unknown,
  };
}

enum HomeLatencyBand {
  nonPositive('non_positive'),
  valid('valid'),
  atLimit('at_limit'),
  aboveLimit('above_limit');

  const HomeLatencyBand(this.wireValue);

  final String wireValue;

  static HomeLatencyBand fromDelay(int delay) => switch (delay) {
    <= 0 => nonPositive,
    < 65000 => valid,
    65000 => atLimit,
    _ => aboveLimit,
  };
}

final class HomePresentationSnapshot {
  const HomePresentationSnapshot({
    required this.asyncVariant,
    required this.connectionValue,
    required this.labelChoice,
    required this.themePlatform,
    required this.runtimeIos,
    required this.reconnect,
    required this.latencyBand,
    required this.tickersEnabled,
    required this.lifecycleState,
  });

  static const Set<String> _keys = {
    'async_variant',
    'connection_value',
    'label_choice',
    'theme_platform',
    'runtime_ios',
    'reconnect',
    'latency_band',
    'tickers_enabled',
    'lifecycle_state',
  };

  final HomeAsyncVariant asyncVariant;
  final HomeConnectionValue connectionValue;
  final HomeLabelChoice labelChoice;
  final HomeThemePlatform themePlatform;
  final bool runtimeIos;
  final HomeReconnectValue reconnect;
  final HomeLatencyBand latencyBand;
  final bool tickersEnabled;
  final HomeLifecycleState lifecycleState;

  Map<String, Object> toJson() => {
    'async_variant': asyncVariant.name,
    'connection_value': connectionValue.name,
    'label_choice': labelChoice.name,
    'theme_platform': themePlatform.name,
    'runtime_ios': runtimeIos,
    'reconnect': reconnect.wireValue,
    'latency_band': latencyBand.wireValue,
    'tickers_enabled': tickersEnabled,
    'lifecycle_state': lifecycleState.name,
  };

  factory HomePresentationSnapshot.fromJson(Map<String, Object?> json) {
    if (json.length != _keys.length || !json.keys.every(_keys.contains)) {
      throw const FormatException('invalid Home presentation fields');
    }
    final asyncVariant = _enumByName(HomeAsyncVariant.values, json['async_variant']);
    final connectionValue = _enumByName(HomeConnectionValue.values, json['connection_value']);
    final labelChoice = _enumByName(HomeLabelChoice.values, json['label_choice']);
    final themePlatform = _enumByName(HomeThemePlatform.values, json['theme_platform']);
    final reconnect = _enumByWire(HomeReconnectValue.values, json['reconnect'], (value) => value.wireValue);
    final latencyBand = _enumByWire(HomeLatencyBand.values, json['latency_band'], (value) => value.wireValue);
    final tickersEnabled = json['tickers_enabled'];
    final lifecycleState = _enumByName(HomeLifecycleState.values, json['lifecycle_state']);
    final runtimeIos = json['runtime_ios'];
    if (asyncVariant == null ||
        connectionValue == null ||
        labelChoice == null ||
        themePlatform == null ||
        runtimeIos is! bool ||
        reconnect == null ||
        latencyBand == null ||
        tickersEnabled is! bool ||
        lifecycleState == null) {
      throw const FormatException('unknown Home presentation value');
    }
    return HomePresentationSnapshot(
      asyncVariant: asyncVariant,
      connectionValue: connectionValue,
      labelChoice: labelChoice,
      themePlatform: themePlatform,
      runtimeIos: runtimeIos,
      reconnect: reconnect,
      latencyBand: latencyBand,
      tickersEnabled: tickersEnabled,
      lifecycleState: lifecycleState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePresentationSnapshot &&
          asyncVariant == other.asyncVariant &&
          connectionValue == other.connectionValue &&
          labelChoice == other.labelChoice &&
          themePlatform == other.themePlatform &&
          runtimeIos == other.runtimeIos &&
          reconnect == other.reconnect &&
          latencyBand == other.latencyBand &&
          tickersEnabled == other.tickersEnabled &&
          lifecycleState == other.lifecycleState;

  @override
  int get hashCode => Object.hash(
    asyncVariant,
    connectionValue,
    labelChoice,
    themePlatform,
    runtimeIos,
    reconnect,
    latencyBand,
    tickersEnabled,
    lifecycleState,
  );
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) =>
    name is String ? values.where((value) => value.name == name).firstOrNull : null;

T? _enumByWire<T>(List<T> values, Object? wireValue, String Function(T value) encode) =>
    wireValue is String ? values.where((value) => encode(value) == wireValue).firstOrNull : null;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
