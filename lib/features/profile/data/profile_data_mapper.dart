import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

final _loggy = infraLogger('ProfileEntryMapper');

/// A profile's saved headers, or null for none. A profile without headers saves the text `null`;
/// headers that can not be read are left out, rather than the profile, and every other profile with
/// it, failing to load.
Map<String, dynamic>? decodeProfileHeaders(String? saved) {
  if (saved == null) return null;
  try {
    return switch (jsonDecode(saved)) {
      final Map<dynamic, dynamic> headers => headers.cast<String, dynamic>(),
      _ => null,
    };
  } catch (error, stackTrace) {
    _loggy.warning("a profile's saved headers can not be read, left out", error, stackTrace);
    return null;
  }
}

/// A profile's saved user override (the user's choices for it), or null for none. One that can not
/// be read, saved by a version whose shape this one no longer takes, is left out: the profile loads
/// with the subscription's own choices.
UserOverride? decodeUserOverride(String? saved) {
  try {
    return UserOverride.fromStr(saved);
  } catch (error, stackTrace) {
    _loggy.warning("a profile's saved choices can not be read, left out", error, stackTrace);
    return null;
  }
}

extension ProfileEntityMapper on ProfileEntity {
  ProfileEntriesCompanion toInsertEntry() => map(
    remote: (rp) => ProfileEntriesCompanion.insert(
      id: rp.id,
      type: ProfileType.remote,
      active: rp.active,
      name: rp.name,
      url: Value(rp.url),
      lastUpdate: rp.lastUpdate,
      updateInterval: Value(rp.options?.updateInterval),
      populatedHeaders: Value(jsonEncode(rp.populatedHeaders)),
      userOverride: Value(rp.userOverride?.toStr()),
      upload: Value(rp.subInfo?.upload),
      download: Value(rp.subInfo?.download),
      total: Value(rp.subInfo?.total),
      expire: Value(rp.subInfo?.expire),
      webPageUrl: Value(rp.webPageUrl),
      supportUrl: Value(rp.supportUrl),
      pinned: Value(rp.pinned),
    ),
    local: (lp) => ProfileEntriesCompanion.insert(
      id: lp.id,
      type: ProfileType.local,
      active: lp.active,
      name: lp.name,
      lastUpdate: lp.lastUpdate,
      populatedHeaders: Value(jsonEncode(lp.populatedHeaders)),
      userOverride: Value(lp.userOverride?.toStr()),
      pinned: Value(lp.pinned),
    ),
  );

  /// Note: `pinned` is intentionally omitted here so a subscription refresh
  /// never clobbers the user's pin; pinning is changed via a dedicated update.
  ProfileEntriesCompanion toUpdateEntry() => map(
    remote: (rp) => ProfileEntriesCompanion(
      name: Value(rp.name),
      lastUpdate: Value(rp.lastUpdate),
      updateInterval: Value(rp.options?.updateInterval),
      populatedHeaders: Value(jsonEncode(rp.populatedHeaders)),
      userOverride: Value(rp.userOverride?.toStr()),
      upload: Value(rp.subInfo?.upload),
      download: Value(rp.subInfo?.download),
      total: Value(rp.subInfo?.total),
      expire: Value(rp.subInfo?.expire),
      webPageUrl: Value(rp.webPageUrl),
      supportUrl: Value(rp.supportUrl),
    ),
    local: (lp) => ProfileEntriesCompanion(
      name: Value(lp.name),
      lastUpdate: Value(lp.lastUpdate),
      populatedHeaders: Value(jsonEncode(lp.populatedHeaders)),
      userOverride: Value(lp.userOverride?.toStr()),
    ),
  );
}

extension ProfileEntryMapper on ProfileEntry {
  ProfileEntity toEntity() {
    ProfileOptions? options;
    if (updateInterval != null) {
      options = ProfileOptions(updateInterval: updateInterval!);
    }

    SubscriptionInfo? subInfo;
    if (upload != null && download != null && total != null && expire != null) {
      subInfo = SubscriptionInfo(upload: upload!, download: download!, total: total!, expire: expire!);
    }
    final mPopulatedHeaders = decodeProfileHeaders(populatedHeaders);
    final mUserOverride = decodeUserOverride(userOverride);

    return switch (type) {
      ProfileType.remote => RemoteProfileEntity(
        id: id,
        active: active,
        name: name,
        // a remote profile saved without its URL still lists, to be fixed or removed
        url: url ?? '',
        lastUpdate: lastUpdate,
        options: options,
        subInfo: subInfo,
        webPageUrl: webPageUrl,
        supportUrl: supportUrl,
        populatedHeaders: mPopulatedHeaders,
        userOverride: mUserOverride,
        pinned: pinned,
      ),
      ProfileType.local => LocalProfileEntity(
        id: id,
        active: active,
        name: name,
        lastUpdate: lastUpdate,
        populatedHeaders: mPopulatedHeaders,
        userOverride: mUserOverride,
        pinned: pinned,
      ),
    };
  }
}
