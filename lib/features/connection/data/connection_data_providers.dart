import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/config_option/data/config_option_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_platform_source.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';

import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_data_providers.g.dart';

@Riverpod(keepAlive: true)
ConnectionRepository connectionRepository(
  ConnectionRepositoryRef ref,
) {
  return ConnectionRepositoryImpl(
    directories: ref.watch(appDirectoriesProvider).requireValue,
    configOptionRepository: ref.watch(configOptionRepositoryProvider),
    singbox: ref.watch(singboxServiceProvider),
    platformSource: ConnectionPlatformSourceImpl(),
    profilePathResolver: ref.watch(profilePathResolverProvider),
  );
}
