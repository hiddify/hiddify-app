import 'package:drift/drift.dart';
import 'package:hiddify/core/database/app_database.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

extension ProfileEntityMapper on ProfileEntity {
  ProfileEntriesCompanion toEntry() {
    return switch (this) {
      RemoteProfileEntity(:final url, :final options, :final subInfo) => ProfileEntriesCompanion.insert(
          id: id,
          type: ProfileType.remote,
          active: active,
          name: name,
          url: Value(url),
          lastUpdate: lastUpdate,
          updateInterval: Value(options?.updateInterval),
          upload: Value(subInfo?.upload),
          download: Value(subInfo?.download),
          total: Value(subInfo?.total),
          expire: Value(subInfo?.expire),
          webPageUrl: Value(subInfo?.webPageUrl),
          supportUrl: Value(subInfo?.supportUrl),
          testUrl: Value(testUrl),
        ),
      LocalProfileEntity() => ProfileEntriesCompanion.insert(
          id: id,
          type: ProfileType.local,
          active: active,
          name: name,
          lastUpdate: lastUpdate,
        ),
    };
  }
}

extension RemoteProfileEntityMapper on RemoteProfileEntity {
  ProfileEntriesCompanion subInfoPatch() {
    return ProfileEntriesCompanion(
      upload: Value(subInfo?.upload),
      download: Value(subInfo?.download),
      total: Value(subInfo?.total),
      expire: Value(subInfo?.expire),
      webPageUrl: Value(subInfo?.webPageUrl),
      supportUrl: Value(subInfo?.supportUrl),
      testUrl: Value(testUrl),
    );
  }
}

extension ProfileEntryMapper on ProfileEntry {
  ProfileEntity toEntity() {
    ProfileOptions? options;
    if (updateInterval != null) {
      options = ProfileOptions(updateInterval: updateInterval!);
    }

    SubscriptionInfo? subInfo;
    if (upload != null && download != null && total != null && expire != null) {
      subInfo = SubscriptionInfo(
        upload: upload!,
        download: download!,
        total: total!,
        expire: expire!,
        webPageUrl: webPageUrl,
        supportUrl: supportUrl,
      );
    }

    return switch (type) {
      ProfileType.remote => RemoteProfileEntity(
          id: id,
          active: active,
          name: name,
          url: url!,
          lastUpdate: lastUpdate,
          options: options,
          subInfo: subInfo,
          testUrl: testUrl,
        ),
      ProfileType.local => LocalProfileEntity(
          id: id,
          active: active,
          name: name,
          lastUpdate: lastUpdate,
          testUrl: testUrl,
        ),
    };
  }
}
