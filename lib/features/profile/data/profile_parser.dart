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
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_proxy_type.dart';
import 'package:hiddify/utils/utils.dart';
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
/// - local: keep the existing name, otherwise extract it from content by protocol()
///
/// Note: the url-based steps (fragment, filename) apply to remote profiles only,
/// since local profiles have no url. Every step treats a whitespace-only result
/// as blank, so it falls through to the next step.

class ProfileParser with InfraLogger {
  // Synthetic sentinel assigned to `total` for "unlimited" traffic (subscription-userinfo total=0 or
  // missing). It MUST stay above the 10 TB "unlimited" threshold the UI uses to decide whether to show
  // "∞" (isInfinitSize() in lib/utils/number_formatters.dart, and profile_tile.dart). The previous
  // value (~857 GiB) was below that gate, so total=0 rendered as a finite cap / "quota exceeded".
  // See https://github.com/hiddify/hiddify-app/issues/1974 . 1000 TiB.
  static const infiniteTrafficThreshold = 1_099_511_627_776_000;
  static const infiniteTimeThreshold = 92_233_720_368;
  static const allowedOverrideConfigs = [
    'ipv6-mode',
    'connection-test-url',
    'ipinfo-url',
    'direct-dns-address',
    'remote-dns-address',
    'tls-tricks',
    'chain-status',
    'extra-security',
    'keep-top',
    'keep-top-quick',
    'keep-top-countries',
    'keep-tags',
  ];
  static const allowedProfileHeaders = [
    'profile-title',
    'content-disposition',
    'subscription-userinfo',
    'profile-update-interval',
    'support-url',
    'profile-web-page-url',
    'ipinfo-url',
    'extra-security',
    'fragment',
    'keep-top',
  ];

  final DioHttpClient _httpClient;

