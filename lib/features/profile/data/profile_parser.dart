import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_proxy_type.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

/// parse profile subscription url and headers for data
///
/// ***name parser hierarchy:***
/// - UserOverride.name
/// - `profile-title` header
/// - `content-disposition` header
/// - url fragment (remote only, example: `https://example.com/config#user`) -> name=`user`
/// - url filename extension (remote only, example: `https://example.com/config.json`) -> name=`config`
/// - if none of these methods return a non-blank string, switch(profileType)
/// - remote:  fallback to `Remote Profile`
/// - local: fallback to protocol, extracted from content by protocol()
///
/// Note: the url-based steps (fragment, filename) apply to remote profiles only,
/// since local profiles have no url. Every step treats a whitespace-only result
/// as blank, so it falls through to the next step.

class ProfileParser {
  // Synthetic sentinel assigned to `total` for "unlimited" traffic (subscription-userinfo total=0 or
  // missing). It MUST stay above the 10 TB "unlimited" threshold the UI uses to decide whether to show
  // "∞" (isInfinitSize() in lib/utils/number_formatters.dart, and profile_tile.dart). The previous
  // value (~857 GiB) was below that gate, so total=0 rendered as a finite cap / "quota exceeded".
  // See https://github.com/hiddify/hiddify-app/issues/1974 . 1000 TiB.
  static const infiniteTrafficThreshold = 1_099_511_627_776_000;
  static const infiniteTimeThreshold = 92_233_720_368;
  static const allowedOverrideConfigs = [
    'connection-test-url',
    'direct-dns-address',
    'remote-dns-address',
    'tls-tricks',
    'chain-status',
    'extra-security',
  ];
  static const allowedProfileHeaders = [
    'profile-title',
    'content-disposition',
    'subscription-userinfo',
    'profile-update-interval',
    'support-url',
    'profile-web-page-url',
    'extra-security',
    'fragment',
  ];

  final Ref _ref;
  final DioHttpClient _httpClient;

  ProfileParser({required Ref ref, required DioHttpClient httpClient}) : _ref = ref, _httpClient = httpClient;
  TaskEither<ProfileFailure, ProfileEntriesCompanion> addLocal({
    required String id,
    required String content,
    required String tempFilePath,
    required UserOverride? userOverride,
  }) {
    return TaskEither.tryCatch(() async {
          await expandRemoteLinesInParallel(
            tempFilePath: tempFilePath,
            httpClient: _httpClient,
            cancelToken: CancelToken(),
            ref: _ref,
          );
        }, (_, _) => const ProfileFailure.unexpected())
        .flatMap((_) => TaskEither.fromEither(populateHeaders(content: content)))
        .flatMap(
          (populatedHeaders) => TaskEither.fromEither(
            parse(
              tempFilePath: tempFilePath,
              profile: ProfileEntity.local(
                id: id,
                active: true,
                name: '',
                lastUpdate: DateTime.now(),
                userOverride: userOverride,
                populatedHeaders: populatedHeaders,
              ),
            ).flatMap((profEntity) => Either.tryCatch(() => profEntity.toInsertEntry(), ProfileFailure.unexpected)),
          ),
        );
  }

  TaskEither<ProfileFailure, ProfileEntriesCompanion> addRemote({
    required String id,
    required String url,
    required String tempFilePath,
    required UserOverride? userOverride,
    CancelToken? cancelToken,
  }) => _downloadProfile(url, tempFilePath, cancelToken).flatMap(
    (remoteHeaders) =>
        TaskEither.fromEither(
          populateHeaders(content: File(tempFilePath).readAsStringSync(), remoteHeaders: remoteHeaders),
        ).flatMap(
          (populatedHeaders) => TaskEither.fromEither(
            parse(
              tempFilePath: tempFilePath,
              profile: ProfileEntity.remote(
                id: id,
                active: true,
                name: '',
                url: url,
                lastUpdate: DateTime.now(),
                userOverride: userOverride,
                populatedHeaders: populatedHeaders,
              ),
            ).flatMap((profEntity) => Either.tryCatch(() => profEntity.toInsertEntry(), ProfileFailure.unexpected)),
          ),
        ),
  );

