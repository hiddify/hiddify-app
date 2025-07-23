import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/data/auto_selection_repository.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_selection_data_provider.g.dart';

@riverpod
AutoSelectionRepository autoSelectionRepo(Ref ref) => AutoSelectionRepositoryImpl(
      mode: ref.watch(Preferences.perAppProxyMode),
      region: ref.watch(ConfigOptions.region),
      httpClient: ref.watch(httpClientProvider),
    );
