import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_option_data_providers.g.dart';

@Riverpod(keepAlive: true)
ConfigOptionRepository configOptionRepository(
  ConfigOptionRepositoryRef ref,
) {
  return ConfigOptionRepository(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    getConfigOptions: () => ref.read(ConfigOptions.singboxConfigOptions.future),
  );
}
