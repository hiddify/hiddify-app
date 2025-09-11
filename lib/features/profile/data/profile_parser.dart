import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:uuid/uuid.dart';

/// parse profile subscription url and headers for data
///
/// ***name parser hierarchy:***
/// - `profile-title` header
/// - `content-disposition` header
/// - url fragment (example: `https://example.com/config#user`) -> name=`user`
/// - url filename extension (example: `https://example.com/config.json`) -> name=`config`
/// - if none of these methods return a non-blank string, fallback to `Remote Profile`
abstract class ProfileParser {
  static const infiniteTrafficThreshold = 9223372036854775807;
  static const infiniteTimeThreshold = 92233720368;

  static RemoteProfileEntity parse(
    String url,
    Map<String, List<String>> headers,
  ) {
    var name = '';
    if (headers['profile-title'] case [final titleHeader]) {
      if (titleHeader.startsWith("base64:")) {
        name = utf8.decode(base64.decode(titleHeader.replaceFirst("base64:", "")));
      } else {
        name = titleHeader.trim();
      }
    }
    if (headers['content-disposition'] case [final contentDispositionHeader] when name.isEmpty) {
      final regExp = RegExp('filename="([^"]*)"');
      final match = regExp.firstMatch(contentDispositionHeader);
      if (match != null && match.groupCount >= 1) {
        name = match.group(1) ?? '';
      }
    }
    if (Uri.parse(url).fragment case final fragment when name.isEmpty) {
      name = fragment;
    }
    if (url.split("/").lastOrNull case final part? when name.isEmpty) {
      final pattern = RegExp(r"\.(json|yaml|yml|txt)[\s\S]*");
      name = part.replaceFirst(pattern, "");
    }
    if (name.isBlank) name = "Remote Profile";

    ProfileOptions? options;
    if (headers['profile-update-interval'] case [final updateIntervalStr]) {
      final updateInterval = Duration(hours: int.parse(updateIntervalStr));
      options = ProfileOptions(updateInterval: updateInterval);
    }
    String? testUrl;
    if (headers['test-url'] case [final testUrl_] when isUrl(testUrl_)) {
      testUrl = testUrl_;
    }
    SubscriptionInfo? subInfo;
    if (headers['subscription-userinfo'] case [final subInfoStr]) {
      subInfo = parseSubscriptionInfo(subInfoStr);
    }

    if (subInfo != null) {
      if (headers['profile-web-page-url'] case [final profileWebPageUrl] when isUrl(profileWebPageUrl)) {
        subInfo = subInfo.copyWith(webPageUrl: profileWebPageUrl);
      }
      if (headers['support-url'] case [final profileSupportUrl] when isUrl(profileSupportUrl)) {
        subInfo = subInfo.copyWith(supportUrl: profileSupportUrl);
      }
    }

    return RemoteProfileEntity(
      id: const Uuid().v4(),
      active: false,
      name: name,
      url: url,
      lastUpdate: DateTime.now(),
      options: options,
      subInfo: subInfo,
      testUrl: testUrl,
    );
  }

  static SubscriptionInfo? parseSubscriptionInfo(String subInfoStr) {
    final values = subInfoStr.split(';');
    final map = {
      for (final v in values) v.split('=').first.trim(): num.tryParse(v.split('=').second.trim())?.toInt(),
    };
    if (map case {"upload": final upload?, "download": final download?, "total": var total, "expire": var expire}) {
      total = (total == null || total == 0) ? infiniteTrafficThreshold : total;
      expire = (expire == null || expire == 0) ? infiniteTimeThreshold : expire;
      return SubscriptionInfo(
        upload: upload,
        download: download,
        total: total,
        expire: DateTime.fromMillisecondsSinceEpoch(expire * 1000),
      );
    }
    return null;
  }
}
