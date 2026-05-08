import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/platform_utils.dart';

@JsonEnum(valueField: 'key')
enum ServiceMode {
  proxy("proxy"),
  systemProxy("system-proxy"),
  tun("vpn")
  // tunService("vpn-service")
  ;

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
    // tunService => t.pages.settings.inbound.serviceModes.tunService,
  };

  String presentShort(TranslationsEn t) => switch (this) {
    proxy => t.pages.settings.inbound.shortServiceModes.proxy,
    systemProxy => t.pages.settings.inbound.shortServiceModes.systemProxy,
    tun => t.pages.settings.inbound.shortServiceModes.tun,
    // tunService => t.pages.settings.inbound.shortServiceModes.tunService,
  };
}

@JsonEnum(valueField: 'key')
enum BalancerStrategy {
  roundRobin("round-robin"),
  consistentHash("consistent-hashing"),
  stickySession("sticky-sessions");

  const BalancerStrategy(this.key);

  final String key;

  String present(TranslationsEn t) => switch (this) {
    roundRobin => t.pages.settings.routing.balancerStrategy.roundRobin,
    consistentHash => t.pages.settings.routing.balancerStrategy.consistentHash,
    stickySession => t.pages.settings.routing.balancerStrategy.stickySession,
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

@JsonEnum(valueField: 'key')
enum ChainStatus {
  off('off'),
  extraSecurity('extra_security'),
  unblocker('unblocker');

  const ChainStatus(this.key);

  final String key;

  bool isOff() => this == off;
  bool isUnblocker() => this == unblocker;
  bool isExtraSecurity() => this == extraSecurity;
}

@JsonEnum(valueField: 'key')
enum ChainMode {
  psiphon('psiphon'),
  warp('warp'),
  profile('profile');

  const ChainMode(this.key);

  final String key;

  String present(Translations t) => switch (this) {
    psiphon => t.common.psiphon,
    warp => t.common.warp,
    profile => t.common.profile,
  };

  IconData icon() => switch (this) {
    psiphon => Icons.local_parking,
    warp => Icons.cloud,
    profile => Icons.link,
  };

  Color color() => switch (this) {
    psiphon => ChainConst.psiphonColor,
    warp => ChainConst.warpColor,
    profile => ChainConst.profileColor,
  };

  bool isPsiphon() => this == psiphon;
  bool isWarp() => this == warp;
  bool isProfile() => this == profile;
}

@JsonEnum(valueField: 'key')
enum PsiphonRegion {
  auto('AUTO'),
  austria('AT'),
  australia('AU'),
  belgium('BE'),
  bulgaria('BG'),
  canada('CA'),
  switzerland('CH'),
  czechRepublic('CZ'),
  germany('DE'),
  denmark('DK'),
  estonia('EE'),
  spain('ES'),
  finland('FI'),
  france('FR'),
  unitedKingdom('GB'),
  croatia('HR'),
  hungary('HU'),
  ireland('IE'),
  india('IN'),
  italy('IT'),
  japan('JP'),
  latvia('LV'),
  netherlands('NL'),
  norway('NO'),
  poland('PL'),
  portugal('PT'),
  romania('RO'),
  serbia('RS'),
  sweden('SE'),
  singapore('SG'),
  slovakia('SK'),
  unitedStates('US');

  const PsiphonRegion(this.key);

  final String key;

  String present(Translations t) => switch (this) {
    auto => t.pages.settings.chain.psiphon.regions.auto,
    austria => t.pages.settings.chain.psiphon.regions.at,
    australia => t.pages.settings.chain.psiphon.regions.au,
    belgium => t.pages.settings.chain.psiphon.regions.be,
    bulgaria => t.pages.settings.chain.psiphon.regions.bg,
    canada => t.pages.settings.chain.psiphon.regions.ca,
    switzerland => t.pages.settings.chain.psiphon.regions.ch,
    czechRepublic => t.pages.settings.chain.psiphon.regions.cz,
    germany => t.pages.settings.chain.psiphon.regions.de,
    denmark => t.pages.settings.chain.psiphon.regions.dk,
    estonia => t.pages.settings.chain.psiphon.regions.ee,
    spain => t.pages.settings.chain.psiphon.regions.es,
    finland => t.pages.settings.chain.psiphon.regions.fi,
    france => t.pages.settings.chain.psiphon.regions.fr,
    unitedKingdom => t.pages.settings.chain.psiphon.regions.gb,
    croatia => t.pages.settings.chain.psiphon.regions.hr,
    hungary => t.pages.settings.chain.psiphon.regions.hu,
    ireland => t.pages.settings.chain.psiphon.regions.ie,
    india => t.pages.settings.chain.psiphon.regions.kIn,
    italy => t.pages.settings.chain.psiphon.regions.it,
    japan => t.pages.settings.chain.psiphon.regions.jp,
    latvia => t.pages.settings.chain.psiphon.regions.lv,
    netherlands => t.pages.settings.chain.psiphon.regions.nl,
    norway => t.pages.settings.chain.psiphon.regions.no,
    poland => t.pages.settings.chain.psiphon.regions.pl,
    portugal => t.pages.settings.chain.psiphon.regions.pt,
    romania => t.pages.settings.chain.psiphon.regions.ro,
    serbia => t.pages.settings.chain.psiphon.regions.rs,
    sweden => t.pages.settings.chain.psiphon.regions.se,
    singapore => t.pages.settings.chain.psiphon.regions.sg,
    slovakia => t.pages.settings.chain.psiphon.regions.sk,
    unitedStates => t.pages.settings.chain.psiphon.regions.us,
  };
}

enum MuxProtocol { h2mux, smux, yamux }

// @JsonEnum(valueField: 'key')
// enum WarpDetourMode {
//   proxyOverWarp("proxy_over_warp"),
//   warpOverProxy("warp_over_proxy");

//   const WarpDetourMode(this.key);

//   final String key;

//   String present(TranslationsEn t) => switch (this) {
//     proxyOverWarp => t.pages.settings.warp.detourModes.proxyOverWarp,
//     warpOverProxy => t.pages.settings.warp.detourModes.warpOverProxy,
//   };

//   String presentExplain(TranslationsEn t) => switch (this) {
//     proxyOverWarp => t.pages.settings.warp.detourModes.proxyOverWarpExplain,
//     warpOverProxy => t.pages.settings.warp.detourModes.warpOverProxyExplain,
//   };
// }
