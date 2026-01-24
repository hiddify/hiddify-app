import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/platform_utils.dart';

@JsonEnum(valueField: 'key')
enum ServiceMode {
  proxy("proxy"),
  systemProxy("system-proxy"),
  tun("vpn"),
  tunService("vpn-service");

  const ServiceMode(this.key);

  final String key;

  static ServiceMode get defaultMode => PlatformUtils.isDesktop ? systemProxy : tun;

  /// supported service mode based on platform, use this instead of [values] in UI
  static List<ServiceMode> get choices {
    if (Platform.isWindows || Platform.isLinux) {
      return values;
    } else if (Platform.isMacOS) {
      return [proxy, systemProxy, tun];
    }
    // mobile
    return [proxy, tun];
  }

  // bool get isExperimental => switch (this) {
  //       tun => PlatformUtils.isDesktop,
  //       tunService => PlatformUtils.isDesktop,
  //       _ => false,
  //     };

  String present(TranslationsEn t) => switch (this) {
    proxy => t.pages.settings.inbound.serviceModes.proxy,
    systemProxy => t.pages.settings.inbound.serviceModes.systemProxy,
    tun => t.pages.settings.inbound.serviceModes.tun,
    tunService => t.pages.settings.inbound.serviceModes.tunService,
  };

  String presentShort(TranslationsEn t) => switch (this) {
    proxy => t.pages.settings.inbound.shortServiceModes.proxy,
    systemProxy => t.pages.settings.inbound.shortServiceModes.systemProxy,
    tun => t.pages.settings.inbound.shortServiceModes.tun,
    tunService => t.pages.settings.inbound.shortServiceModes.tunService,
  };
}

@JsonEnum(valueField: 'key')
enum IPv6Mode {
  disable("ipv4_only"),
  enable("prefer_ipv4"),
  prefer("prefer_ipv6"),
  only("ipv6_only");

  const IPv6Mode(this.key);

  final String key;

  String present(TranslationsEn t) => switch (this) {
    disable => t.pages.settings.routing.ipv6Modes.disable,
    enable => t.pages.settings.routing.ipv6Modes.enable,
    prefer => t.pages.settings.routing.ipv6Modes.prefer,
    only => t.pages.settings.routing.ipv6Modes.only,
  };
}

@JsonEnum(valueField: 'key')
enum DomainStrategy {
  auto(""),
  preferIpv6("prefer_ipv6"),
  preferIpv4("prefer_ipv4"),
  ipv4Only("ipv4_only"),
  ipv6Only("ipv6_only");

  const DomainStrategy(this.key);

  final String key;

  String present(TranslationsEn t) => switch (this) {
    auto => t.pages.settings.dns.domainStrategy.auto,
    preferIpv6 => t.pages.settings.dns.domainStrategy.preferIpv6,
    preferIpv4 => t.pages.settings.dns.domainStrategy.preferIpv4,
    ipv4Only => t.pages.settings.dns.domainStrategy.ipv4Only,
    ipv6Only => t.pages.settings.dns.domainStrategy.ipv6Only,
  };
}

enum TunImplementation {
  mixed,
  system,
  gvisor;

  String present(TranslationsEn t) => switch (this) {
    mixed => t.pages.settings.inbound.tunImplementations.mixed,
    system => t.pages.settings.inbound.tunImplementations.system,
    gvisor => t.pages.settings.inbound.tunImplementations.gvisor,
  };
}

enum MuxProtocol { h2mux, smux, yamux }

@JsonEnum(valueField: 'key')
enum WarpDetourMode {
  proxyOverWarp("proxy_over_warp"),
  warpOverProxy("warp_over_proxy");

  const WarpDetourMode(this.key);

  final String key;

  String present(TranslationsEn t) => switch (this) {
    proxyOverWarp => t.pages.settings.warp.detourModes.proxyOverWarp,
    warpOverProxy => t.pages.settings.warp.detourModes.warpOverProxy,
  };

  String presentExplain(TranslationsEn t) => switch (this) {
    proxyOverWarp => t.pages.settings.warp.detourModes.proxyOverWarpExplain,
    warpOverProxy => t.pages.settings.warp.detourModes.warpOverProxyExplain,
  };
}
