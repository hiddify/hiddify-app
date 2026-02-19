// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class ProfileEntries extends Table
    with TableInfo<ProfileEntries, ProfileEntriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ProfileEntries(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> lastUpdate = GeneratedColumn<DateTime>(
    'last_update',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> updateInterval = GeneratedColumn<int>(
    'update_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> upload = GeneratedColumn<int>(
    'upload',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> download = GeneratedColumn<int>(
    'download',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> expire = GeneratedColumn<DateTime>(
    'expire',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> webPageUrl = GeneratedColumn<String>(
    'web_page_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> supportUrl = GeneratedColumn<String>(
    'support_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    active,
    name,
    url,
    lastUpdate,
    updateInterval,
    upload,
    download,
    total,
    expire,
    webPageUrl,
    supportUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_entries';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileEntriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileEntriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      lastUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_update'],
      )!,
      updateInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_interval'],
      ),
      upload: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload'],
      ),
      download: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download'],
      ),
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      ),
      expire: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expire'],
      ),
      webPageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}web_page_url'],
      ),
      supportUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}support_url'],
      ),
    );
  }

  @override
  ProfileEntries createAlias(String alias) {
    return ProfileEntries(attachedDatabase, alias);
  }
}

class ProfileEntriesData extends DataClass
    implements Insertable<ProfileEntriesData> {
  final String id;
  final bool active;
  final String name;
  final String url;
  final DateTime lastUpdate;
  final int? updateInterval;
  final int? upload;
  final int? download;
  final int? total;
  final DateTime? expire;
  final String? webPageUrl;
  final String? supportUrl;
  const ProfileEntriesData({
    required this.id,
    required this.active,
    required this.name,
    required this.url,
    required this.lastUpdate,
    this.updateInterval,
    this.upload,
    this.download,
    this.total,
    this.expire,
    this.webPageUrl,
    this.supportUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['active'] = Variable<bool>(active);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['last_update'] = Variable<DateTime>(lastUpdate);
    if (!nullToAbsent || updateInterval != null) {
      map['update_interval'] = Variable<int>(updateInterval);
    }
    if (!nullToAbsent || upload != null) {
      map['upload'] = Variable<int>(upload);
    }
    if (!nullToAbsent || download != null) {
      map['download'] = Variable<int>(download);
    }
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    if (!nullToAbsent || expire != null) {
      map['expire'] = Variable<DateTime>(expire);
    }
    if (!nullToAbsent || webPageUrl != null) {
      map['web_page_url'] = Variable<String>(webPageUrl);
    }
    if (!nullToAbsent || supportUrl != null) {
      map['support_url'] = Variable<String>(supportUrl);
    }
    return map;
  }

  ProfileEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProfileEntriesCompanion(
      id: Value(id),
      active: Value(active),
      name: Value(name),
      url: Value(url),
      lastUpdate: Value(lastUpdate),
      updateInterval: updateInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(updateInterval),
      upload: upload == null && nullToAbsent
          ? const Value.absent()
          : Value(upload),
      download: download == null && nullToAbsent
          ? const Value.absent()
          : Value(download),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
      expire: expire == null && nullToAbsent
          ? const Value.absent()
          : Value(expire),
      webPageUrl: webPageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(webPageUrl),
      supportUrl: supportUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(supportUrl),
    );
  }

  factory ProfileEntriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileEntriesData(
      id: serializer.fromJson<String>(json['id']),
      active: serializer.fromJson<bool>(json['active']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      lastUpdate: serializer.fromJson<DateTime>(json['lastUpdate']),
      updateInterval: serializer.fromJson<int?>(json['updateInterval']),
      upload: serializer.fromJson<int?>(json['upload']),
      download: serializer.fromJson<int?>(json['download']),
      total: serializer.fromJson<int?>(json['total']),
      expire: serializer.fromJson<DateTime?>(json['expire']),
      webPageUrl: serializer.fromJson<String?>(json['webPageUrl']),
      supportUrl: serializer.fromJson<String?>(json['supportUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'active': serializer.toJson<bool>(active),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'lastUpdate': serializer.toJson<DateTime>(lastUpdate),
      'updateInterval': serializer.toJson<int?>(updateInterval),
      'upload': serializer.toJson<int?>(upload),
      'download': serializer.toJson<int?>(download),
      'total': serializer.toJson<int?>(total),
      'expire': serializer.toJson<DateTime?>(expire),
      'webPageUrl': serializer.toJson<String?>(webPageUrl),
      'supportUrl': serializer.toJson<String?>(supportUrl),
    };
  }

  ProfileEntriesData copyWith({
    String? id,
    bool? active,
    String? name,
    String? url,
    DateTime? lastUpdate,
    Value<int?> updateInterval = const Value.absent(),
    Value<int?> upload = const Value.absent(),
    Value<int?> download = const Value.absent(),
    Value<int?> total = const Value.absent(),
    Value<DateTime?> expire = const Value.absent(),
    Value<String?> webPageUrl = const Value.absent(),
    Value<String?> supportUrl = const Value.absent(),
  }) => ProfileEntriesData(
    id: id ?? this.id,
    active: active ?? this.active,
    name: name ?? this.name,
    url: url ?? this.url,
    lastUpdate: lastUpdate ?? this.lastUpdate,
    updateInterval: updateInterval.present
        ? updateInterval.value
        : this.updateInterval,
    upload: upload.present ? upload.value : this.upload,
    download: download.present ? download.value : this.download,
    total: total.present ? total.value : this.total,
    expire: expire.present ? expire.value : this.expire,
    webPageUrl: webPageUrl.present ? webPageUrl.value : this.webPageUrl,
    supportUrl: supportUrl.present ? supportUrl.value : this.supportUrl,
  );
  ProfileEntriesData copyWithCompanion(ProfileEntriesCompanion data) {
    return ProfileEntriesData(
      id: data.id.present ? data.id.value : this.id,
      active: data.active.present ? data.active.value : this.active,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      lastUpdate: data.lastUpdate.present
          ? data.lastUpdate.value
          : this.lastUpdate,
      updateInterval: data.updateInterval.present
          ? data.updateInterval.value
          : this.updateInterval,
      upload: data.upload.present ? data.upload.value : this.upload,
      download: data.download.present ? data.download.value : this.download,
      total: data.total.present ? data.total.value : this.total,
      expire: data.expire.present ? data.expire.value : this.expire,
      webPageUrl: data.webPageUrl.present
          ? data.webPageUrl.value
          : this.webPageUrl,
      supportUrl: data.supportUrl.present
          ? data.supportUrl.value
          : this.supportUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileEntriesData(')
          ..write('id: $id, ')
          ..write('active: $active, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('updateInterval: $updateInterval, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('total: $total, ')
          ..write('expire: $expire, ')
          ..write('webPageUrl: $webPageUrl, ')
          ..write('supportUrl: $supportUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    active,
    name,
    url,
    lastUpdate,
    updateInterval,
    upload,
    download,
    total,
    expire,
    webPageUrl,
    supportUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileEntriesData &&
          other.id == this.id &&
          other.active == this.active &&
          other.name == this.name &&
          other.url == this.url &&
          other.lastUpdate == this.lastUpdate &&
          other.updateInterval == this.updateInterval &&
          other.upload == this.upload &&
          other.download == this.download &&
          other.total == this.total &&
          other.expire == this.expire &&
          other.webPageUrl == this.webPageUrl &&
          other.supportUrl == this.supportUrl);
}

class ProfileEntriesCompanion extends UpdateCompanion<ProfileEntriesData> {
  final Value<String> id;
  final Value<bool> active;
  final Value<String> name;
  final Value<String> url;
  final Value<DateTime> lastUpdate;
  final Value<int?> updateInterval;
  final Value<int?> upload;
  final Value<int?> download;
  final Value<int?> total;
  final Value<DateTime?> expire;
  final Value<String?> webPageUrl;
  final Value<String?> supportUrl;
  final Value<int> rowid;
  const ProfileEntriesCompanion({
    this.id = const Value.absent(),
    this.active = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.updateInterval = const Value.absent(),
    this.upload = const Value.absent(),
    this.download = const Value.absent(),
    this.total = const Value.absent(),
    this.expire = const Value.absent(),
    this.webPageUrl = const Value.absent(),
    this.supportUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileEntriesCompanion.insert({
    required String id,
    required bool active,
    required String name,
    required String url,
    required DateTime lastUpdate,
    this.updateInterval = const Value.absent(),
    this.upload = const Value.absent(),
    this.download = const Value.absent(),
    this.total = const Value.absent(),
    this.expire = const Value.absent(),
    this.webPageUrl = const Value.absent(),
    this.supportUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       active = Value(active),
       name = Value(name),
       url = Value(url),
       lastUpdate = Value(lastUpdate);
  static Insertable<ProfileEntriesData> custom({
    Expression<String>? id,
    Expression<bool>? active,
    Expression<String>? name,
    Expression<String>? url,
    Expression<DateTime>? lastUpdate,
    Expression<int>? updateInterval,
    Expression<int>? upload,
    Expression<int>? download,
    Expression<int>? total,
    Expression<DateTime>? expire,
    Expression<String>? webPageUrl,
    Expression<String>? supportUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (lastUpdate != null) 'last_update': lastUpdate,
      if (updateInterval != null) 'update_interval': updateInterval,
      if (upload != null) 'upload': upload,
      if (download != null) 'download': download,
      if (total != null) 'total': total,
      if (expire != null) 'expire': expire,
      if (webPageUrl != null) 'web_page_url': webPageUrl,
      if (supportUrl != null) 'support_url': supportUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileEntriesCompanion copyWith({
    Value<String>? id,
    Value<bool>? active,
    Value<String>? name,
    Value<String>? url,
    Value<DateTime>? lastUpdate,
    Value<int?>? updateInterval,
    Value<int?>? upload,
    Value<int?>? download,
    Value<int?>? total,
    Value<DateTime?>? expire,
    Value<String?>? webPageUrl,
    Value<String?>? supportUrl,
    Value<int>? rowid,
  }) {
    return ProfileEntriesCompanion(
      id: id ?? this.id,
      active: active ?? this.active,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      updateInterval: updateInterval ?? this.updateInterval,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      total: total ?? this.total,
      expire: expire ?? this.expire,
      webPageUrl: webPageUrl ?? this.webPageUrl,
      supportUrl: supportUrl ?? this.supportUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (lastUpdate.present) {
      map['last_update'] = Variable<DateTime>(lastUpdate.value);
    }
    if (updateInterval.present) {
      map['update_interval'] = Variable<int>(updateInterval.value);
    }
    if (upload.present) {
      map['upload'] = Variable<int>(upload.value);
    }
    if (download.present) {
      map['download'] = Variable<int>(download.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (expire.present) {
      map['expire'] = Variable<DateTime>(expire.value);
    }
    if (webPageUrl.present) {
      map['web_page_url'] = Variable<String>(webPageUrl.value);
    }
    if (supportUrl.present) {
      map['support_url'] = Variable<String>(supportUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileEntriesCompanion(')
          ..write('id: $id, ')
          ..write('active: $active, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('updateInterval: $updateInterval, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('total: $total, ')
          ..write('expire: $expire, ')
          ..write('webPageUrl: $webPageUrl, ')
          ..write('supportUrl: $supportUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV1 extends GeneratedDatabase {
  DatabaseAtV1(QueryExecutor e) : super(e);
  late final ProfileEntries profileEntries = ProfileEntries(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profileEntries];
  @override
  int get schemaVersion => 1;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
