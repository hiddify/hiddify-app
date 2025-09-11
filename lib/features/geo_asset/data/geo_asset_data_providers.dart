// import 'package:hiddify/core/database/database_provider.dart';
// import 'package:hiddify/core/directories/directories_provider.dart';
// import 'package:hiddify/core/http_client/http_client_provider.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_data_source.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_path_resolver.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_repository.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'geo_asset_data_providers.g.dart';

// @Riverpod(keepAlive: true)
// Future<GeoAssetRepository> geoAssetRepository(GeoAssetRepositoryRef ref) async {
//   final repo = GeoAssetRepositoryImpl(
//     geoAssetDataSource: ref.watch(geoAssetDataSourceProvider),
//     geoAssetPathResolver: ref.watch(geoAssetPathResolverProvider),
//     httpClient: ref.watch(httpClientProvider),
//   );
//   await repo.init().getOrElse((l) => throw l).run();
//   return repo;
// }

// @Riverpod(keepAlive: true)
// GeoAssetDataSource geoAssetDataSource(GeoAssetDataSourceRef ref) {
//   return GeoAssetsDao(ref.watch(appDatabaseProvider));
// }

// @Riverpod(keepAlive: true)
// GeoAssetPathResolver geoAssetPathResolver(GeoAssetPathResolverRef ref) {
//   return GeoAssetPathResolver(
//     ref.watch(appDirectoriesProvider).requireValue.workingDir,
//   );
// }