  ProfileParser({required DioHttpClient httpClient}) : _httpClient = httpClient;
  TaskEither<ProfileFailure, ProfileEntriesCompanion> addLocal({
    required String id,
    required String content,
    required String tempFilePath,
    required UserOverride? userOverride,
  }) {
    return TaskEither.fromEither(populateHeaders(content: content)).flatMap(
      (populatedHeaders) => _expandLinksInFile(tempFilePath, null).flatMap(
        (_) => TaskEither.fromEither(
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
          (populatedHeaders) => _expandLinksInFile(tempFilePath, cancelToken).flatMap(
            (_) => TaskEither.fromEither(
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
          (populatedHeaders) => _expandLinksInFile(tempFilePath, cancelToken).flatMap(
            (_) => TaskEither.fromEither(
              parse(
                tempFilePath: tempFilePath,
                profile: rp.copyWith(populatedHeaders: populatedHeaders),
              ).flatMap((profEntity) => Either.tryCatch(() => profEntity.toUpdateEntry(), ProfileFailure.unexpected)),
            ),
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

    final rs = await _httpClient.download(url.trim(), tempFilePath, cancelToken: cancelToken).catchError((err) {
      if (CancelToken.isCancel(err as DioException)) {
        throw const ProfileFailure.cancelByUser('HTTP request for getting profile content canceled by user.');
      }
      throw err;
    });
    // fixing headers before return
    return rs.headers.map.map((key, value) {
      if (value.length == 1) return MapEntry(key, value.first);
      return MapEntry(key, value);
    });
  }, (err, st) => err is ProfileFailure ? err : ProfileFailure.unexpected(err, st));

  /// Replaces every subscription link line in [text] with the content it points to.
  ///
  /// Returns [text] unchanged when no line is a link.
  Future<String> expandLinks(String text, CancelToken cancelToken) async {
    final lines = text.split('\n');
    if (!lines.any(_isSubscriptionLink)) return text;

    final results = List<String?>.filled(lines.length, null);
    int index = 0;

    Future<void> worker() async {
      while (true) {
        if (cancelToken.isCancelled) return;

        final currentIndex = index++;
        if (currentIndex >= lines.length) return;

        final line = lines[currentIndex];
        if (!_isSubscriptionLink(line)) {
          results[currentIndex] = line;
          continue;
        }

        try {
          final response = await _httpClient.get<String>(
            line.trimRight(),
            cancelToken: cancelToken,
            responseType: ResponseType.plain,
          );
          results[currentIndex] = (response.data ?? '').trim();
        } catch (err) {
          if (err is DioException && CancelToken.isCancel(err)) return;
          // the full url carries the user's token, so only the host is logged
          loggy.warning(
            'dropped an inner subscription link that failed to download: ${Uri.tryParse(line.trimRight())?.host}',
          );
          results[currentIndex] = '';
        }
      }
    }

    // 4 downloads at a time
    await Future.wait(List.generate(4, (_) => worker()));
    if (cancelToken.isCancelled) {
      throw const ProfileFailure.cancelByUser('HTTP request for getting an inner subscription link canceled by user.');
    }
    return results.join('\n');
  }

  /// An http(s) line is a subscription link only when its URL has a path. HTTP proxy links have none: the core reads
  /// their options from the query.
  static bool _isSubscriptionLink(String line) {
    if (!line.startsWith('http://') && !line.startsWith('https://')) return false;
    final path = Uri.tryParse(line.trimRight())?.path ?? '';
    return path.isNotEmpty && path != '/';
  }

  /// Expands the links in the temp file and writes the file once, only if the text changed.
  TaskEither<ProfileFailure, Unit> _expandLinksInFile(String tempFilePath, CancelToken? cancelToken) =>
      TaskEither.tryCatch(() async {
        final file = File(tempFilePath);
        final text = safeDecodeBase64((await file.readAsString()).trim());
        final expanded = await expandLinks(text, cancelToken ?? CancelToken());
        if (expanded != text) await file.writeAsString(expanded);
        return unit;
      }, (err, st) => err is ProfileFailure ? err : ProfileFailure.unexpected(err, st));

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
  /// are truncated to int. `upload` and `download` are required; a missing,
  /// `0` or unreadable `total`/`expire` is treated as "unlimited", and so is an
  /// `expire` past [infiniteTimeThreshold].
  static SubscriptionInfo? _parseSubscriptionInfo(String subInfoStr) {
    final map = <String, int?>{};
    for (final segment in subInfoStr.split(';')) {
      final parts = segment.split('=');
      if (parts.length < 2) continue;
      final key = parts.first.trim();
      if (key.isEmpty) continue;
      // NaN, infinity and negatives count as unreadable: toInt() throws on the first two.
      final value = num.tryParse(parts[1].trim());
      map[key] = (value == null || !value.isFinite || value < 0) ? null : value.toInt();
    }
    if (map case {"upload": final upload?, "download": final download?, "total": final total, "expire": var expire}) {
      final total1 = (total == null || total == 0) ? infiniteTrafficThreshold + 1 : total;
      // An expiry past the threshold is no expiry; it may also be beyond what DateTime holds.
      expire = (expire == null || expire == 0 || expire > infiniteTimeThreshold) ? infiniteTimeThreshold : expire;
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

  /// Decode the value of a `profile-title: base64:<value>` header.
  ///
  /// Accepts the value without `=` padding, which some servers send. Returns ''
  /// when it is not valid base64 or not UTF-8, so the name falls through to the
  /// next source instead of failing the whole profile parse.
  @visibleForTesting
  static String decodeBase64Title(String value) {
    try {
      return utf8.decode(base64.decode(base64.normalize(value.trim()))).trim();
    } on FormatException {
      return '';
    }
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
            name = decodeBase64Title(titleHeader.replaceFirst("base64:", ""));
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
              // The editor saves generated JSON, so the original link fragment
              // is no longer available. Keep the profile name independently of
              // outbound tags unless an override or header supplies a new name.
              name = profile.name.isNotBlank ? profile.name : protocol(File(tempFilePath).readAsStringSync());
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
        // `ipinfo-url` stays in populatedHeaders only (not a dedicated column).

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
    // a .ovpn file: its certificate inline, and the server it connects to
    if (content.contains('<ca>') && RegExp(r'^\s*remote\s', multiLine: true).hasMatch(content)) {
      return 'OpenVPN';
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
        'ovpn' => fragment ?? 'OpenVPN',
        // any other link (psiphon://, anytls://, naive+https://, ...): its name, else its scheme
        final scheme when scheme.isNotEmpty && line.trimLeft().startsWith('$scheme://') =>
          fragment ?? _schemeLabel(scheme),
        _ => null,
      };
    }
    return name ?? ProxyType.unknown.label;
  }

  /// Display label for a link scheme: the matching [ProxyType] label (naive+https -> Naive),
  /// otherwise the capitalized scheme (psiphon -> Psiphon).
  static String _schemeLabel(String scheme) {
    final base = scheme.split('+').first;
    final type = ProxyType.fromJson(base);
    if (type != ProxyType.unknown) return type.label;
    return base[0].toUpperCase() + base.substring(1);
  }

  static String profileOverrideHelper({required ProfileEntriesCompanion profile}) {
    return ProfileParser.profileOverride(
      populatedHeaders: decodeProfileHeaders(profile.populatedHeaders.value),
      userOverride: decodeUserOverride(profile.userOverride.value),
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
      // a subscription calls it "warp"; the core's key for it is "warp_auto"
      if (mode.key == trimmed || (mode.isWarp() && trimmed == 'warp')) return mode;
    }
    return null;
  }

  /// A `keep-top` header: how many proxies to keep running, or -1 for all. Anything else is no
  /// header at all.
  static int? keepTopHeader(String? value) {
    final keepTop = int.tryParse(value?.trim() ?? '');
    if (keepTop == null || (keepTop < 1 && keepTop != -1)) return null;
    return keepTop;
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
    final keepTopInput = headers.remove('keep-top')?.toString();
    // the user's choices only, never a subscription's
    headers.remove('keep-top-quick');
    headers.remove('keep-top-countries');

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

    // keep-top: the user's choice, else the subscription's; -1 (or none) runs every proxy
    if (userOverride?.keepTop ?? keepTopHeader(keepTopInput) case final keepTop?) {
      headers['keep-top'] = keepTop;
    }
    // keep-top-quick: picks the fastest without testing every proxy, unless the user turned it off
    if (userOverride?.keepTopQuick ?? true) {
      headers['keep-top-quick'] = true;
    }
    // keep-top-countries: only proxies of these countries are kept
    if (userOverride?.keepTopCountries case final countries? when countries.isNotEmpty) {
      headers['keep-top-countries'] = countries;
    }
    // keep-tags: the proxies the user chose run, and only them, while any is still in the profile
    if (userOverride?.keepTags case final tags? when tags.isNotEmpty) {
      headers['keep-tags'] = tags;
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
