import 'package:drift/drift.dart';
import 'package:hiddify/core/database/converters/duration_converter.dart';
import 'package:hiddify/features/geo_asset/model/geo_asset_entity.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

@DataClassName('ProfileEntry')
class ProfileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<ProfileType>()();
  BoolColumn get active => boolean()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get url => text().nullable()();
  DateTimeColumn get lastUpdate => dateTime()();
  IntColumn get updateInterval => integer().nullable().map(DurationTypeConverter())();
  IntColumn get upload => integer().nullable()();
  IntColumn get download => integer().nullable()();
  IntColumn get total => integer().nullable()();
  DateTimeColumn get expire => dateTime().nullable()();
  TextColumn get webPageUrl => text().nullable()();
  TextColumn get supportUrl => text().nullable()();
  TextColumn get testUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GeoAssetEntry')
class GeoAssetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<GeoAssetType>()();
  BoolColumn get active => boolean()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get providerName => text().withLength(min: 1)();
  TextColumn get version => text().nullable()();
  DateTimeColumn get lastCheck => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {name, providerName},
      ];
}