  TaskEither<ProfileFailure, ProfileEntriesCompanion> updateRemote({
    required RemoteProfileEntity rp,
    required String tempFilePath,
    CancelToken? cancelToken,
  }) => _downloadProfile(rp.url, tempFilePath, cancelToken).flatMap(
    (remoteHeaders) =>
        TaskEither.fromEither(
          populateHeaders(content: File(tempFilePath).readAsStringSync(), remoteHeaders: remoteHeaders),
        ).flatMap(
          (populatedHeaders) => TaskEither.fromEither(
            parse(
              tempFilePath: tempFilePath,
              profile: rp.copyWith(populatedHeaders: populatedHeaders),
            ).flatMap((profEntity) => Either.tryCatch(() => profEntity.toUpdateEntry(), ProfileFailure.unexpected)),
          ),
        ),
  );

  Either<ProfileFailure, ProfileEntriesCompanion> offlineUpdate({
    required ProfileEntity profile,
    required String tempFilePath,
  }) => profile
      .map(
        remote: (rp) => parse(profile: rp, tempFilePath: tempFilePath),
        local: (lp) => parse(tempFilePath: tempFilePath, profile: lp),
      )
      .flatMap((profEntity) => Either.tryCatch(() => profEntity.toUpdateEntry(), ProfileFailure.unexpected));

  TaskEither<ProfileFailure, Map<String, dynamic>> _downloadProfile(
    String url,
    String tempFilePath,
    CancelToken? cancelToken,
  ) => TaskEither.tryCatch(() async {
    // if (url.startsWith("http://"))
    //   throw const ProfileFailure.invalidUrl('HTTP is not supported. Please use HTTPS for secure connection.');

    final rs = await _httpClient
        .download(
          url.trim(),
          tempFilePath,
          cancelToken: cancelToken,
          userAgent: _ref.read(ConfigOptions.useXrayCoreWhenPossible)
              ? _httpClient.userAgent.replaceAll("HiddifyNext", "HiddifyNextX")
              : null,
        )
        .catchError((err) {
          if (CancelToken.isCancel(err as DioException)) {
            throw const ProfileFailure.cancelByUser('HTTP request for getting profile content canceled by user.');
          }
          throw err;
        });
    await expandRemoteLinesInParallel(
      tempFilePath: tempFilePath,
      httpClient: _httpClient,
      cancelToken: cancelToken ?? CancelToken(),
      ref: _ref,
    );
    // fixing headers before return
    return rs.headers.map.map((key, value) {
      if (value.length == 1) return MapEntry(key, value.first);
      return MapEntry(key, value);
    });
  }, (err, st) => err is ProfileFailure ? err : ProfileFailure.unexpected(err, st));
  Future<void> expandRemoteLinesInParallel({
    required String tempFilePath,
    required DioHttpClient httpClient,
    required CancelToken cancelToken,
    required Ref ref,
    int parallelism = 4,
  }) async {
    final content = await File(tempFilePath).readAsString();
    final lines = content.split('\n');

    final results = List<String?>.filled(lines.length, null);

    int index = 0;

    Future<void> worker() async {
      while (true) {
        if (cancelToken.isCancelled) return;

        final currentIndex = index++;
        if (currentIndex >= lines.length) return;

        final line = lines[currentIndex];

        // Non-URL
        if (!line.startsWith('http://') && !line.startsWith('https://')) {
          results[currentIndex] = line.trim();
          continue;
        }

        try {
          final tmpPath = '$tempFilePath.$currentIndex';

          await httpClient.download(
            line,
            tmpPath,
            cancelToken: cancelToken,
            userAgent: ref.read(ConfigOptions.useXrayCoreWhenPossible)
                ? httpClient.userAgent.replaceAll('HiddifyNext', 'HiddifyNextX')
                : null,
          );

          results[currentIndex] = (await File(tmpPath).readAsString()).trim();
        } catch (err) {
          if (err is DioException && CancelToken.isCancel(err)) {
            return;
          }
          results[currentIndex] = '';
        }
      }
    }

    // Start workers
    await Future.wait(List.generate(parallelism, (_) => worker()));

    if (results.any((e) => e != null)) {
      final newContent = results.join("\n");
      await File(tempFilePath).writeAsString(newContent);
    }
  }

