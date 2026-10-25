import 'package:dart_mappable/dart_mappable.dart';

part 'ip_info_entity.mapper.dart';

@MappableClass()
class IpInfo with IpInfoMappable {
  const IpInfo({
    required this.ip,
    required this.countryCode,
    this.region,
    this.city,
    this.timezone,
    this.asn,
    this.org,
  });

  final String ip;
  final String countryCode;
  final String? region;
  final String? city;
  final String? timezone;
  final String? asn;
  final String? org;

  /// Tries known response shapes until one parses. Used for custom `ipinfo-url`
  /// endpoints (and as a last-resort fallback for built-in sources).
  static IpInfo parseFlexible(Map<String, dynamic> json) {
    final parsers = <IpInfo Function(Map<String, dynamic>)>[
      fromIpApiJson,
      fromIpInfoIoJson,
      fromIpSbJson,
      fromIpwhoIsJson,
      fromIfconfigCoJson,
    ];
    Object? lastError;
    for (final parse in parsers) {
      try {
        return parse(json);
      } catch (e) {
        lastError = e;
      }
    }
    throw FormatException('unrecognized ip info json: $lastError');
  }

  /// ipapi.co / custom panel schema, e.g.
  /// `{ "ip", "city", "region", "country_code", "timezone", "asn": "AS1234", "org", ... }`.
  /// Optional fields may be missing or null; only `ip` + a country code are required.
  static IpInfo fromIpApiJson(Map<String, dynamic> json) {
    final ip = _string(json['ip']);
    final countryCode = _countryCode(json);
    if (ip == null || countryCode == null) {
      throw const FormatException('invalid ipapi json');
    }
    return IpInfo(
      ip: ip,
      countryCode: countryCode,
      region: _string(json['region']),
      city: _string(json['city']),
      timezone: _string(json['timezone']),
      asn: _asn(json['asn']),
      org: _string(json['org']),
    );
  }

  /// @Deprecated Use [fromIpApiJson].
  static IpInfo fromIpApiCoJson(Map<String, dynamic> json) => fromIpApiJson(json);

  static IpInfo fromIpInfoIoJson(Map<String, dynamic> json) {
    final ip = _string(json['ip']);
    // ipinfo.io uses `country` (ISO alpha-2), not `country_code`.
    final countryCode = _string(json['country']) ?? _string(json['country_code']);
    if (ip == null || countryCode == null) {
      throw const FormatException('invalid ipinfo.io json');
    }
    // `org` is often "AS12322 Free SAS" — split ASN when present.
    final orgRaw = _string(json['org']);
    String? asn = _asn(json['asn']);
    String? org = orgRaw;
    if (asn == null && orgRaw != null) {
      final match = RegExp(r'^(AS\d+)\s+(.*)$').firstMatch(orgRaw);
      if (match != null) {
        asn = match.group(1);
        org = match.group(2);
      }
    }
    return IpInfo(
      ip: ip,
      countryCode: countryCode,
      region: _string(json['region']),
      city: _string(json['city']),
      timezone: _string(json['timezone']),
      asn: asn,
      org: org,
    );
  }

  static IpInfo fromIpSbJson(Map<String, dynamic> json) {
    final ip = _string(json['ip']);
    final countryCode = _string(json['country_code']);
    if (ip == null || countryCode == null) {
      throw const FormatException('invalid ip.sb json');
    }
    return IpInfo(
      ip: ip,
      countryCode: countryCode,
      region: _string(json['region']),
      city: _string(json['city']),
      timezone: _string(json['timezone']),
      asn: _asn(json['asn']),
      org: _string(json['asn_organization']) ?? _string(json['organization']),
    );
  }

  static IpInfo fromIpwhoIsJson(Map<String, dynamic> json) {
    if (json['success'] == false) {
      throw FormatException('ipwho.is error: ${json['message']}');
    }
    final ip = _string(json['ip']);
    final countryCode = _string(json['country_code']);
    if (ip == null || countryCode == null) {
      throw const FormatException('invalid ipwho.is json');
    }

    String? asn;
    String? org;
    final connection = json['connection'];
    if (connection is Map) {
      asn = _asn(connection['asn']);
      org = _string(connection['org']);
    }

    String? timezone;
    final tz = json['timezone'];
    if (tz is Map) {
      timezone = _string(tz['id']);
    } else {
      timezone = _string(tz);
    }

    return IpInfo(
      ip: ip,
      countryCode: countryCode,
      region: _string(json['region']),
      city: _string(json['city']),
      timezone: timezone,
      asn: asn,
      org: org,
    );
  }

  static IpInfo fromIfconfigCoJson(Map<String, dynamic> json) {
    final ip = _string(json['ip']);
    final countryCode = _string(json['country_iso']) ?? _string(json['country_code']);
    if (ip == null || countryCode == null) {
      throw const FormatException('invalid ifconfig.co json');
    }
    return IpInfo(
      ip: ip,
      countryCode: countryCode,
      timezone: _string(json['time_zone']) ?? _string(json['timezone']),
      asn: _asn(json['asn']),
      org: _string(json['asn_org']) ?? _string(json['org']),
    );
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  /// Accepts `"FR"`, or falls back to `country` only when it looks like an ISO code.
  static String? _countryCode(Map<String, dynamic> json) {
    final code = _string(json['country_code']);
    if (code != null && code.length == 2) return code.toUpperCase();
    final country = _string(json['country']);
    if (country != null && country.length == 2) return country.toUpperCase();
    return code?.toUpperCase();
  }

  /// Normalizes `12322`, `"12322"`, or `"AS12322"` → `"AS12322"`.
  static String? _asn(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;
    final match = RegExp(r'^(?:AS)?(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match != null) return 'AS${match.group(1)}';
    return raw;
  }
}
