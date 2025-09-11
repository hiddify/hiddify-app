// import 'dart:io';

// import 'package:dartx/dartx_io.dart';
// import 'package:drift/drift.dart';
// import 'package:flutter/services.dart';
// import 'package:fpdart/fpdart.dart';
// import 'package:hiddify/core/database/app_database.dart';
// import 'package:hiddify/core/http_client/dio_http_client.dart';
// import 'package:hiddify/core/utils/exception_handler.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_data_mapper.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_data_source.dart';
// import 'package:hiddify/features/geo_asset/data/geo_asset_path_resolver.dart';
// import 'package:hiddify/features/geo_asset/model/default_geo_assets.dart';
// import 'package:hiddify/features/geo_asset/model/geo_asset_entity.dart';
// import 'package:hiddify/features/geo_asset/model/geo_asset_failure.dart';
// import 'package:hiddify/gen/assets.gen.dart';
// import 'package:hiddify/utils/custom_loggers.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:watcher/watcher.dart';

// abstract interface class GeoAssetRepository {
//   /// populate bundled geo assets directory with bundled files if needed
//   TaskEither<GeoAssetFailure, Unit> init();
//   TaskEither<GeoAssetFailure, ({GeoAssetEntity geoip, GeoAssetEntity geosite})>
//       getActivePair();
//   Stream<Either<GeoAssetFailure, List<GeoAssetWithFileSize>>> watchAll();
//   TaskEither<GeoAssetFailure, Unit> update(GeoAssetEntity geoAsset);
//   TaskEither<GeoAssetFailure, Unit> markAsActive(GeoAssetEntity geoAsset);
//   TaskEither<GeoAssetFailure, Unit> addRecommended();
// }

// class GeoAssetRepositoryImpl
//     with ExceptionHandler, InfraLogger
//     implements GeoAssetRepository {
//   GeoAssetRepositoryImpl({
//     required this.geoAssetDataSource,
//     required this.geoAssetPathResolver,
//     required this.httpClient,
//   });

//   final GeoAssetDataSource geoAssetDataSource;
//   final GeoAssetPathResolver geoAssetPathResolver;
//   final DioHttpClient httpClient;

//   @override
//   TaskEither<GeoAssetFailure, Unit> init() {
//     return exceptionHandler(
//       () async {
//         loggy.debug("initializing");
//         final geoipFile = geoAssetPathResolver.file(
//           defaultGeoip.providerName,
//           defaultGeoip.fileName,
//         );
//         final geositeFile = geoAssetPathResolver.file(
//           defaultGeosite.providerName,
//           defaultGeosite.fileName,
//         );

//         final dirExists = await geoAssetPathResolver.directory.exists();
//         if (!dirExists) {
//           await geoAssetPathResolver.directory.create(recursive: true);
//         }

//         if (!dirExists || !await geoipFile.exists()) {
//           final bundledGeoip = await rootBundle.load(Assets.core.geoip);
//           await geoipFile.writeAsBytes(bundledGeoip.buffer.asInt8List());
//         }
//         if (!dirExists || !await geositeFile.exists()) {
//           final bundledGeosite = await rootBundle.load(Assets.core.geosite);
//           await geositeFile.writeAsBytes(bundledGeosite.buffer.asInt8List());
//         }
//         return right(unit);
//       },
//       GeoAssetUnexpectedFailure.new,
//     );
//   }

//   @override
//   TaskEither<GeoAssetFailure, ({GeoAssetEntity geoip, GeoAssetEntity geosite})>
//       getActivePair() {
//     return exceptionHandler(
//       () async {
//         final geoip =
//             await geoAssetDataSource.getActiveAssetByType(GeoAssetType.geoip);
//         final geosite =
//             await geoAssetDataSource.getActiveAssetByType(GeoAssetType.geosite);
//         if (geoip == null || geosite == null) {
//           return left(const GeoAssetFailure.activeAssetNotFound());
//         }
//         return right((geoip: geoip.toEntity(), geosite: geosite.toEntity()));
//       },
//       GeoAssetUnexpectedFailure.new,
//     );
//   }

//   @override
//   Stream<Either<GeoAssetFailure, List<GeoAssetWithFileSize>>> watchAll() {
//     final persistedStream = geoAssetDataSource
//         .watchAll()
//         .map((event) => event.map((e) => e.toEntity()));
//     final filesStream = _watchGeoFiles();