  static Either<ProfileFailure, Map<String, dynamic>> populateHeaders({
    required String content,
    Map<String, dynamic>? remoteHeaders,
  }) => Either.tryCatch(() {
    final contentHeaders = _parseHeadersFromContent(content);
    return _mergeAndValidateHeaders(contentHeaders, remoteHeaders ?? {});
  }, ProfileFailure.unexpected);

  static Map<String, dynamic> _mergeAndValidateHeaders(
    Map<String, dynamic> contentHeaders,
    Map<String, dynamic> remoteHeaders,
  ) {
    for (final entry in contentHeaders.entries) {
      if (!remoteHeaders.keys.contains(entry.key)) {
        remoteHeaders[entry.key] = entry.value;
      }
    }
    final headers = <String, dynamic>{};
    for (final entry in remoteHeaders.entries) {
      if (allowedProfileHeaders.contains(entry.key) && entry.value != null && entry.value.toString().isNotEmpty) {
        headers[entry.key] = entry.value;
      }
    }
    return headers;
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

  /// Parse a `subscription-userinfo` header, e.g.
  /// `upload=0; download=1024; total=10240; expire=1704054600`.
  ///
  /// Tolerant of real-world noise: a segment without a `key=value` pair (a
  /// stray `;;`, a trailing `;`, or a malformed token) is skipped instead of
  /// throwing and failing the whole profile parse. Values may be decimals and
  /// are truncated to int. `upload` and `download` are required; a missing or
  /// `0` `total`/`expire` is treated as "unlimited".
  static SubscriptionInfo? _parseSubscriptionInfo(String subInfoStr) {
    final map = <String, int?>{};
    for (final segment in subInfoStr.split(';')) {
      final parts = segment.split('=');
      if (parts.length < 2) continue;
      final key = parts.first.trim();
      if (key.isEmpty) continue;
      map[key] = num.tryParse(parts[1].trim())?.toInt();
    }
    if (map case {"upload": final upload?, "download": final download?, "total": final total, "expire": var expire}) {
      final total1 = (total == null || total == 0) ? infiniteTrafficThreshold + 1 : total;
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

  /// Extract a filename from a `content-disposition` header.
  ///
  /// Prefers the RFC 5987 extended form `filename*=UTF-8''<percent-encoded>`,
  /// which is how servers send non-ASCII names (Persian, Chinese, emoji …),
  /// and falls back to the plain quoted form `filename="name.txt"`. Returns ''
  /// when neither is present or the extended value can't be decoded.
  @visibleForTesting
  static String filenameFromContentDisposition(String header) {
    // filename*=charset'lang'<percent-encoded-value>; charset'lang' is optional here to
    // also accept servers that omit it (filename*=%D9%BE...).
    if (RegExp(r"filename\*\s*=\s*(?:[^']*'[^']*')?([^;]+)", caseSensitive: false).firstMatch(header) case final m?) {
      final raw = m.group(1)?.trim() ?? '';
      if (raw.isNotEmpty) {
        try {
          return Uri.decodeComponent(raw);
        } catch (_) {
          // Malformed percent-encoding → fall back to the quoted form below.
        }
      }
    }
    if (RegExp('filename="([^"]*)"').firstMatch(header) case final m?) {
      return m.group(1) ?? '';
    }
    return '';
  }

  @visibleForTesting
  static Either<ProfileFailure, ProfileEntity> parse({required String tempFilePath, required ProfileEntity profile}) =>
      Either.tryCatch(() {
        final headers = Map<String, dynamic>.from(profile.populatedHeaders ?? {});
        var name = '';
        if (profile.userOverride?.name case final String oName when oName.isNotBlank) {
          name = oName;
        }

        if (headers['profile-title'] case final String titleHeader when name.isBlank) {
          if (titleHeader.startsWith("base64:")) {
            name = utf8.decode(base64.decode(titleHeader.replaceFirst("base64:", "")));
          } else {
            name = titleHeader.trim();
          }
        }
        if (headers['content-disposition'] case final String contentDispositionHeader when name.isBlank) {
          name = filenameFromContentDisposition(contentDispositionHeader);
        }
        if (profile case RemoteProfileEntity(:final url)) {
          if (Uri.parse(url).fragment case final fragment when name.isBlank) {
            name = fragment;
          }
          if (url.split("/").lastOrNull case final part? when name.isBlank) {
            final pattern = RegExp(r"\.(json|yaml|yml|txt)[\s\S]*");
            name = part.replaceFirst(pattern, "");
          }
        }
        if (name.isBlank) {
          switch (profile) {
            case RemoteProfileEntity():
              name = "Remote Profile";

            case LocalProfileEntity():
              name = protocol(File(tempFilePath).readAsStringSync());
          }
        }

        final isAutoUpdateDisable = profile.userOverride?.isAutoUpdateDisable ?? false;
        ProfileOptions? options;
        if (profile.userOverride?.updateInterval case final int updateInterval
            when updateInterval > 0 && !isAutoUpdateDisable) {
          options = ProfileOptions(updateInterval: Duration(hours: updateInterval));
        }
        if (headers['profile-update-interval'] case final String updateIntervalStr
            when options == null && !isAutoUpdateDisable) {
          // Convention: a positive integer number of hours. Ignore anything else
          // (a decimal, garbage, or <= 0) instead of failing the whole parse.
          if (int.tryParse(updateIntervalStr.trim()) case final hours? when hours > 0) {
            options = ProfileOptions(updateInterval: Duration(hours: hours));
          }
        }

        SubscriptionInfo? subInfo;
        if (headers['subscription-userinfo'] case final String subInfoStr) {
          subInfo = _parseSubscriptionInfo(subInfoStr);
        }

        // Standalone headers: valid with or without `subscription-userinfo`.
        String? webPageUrl;
        if (headers['profile-web-page-url'] case final String profileWebPageUrl when isUrl(profileWebPageUrl)) {
          webPageUrl = profileWebPageUrl;
        }
        String? supportUrl;
        if (headers['support-url'] case final String profileSupportUrl when isUrl(profileSupportUrl)) {
          supportUrl = profileSupportUrl;
        }

        return profile.map(
          remote: (rp) => rp.copyWith(
            name: name,
            lastUpdate: DateTime.now(),
            options: options,
            subInfo: subInfo,
            webPageUrl: webPageUrl,
            supportUrl: supportUrl,
          ),
          local: (lp) => lp.copyWith(name: name, lastUpdate: DateTime.now()),
        );
      }, ProfileFailure.unexpected);

  static String protocol(String content) {
    if (content.contains("[Interface]")) {
      return ProxyType.wireguard.label;
    }
    final lines = content.split('\n');
    String? name;
    for (final line in lines) {
      final uri = Uri.tryParse(line);
      if (uri == null) continue;
      final fragment = uri.hasFragment ? Uri.decodeComponent(uri.fragment.split(" -> ")[0]) : null;
      name ??= switch (uri.scheme) {
        'ss' => fragment ?? ProxyType.shadowsocks.label,
        'ssconf' => fragment ?? ProxyType.shadowsocks.label,
        'vmess' => ProxyType.vmess.label,
        'vless' => fragment ?? ProxyType.vless.label,
        'trojan' => fragment ?? ProxyType.trojan.label,
        'tuic' => fragment ?? ProxyType.tuic.label,
        'hy2' || 'hysteria2' => fragment ?? ProxyType.hysteria2.label,
        'hy' || 'hysteria' => fragment ?? ProxyType.hysteria.label,
        'ssh' => fragment ?? ProxyType.ssh.label,
        'wg' => fragment ?? ProxyType.wireguard.label,
        'awg' => fragment ?? ProxyType.awg.label,
        'shadowtls' => fragment ?? ProxyType.shadowtls.label,
        'mieru' => fragment ?? ProxyType.mieru.label,
        'warp' => fragment ?? ProxyType.warp.label,
        _ => null,
      };
    }
    return name ?? ProxyType.unknown.label;
  }

  static String profileOverrideHelper({required ProfileEntriesCompanion profile}) {
    final populatedHeaders = profile.populatedHeaders.value;

    Map<String, dynamic>? mPopulatedHeaders;
    if (populatedHeaders != null) {
      final m = jsonDecode(populatedHeaders) as Map;
      mPopulatedHeaders = m.cast<String, dynamic>();
    }

    return ProfileParser.profileOverride(
      populatedHeaders: mPopulatedHeaders,
      userOverride: UserOverride.fromStr(profile.userOverride.value),
    );
  }

  /// Resolve an `extra-security` value to a chain mode.
  ///
  /// Strict on purpose: the value must equal a documented mode key exactly, or
  /// it is ignored. `profile` is not accepted — chaining to another profile is a
  /// user choice, not something a subscription may impose.
  @visibleForTesting
  static ChainMode? extraSecurityMode(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    for (final mode in ChainMode.values) {
      if (mode.isProfile()) continue;
      if (mode.key == trimmed) return mode;
    }
    return null;
  }

  /// Build the `tls-tricks` map from a subscription `fragment` header.
  ///
  /// Mirrors the per-proxy `fragment` parameter, which needs a full triplet —
  /// `size,sleep,method` or `tlshello,size,sleep`. Anything shorter, or a size
  /// or sleep that isn't a valid range, is incomplete and turns fragmentation
  /// off entirely rather than enabling it with half the values. Returns null
  /// when the header can't be used.
  @visibleForTesting
  static Map<String, dynamic>? fragmentTricks(String? value) {
    if (value == null) return null;
    final parts = value.split(',').map((e) => e.trim()).toList();
    if (parts.length < 3) return null;
    final leadingMethod = parts.first.toLowerCase() == 'tlshello';
    final size = leadingMethod ? parts[1] : parts[0];
    final sleep = leadingMethod ? parts[2] : parts[1];
    if (OptionalRange.tryParse(size) == null || OptionalRange.tryParse(sleep) == null) return null;
    return {'enable-fragment': true, 'fragment-size': size, 'fragment-sleep': sleep};
  }

  static String profileOverride({
    required Map<String, dynamic>? populatedHeaders,
    required UserOverride? userOverride,
  }) {
    final headers = Map<String, dynamic>.from(populatedHeaders ?? {});

    // Consume the raw subscription inputs; the output config uses structured
    // keys, so these string values must not leak through unchanged.
    final fragmentInput = headers.remove('fragment')?.toString();
    final extraSecurityInput = headers.remove('extra-security')?.toString();

    // extra-security: exactly one documented mode. The app's own setting takes
    // precedence over the subscription; an unrecognised value is ignored.
    final mode = extraSecurityMode(userOverride?.extraSecurity) ?? extraSecurityMode(extraSecurityInput);
    if (mode != null) {
      headers['chain-status'] = ChainStatus.extraSecurity.key;
      headers['extra-security'] = {'mode': mode.key};
    }

    // fragment: the app's own setting wins and enables fragmentation with the
    // user's configured size/sleep. Otherwise the subscription header is read
    // exactly like a proxy link's `fragment` parameter — a complete triplet or
    // nothing at all.
    if (userOverride?.enableFragment == true) {
      headers['tls-tricks'] = {'enable-fragment': true};
    } else if (fragmentTricks(fragmentInput) case final tricks?) {
      headers['tls-tricks'] = tricks;
    }

    headers.removeWhere(
      (key, value) => !allowedOverrideConfigs.contains(key) || value == null || value.toString().isEmpty,
    );

    final profileOverrideStr = jsonEncode({for (final key in headers.keys) key: headers[key]});
    return profileOverrideStr;
  }

  static Map<String, dynamic> applyProfileOverride(Map<String, dynamic> main, String? profileOverride) {
    if (profileOverride == null) return main;
    if (profileOverride.contains("{")) {
      final profileOverrideMap = jsonDecode(profileOverride) as Map<String, dynamic>;
      return _mergeJson(main, profileOverrideMap);
    } else {
      return main;
    }
  }

  static Map<String, dynamic> _mergeJson(Map<String, dynamic> main, Map<String, dynamic> override) {
    override.forEach((key, value) {
      if (main.containsKey(key)) {
        if (main[key] is Map<String, dynamic> && value is Map<String, dynamic>) {
          main[key] = _mergeJson(main[key] as Map<String, dynamic>, value);
        } else {
          main[key] = value;
        }
      } else {
        main[key] = value;
      }
    });
    return main;
  }
}
