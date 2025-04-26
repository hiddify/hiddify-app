import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_local_override.dart';
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
  static const infiniteTrafficThreshold = 92233720368;
  static const infiniteTimeThreshold = 92233720368;
  static const allowedOverrideConfigs = ['connection-test-url', 'direct-dns-address', 'remote-dns-address', 'warp', 'warp2', 'tls-tricks'];
  static const allowedProfileHeaders = ['profile-title', 'content-disposition', 'subscription-userinfo', 'profile-update-interval', 'support-url', 'profile-web-page-url', 'enable-warp', 'enable-fragment'];

  static RemoteProfileEntity parse(String url, Map<String, dynamic> headers, [ProfileLocalOverride? override]) {
    var name = '';
    if (override?.name case final String oName when oName.isNotEmpty) {
      name = oName;
    }

    if (headers['profile-title'] case final String titleHeader when name.isEmpty) {
      if (titleHeader.startsWith("base64:")) {
        name = utf8.decode(base64.decode(titleHeader.replaceFirst("base64:", "")));
      } else {
        name = titleHeader.trim();
      }
    }
    if (headers['content-disposition'] case final String contentDispositionHeader when name.isEmpty) {
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

    if (headers['enable-warp'].toString() == 'true' || override?.enableWarp == true) {
      final value = {
        'enable': true,
        'mode': 'warp_over_proxy',
      };
      headers['warp'] = value;
      headers['warp2'] = value;
    }

    if (headers['enable-fragment'].toString() == 'true' || override?.enableFragment == true) {
      headers['tls-tricks'] = {
        'enable-fragment': true,
      };
    }

    ProfileOptions? options;
    if (headers['profile-update-interval'] case final String updateIntervalStr) {
      final updateInterval = Duration(hours: int.parse(updateIntervalStr));
      options = ProfileOptions(updateInterval: updateInterval);
    }

    SubscriptionInfo? subInfo;
    if (headers['subscription-userinfo'] case final String subInfoStr) {
      subInfo = parseSubscriptionInfo(subInfoStr);
    }

    if (subInfo != null) {
      if (headers['profile-web-page-url'] case final String profileWebPageUrl when isUrl(profileWebPageUrl)) {
        subInfo = subInfo.copyWith(webPageUrl: profileWebPageUrl);
      }
      if (headers['support-url'] case final String profileSupportUrl when isUrl(profileSupportUrl)) {
        subInfo = subInfo.copyWith(supportUrl: profileSupportUrl);
      }
    }

    headers.removeWhere((key, value) => !allowedOverrideConfigs.contains(key) || value == null || value.toString().isEmpty);

    if (override != null) {
      headers[ProfileLocalOverride.key] = jsonEncode(override.toJson());
    }
    final testUrl = jsonEncode({for (final key in headers.keys) key: headers[key]});

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
    if (map case {"upload": final upload?, "download": final download?, "total": final total, "expire": var expire}) {
      final total1 = (total == null || total == 0) ? infiniteTrafficThreshold : total;
      expire = (expire == null || expire == 0) ? infiniteTimeThreshold : expire;
      return SubscriptionInfo(
        upload: upload,
        download: download,
        total: total1,
        expire: DateTime.fromMillisecondsSinceEpoch(expire * 1000),
      );
    }
    return null;
  }

  static Map<String, dynamic> populateHeaders({required String content, Map<String, dynamic> requestHeaders = const {}}) {
    final contentHeaders = _parseHeadersFromContent(content);
    return _mergeAndValidateHeaders(contentHeaders, requestHeaders: _fixRequestHeaders(requestHeaders));
  }

  static Map<String, dynamic> _parseHeadersFromContent(String content) {
    final headers = <String, dynamic>{};
    final content_ = safeDecodeBase64(content);
    final lines = content_.split("\n");
    final linesToProcess = lines.length < 10 ? lines.length : 10;
    for (int i = 0; i < linesToProcess; i++) {
      final line = lines[i];
      if (line.startsWith("#") || line.startsWith("//")) {
        final index = line.indexOf(':');
        if (index == -1) continue;
        final key = line.substring(0, index).replaceFirst(RegExp("^#|//"), "").trim().toLowerCase();
        final value = line.substring(index + 1).trim();
        headers[key] = value;
      }
    }
    return headers;
  }

  static Map<String, dynamic> _mergeAndValidateHeaders(Map<String, dynamic> contentHeaders, {Map<String, dynamic> requestHeaders = const {}}) {
    for (final entry in contentHeaders.entries) {
      if (!requestHeaders.keys.contains(entry.key)) {
        requestHeaders[entry.key] = entry.value;
      }
    }
    final headers = <String, dynamic>{};
    for (final entry in requestHeaders.entries) {
      if (allowedProfileHeaders.contains(entry.key) && entry.value != null && entry.value.toString().isNotEmpty) {
        headers[entry.key] = entry.value;
      }
    }
    return headers;
  }

  static Map<String, dynamic> _fixRequestHeaders(Map<String, dynamic> requestHeaders) {
    return requestHeaders.map((key, value) {
      if (value is List && value.length == 1) return MapEntry(key, value.first);
      return MapEntry(key, value);
    });
  }

  static Map<String, dynamic> mergeJson(Map<String, dynamic> main, Map<String, dynamic> override) {
    override.forEach((key, value) {
      if (main.containsKey(key)) {
        if (main[key] is Map<String, dynamic> && value is Map<String, dynamic>) {
          main[key] = mergeJson(main[key] as Map<String, dynamic>, value);
        } else {
          main[key] = value;
        }
      } else {
        main[key] = value;
      }
    });
    return main;
  }

  static ProfileLocalOverride? getLocalOverride(String? overrideStr) {
    ProfileLocalOverride? override;
    if (overrideStr != null) {
      final testUrlJson = jsonDecode(overrideStr) as Map<String, dynamic>;
      if (testUrlJson.containsKey(ProfileLocalOverride.key) && testUrlJson[ProfileLocalOverride.key] != null) {
        final overrideValue = testUrlJson[ProfileLocalOverride.key] as String;
        final overrideJson = jsonDecode(overrideValue) as Map<String, dynamic>;
        override = ProfileLocalOverride.fromJson(overrideJson);
      }
    }
    return override;
  }
}