//     return Rx.combineLatest2(
//       persistedStream,
//       filesStream,
//       (assets, files) => assets.map(
//         (e) {
//           final path =
//               geoAssetPathResolver.file(e.providerName, e.fileName).path;
//           final file = files.firstOrNullWhere((e) => e.path == path);
//           final stat = file?.statSync();
//           return (e, stat?.size);
//         },
//       ).toList(),
//     ).handleExceptions(GeoAssetUnexpectedFailure.new);
//   }

//   Iterable<File> _geoFiles = [];
//   Stream<Iterable<File>> _watchGeoFiles() async* {
//     yield await _readGeoFiles();
//     yield* Watcher(
//       geoAssetPathResolver.directory.path,
//       pollingDelay: const Duration(seconds: 1),
//     ).events.asyncMap((event) async {
//       await _readGeoFiles();
//       return _geoFiles;
//     });
//   }

//   Future<Iterable<File>> _readGeoFiles() async {
//     return _geoFiles = Directory(geoAssetPathResolver.directory.path)
//         .listSync()
//         .whereType<File>()
//         .where((e) => e.extension == '.db');
//   }

//   @override
//   TaskEither<GeoAssetFailure, Unit> update(GeoAssetEntity geoAsset) {
//     return exceptionHandler(
//       () async {
//         loggy.debug(
//           "checking latest release of [${geoAsset.name}] on [${geoAsset.repositoryUrl}]",
//         );
//         final response = await httpClient.get<Map>(geoAsset.repositoryUrl);
//         if (response.statusCode != 200 || response.data == null) {
//           return left(
//             GeoAssetUnexpectedFailure.new(
//               "invalid response",
//               StackTrace.current,
//             ),
//           );
//         }

//         final file =
//             geoAssetPathResolver.file(geoAsset.providerName, geoAsset.name);
//         final tagName = response.data!['tag_name'] as String;
//         loggy.debug("latest release of [${geoAsset.name}]: [$tagName]");
//         if (tagName == geoAsset.version && await file.exists()) {
//           await geoAssetDataSource.patch(
//             geoAsset.id,
//             GeoAssetEntriesCompanion(lastCheck: Value(DateTime.now())),
//           );
//           return left(const GeoAssetFailure.noUpdateAvailable());
//         }

//         final assets = (response.data!['assets'] as List)
//             .whereType<Map<String, dynamic>>();
//         final asset =
//             assets.firstOrNullWhere((e) => e["name"] == geoAsset.name);
//         if (asset == null) {
//           return left(
//             GeoAssetUnexpectedFailure.new(
//               "couldn't find [${geoAsset.name}] on [${geoAsset.repositoryUrl}]",
//               StackTrace.current,
//             ),
//           );
//         }

//         final downloadUrl = asset["browser_download_url"] as String;
//         loggy.debug("[${geoAsset.name}] download url: [$downloadUrl]");
//         final tempPath = "${file.path}.tmp";
//         await file.parent.create(recursive: true);
//         await httpClient.download(downloadUrl, tempPath);
//         await File(tempPath).rename(file.path);

//         await geoAssetDataSource.patch(
//           geoAsset.id,
//           GeoAssetEntriesCompanion(
//             version: Value(tagName),
//             lastCheck: Value(DateTime.now()),
//           ),
//         );

//         return right(unit);
//       },
//       GeoAssetUnexpectedFailure.new,
//     );
//   }

//   @override
//   TaskEither<GeoAssetFailure, Unit> markAsActive(GeoAssetEntity geoAsset) {
//     return exceptionHandler(
//       () async {
//         await geoAssetDataSource.patch(
//           geoAsset.id,
//           const GeoAssetEntriesCompanion(active: Value(true)),
//         );
//         return right(unit);
//       },
//       GeoAssetUnexpectedFailure.new,
//     );
//   }

//   @override
//   TaskEither<GeoAssetFailure, Unit> addRecommended() {
//     return exceptionHandler(
//       () async {
//         final persistedIds = await geoAssetDataSource
//             .watchAll()
//             .first
//             .then((value) => value.map((e) => e.id));
//         final missing =
//             recommendedGeoAssets.where((e) => !persistedIds.contains(e.id));
//         for (final geoAsset in missing) {
//           await geoAssetDataSource.insert(geoAsset.toEntry());
//         }
//         return right(unit);
//       },
//       GeoAssetUnexpectedFailure.new,
//     );
//   }
// }
