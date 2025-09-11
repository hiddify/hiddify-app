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

  static IpInfo fromIpInfoIoJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "ip": final String ip,
        "country": final String country,
        // "region": final String region, //sometime is not available
        // "city": final String city,//sometime is not available
        "timezone": final String timezone,
        "org": final String org,
      } =>
        IpInfo(
          ip: ip,
          countryCode: country,
          // region: region,
          // city: city,
          timezone: timezone,
          org: org,
        ),
      _ => throw const FormatException("invalid json"),
    };
  }

  static IpInfo fromIpApiCoJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "ip": final String ip,
        "country_code": final String countryCode,
        // "region": final String region, //sometime is not available
        // "city": final String city,//sometime is not available
        "timezone": final String timezone,
        "asn": final String asn,
        "org": final String org,
      } =>
        IpInfo(
          ip: ip,
          countryCode: countryCode,
          // region: region,
          // city: city,
          timezone: timezone,
          asn: asn,
          org: org,
        ),
      _ => throw const FormatException("invalid json"),
    };
  }

  static IpInfo fromIpSbJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "ip": final String ip,
        "country_code": final String countryCode,
        // "region": final String region,
        // "city": final String city,
        "timezone": final String timezone,
        "asn": final int asn,
        "asn_organization": final String org,
      } =>
        IpInfo(
          ip: ip,
          countryCode: countryCode,
          // region: region,
          // city: city,
          timezone: timezone,
          asn: '$asn',
          org: org,
        ),
      _ => throw const FormatException("invalid json"),
    };
  }

  static IpInfo fromIpwhoIsJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "ip": final String ip,
        "country_code": final String countryCode,
        // "region": final String region,
        // "city": final String city,
        // "timezone": final String timezone,
        // "asn": final int asn,
        "connection": final Map<String, dynamic> connection,
      } =>
        IpInfo(
          ip: ip,
          countryCode: countryCode,
          // region: region,
          // city: city,
          // timezone: timezone,
          asn: '$connection["asn"]',
          org: '$connection["org"]',
        ),
      _ => throw const FormatException("invalid json"),
    };
  }

  static IpInfo fromGeolocationDbComJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "ip": final String ip,
        "country_code": final String countryCode,
        // "state": final String region,
        "city": final String city
      } =>
        IpInfo(
          ip: ip,
          countryCode: countryCode,
          // region: region,
          city: city,
        ),
      _ => throw const FormatException("invalid json"),
    };
  }
}
