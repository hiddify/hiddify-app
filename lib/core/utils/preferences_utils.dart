import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesEntry<T, P> with InfraLogger {
  PreferencesEntry({
    required this.preferences,
    required this.key,
    required this.defaultValue,
    this.mapFrom,
    this.mapTo,
    this.validator,
  });

  final SharedPreferences preferences;
  final String key;
  final T defaultValue;
  final T Function(P value)? mapFrom;
  final P Function(T value)? mapTo;
  final bool Function(T value)? validator;

  T read() {
    try {
      loggy.debug("getting persisted preference [$key]($T)");
      final T value;
      if (mapFrom != null) {
        final persisted = preferences.get(key) as P?;
        if (persisted == null) {
          value = defaultValue;
        } else {
          value = mapFrom!(persisted);
        }
      } else if (T == List<String>) {
        value = preferences.getStringList(key) as T? ?? defaultValue;
      } else {
        value = preferences.get(key) as T? ?? defaultValue;
      }

      if (validator?.call(value) ?? true) return value;
      return defaultValue;
    } catch (e, stackTrace) {
      loggy.warning("error getting preference[$key]: $e", e, stackTrace);
      return defaultValue;
    }
  }

  Future<bool> write(T value) async {
    Object? mapped = value;
    if (mapTo != null) {
      mapped = mapTo!(value);
    }
    loggy.debug("updating preference [$key]($T) to [$mapped]");
    try {
      if (!(validator?.call(value) ?? true)) {
        loggy.warning("invalid value [$value] for preference [$key]($T)");
        return false;
      }

      return switch (mapped) {
        final String value => await preferences.setString(key, value),
        final bool value => await preferences.setBool(key, value),
        final int value => await preferences.setInt(key, value),
        final double value => await preferences.setDouble(key, value),
        final List<String> value => await preferences.setStringList(key, value),
        _ => throw const FormatException("Invalid Type"),
      };
    } catch (e, stackTrace) {
      loggy.warning("error updating preference[$key]: $e", e, stackTrace);
      return false;
    }
  }

  Future<T?> writeRaw(P input) async {
    final T value;
    if (mapFrom != null) {
      value = mapFrom!(input);
    } else {
      value = input as T;
    }
    if (await write(value)) return value;
    return null;
  }

  Future<void> remove() async {
    try {
      await preferences.remove(key);
    } catch (e, stackTrace) {
      loggy.warning("error removing preference[$key]: $e", e, stackTrace);
    }
  }
}

class PreferencesNotifier<T, P> extends StateNotifier<T> {
  PreferencesNotifier._({
    required Ref ref,
    required this.entry,
    this.overrideValue,
    this.possibleValues,
  })  : _ref = ref,
        super(overrideValue ?? entry.read());

  final Ref _ref;
  final PreferencesEntry<T, P> entry;
  final T? overrideValue;
  final List<T>? possibleValues;

  static StateNotifierProvider<PreferencesNotifier<T, P>, T> create<T, P>(String key, T defaultValue,
          {T Function(Ref ref)? defaultValueFunction, T Function(P value)? mapFrom, P Function(T value)? mapTo, bool Function(T value)? validator, T? overrideValue, List<T>? possibleValues}) =>
      StateNotifierProvider(
        (ref) => PreferencesNotifier._(
            ref: ref,
            entry: PreferencesEntry<T, P>(
              preferences: ref.read(sharedPreferencesProvider).requireValue,
              key: key,
              defaultValue: defaultValueFunction?.call(ref) ?? defaultValue,
              mapFrom: mapFrom,
              mapTo: mapTo,
              validator: validator,
            ),
            overrideValue: overrideValue,
            possibleValues: possibleValues),
      );

  static AutoDisposeStateNotifierProvider<PreferencesNotifier<T, P>, T> createAutoDispose<T, P>(
    String key,
    T defaultValue, {
    T Function(P value)? mapFrom,
    P Function(T value)? mapTo,
    bool Function(T value)? validator,
    T? overrideValue,
  }) =>
      StateNotifierProvider.autoDispose(
        (ref) => PreferencesNotifier._(
          ref: ref,
          entry: PreferencesEntry<T, P>(
            preferences: ref.read(sharedPreferencesProvider).requireValue,
            key: key,
            defaultValue: defaultValue,
            mapFrom: mapFrom,
            mapTo: mapTo,
            validator: validator,
          ),
          overrideValue: overrideValue,
        ),
      );

  P raw() {
    final value = overrideValue ?? state;
    if (entry.mapTo != null) return entry.mapTo!(value);
    return value as P;
  }

  Future<void> updateRaw(P input) async {
    final value = await entry.writeRaw(input);
    if (value != null) state = value;
  }

  Future<void> update(T value) async {
    if (await entry.write(value)) state = value;
  }

  Future<void> reset() async {
    await entry.remove();
    _ref.invalidateSelf();
  }
}
