import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/platform_utils.dart';

@JsonEnum(valueField: 'key')
enum ServiceMode {
  proxy("proxy"),
  systemProxy("system-proxy"),
  tun("vpn");

  const ServiceMode(this.key);

  final String key;

  static ServiceMode get defaultMode => PlatformUtils.isDesktop ? systemProxy : tun;

  /// supported service mode based on platform, use this instead of [values] in UI
  static List<ServiceMode> get choices {
    if (Platform.isWindows || Platform.isLinux) {
      // All modes supported on Windows/Linux
      return values;
    } else if (Platform.isMacOS) {
      // macOS supports all modes
      return values;
    }
    // mobile - only proxy and tun
    return [proxy, tun];
  }

  bool get isExperimental => false;

  String present(Translations t) => switch (this) {
        proxy => t.config.serviceModes.proxy,
        systemProxy => t.config.serviceModes.systemProxy,
        tun => t.config.serviceModes.tun,
      };

  String presentShort(Translations t) => switch (this) {
        proxy => t.config.shortServiceModes.proxy,
        systemProxy => t.config.shortServiceModes.systemProxy,
        tun => t.config.shortServiceModes.tun,
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

  String present(Translations t) => switch (this) {
        disable => t.config.ipv6Modes.disable,
        enable => t.config.ipv6Modes.enable,
        prefer => t.config.ipv6Modes.prefer,
        only => t.config.ipv6Modes.only,
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

  String get displayName => switch (this) {
        auto => "auto",
        _ => key,
      };
}

enum TunImplementation {
  mixed,
  system,
  gvisor;
}

enum MuxProtocol {
  h2mux,
  smux,
  yamux;
}

@JsonEnum(valueField: 'key')
enum WarpDetourMode {
  proxyOverWarp("proxy_over_warp"),
  warpOverProxy("warp_over_proxy");

  const WarpDetourMode(this.key);

  final String key;

  String present(Translations t) => switch (this) {
        proxyOverWarp => t.config.warpDetourModes.proxyOverWarp,
        warpOverProxy => t.config.warpDetourModes.warpOverProxy,
      };
}
