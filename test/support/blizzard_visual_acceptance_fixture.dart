import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/app_info_entity.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final blizzardVisualAcceptanceProfile = ProfileEntity.remote(
  id: 'synthetic-akonit-premium',
  active: true,
  name: 'Akonit Premium',
  url: 'https://fixture.invalid/akonit-premium',
  lastUpdate: DateTime.utc(2026, 10, 22),
  subInfo: SubscriptionInfo(
    upload: 0,
    download: 0,
    total: 11 * 1024 * 1024 * 1024 * 1024,
    // Keep the synthetic acceptance state at a stable visible 169 days on every run.
    expire: DateTime.now().toUtc().add(const Duration(days: 169, hours: 12)),
  ),
);

final blizzardVisualAcceptanceProxy = OutboundInfo(
  tag: 'finland-vless',
  tagDisplay: 'Финляндия',
  groupSelectedTagDisplay: 'Вьюга 1G',
  type: 'VLESS',
  urlTestDelay: 84,
  ipinfo: IpInfo(ip: '192.0.2.84', countryCode: 'FI', org: 'Synthetic documentation network'),
);

OutboundGroup get blizzardVisualAcceptanceServerGroup => OutboundGroup(
  tag: 'select',
  selected: 'finland-vless',
  items: [
    OutboundInfo(
      tag: 'finland-vless',
      tagDisplay: 'Финляндия',
      groupSelectedTagDisplay: 'Вьюга 1G',
      type: 'VLESS',
      urlTestDelay: 84,
      ipinfo: IpInfo(ip: '192.0.2.84', countryCode: 'FI'),
    ),
    OutboundInfo(
      tag: 'germany-vless',
      tagDisplay: 'Германия',
      groupSelectedTagDisplay: 'Хёллентэлер',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.2', countryCode: 'DE'),
    ),
    OutboundInfo(
      tag: 'netherlands-harmonic-vless',
      tagDisplay: 'Нидерланды',
      groupSelectedTagDisplay: 'Хармоник',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.3', countryCode: 'NL'),
    ),
    OutboundInfo(
      tag: 'estonia-vless',
      tagDisplay: 'Эстония',
      groupSelectedTagDisplay: 'Рао',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.4', countryCode: 'EE'),
    ),
    OutboundInfo(
      tag: 'usa-vless',
      tagDisplay: 'США',
      groupSelectedTagDisplay: 'Виливав',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.5', countryCode: 'US'),
    ),
    OutboundInfo(
      tag: 'japan-vless',
      tagDisplay: 'Япония',
      groupSelectedTagDisplay: 'Ямасэ',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.6', countryCode: 'JP'),
    ),
    OutboundInfo(
      tag: 'turkey-vless',
      tagDisplay: 'Турция',
      groupSelectedTagDisplay: 'Лодос',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.7', countryCode: 'TR'),
    ),
    OutboundInfo(
      tag: 'netherlands-favonius-vless',
      tagDisplay: 'Нидерланды',
      groupSelectedTagDisplay: 'Фавоний',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.8', countryCode: 'NL'),
    ),
    OutboundInfo(
      tag: 'poland-vless',
      tagDisplay: 'Польша',
      groupSelectedTagDisplay: 'Хальны',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.9', countryCode: 'PL'),
    ),
    OutboundInfo(
      tag: 'switzerland-vless',
      tagDisplay: 'Швейцария',
      groupSelectedTagDisplay: 'Тивано',
      type: 'VLESS',
      urlTestDelay: 0,
      ipinfo: IpInfo(ip: '192.0.2.10', countryCode: 'CH'),
    ),
  ],
);

List<Override> get blizzardVisualAcceptanceOverrides => [
  appInfoProvider.overrideWith(BlizzardVisualAcceptanceAppInfo.new),
  serviceRunningProvider.overrideWith((ref) => true),
  activeProxyNotifierProvider.overrideWith(BlizzardVisualAcceptanceActiveProxy.new),
  iosActiveProxyMeasurementStateProvider.overrideWith(
    (ref) => Stream.value(
      IosProxyMeasurementState(IosProxyMeasurementPhase.available, proxy: blizzardVisualAcceptanceProxy),
    ),
  ),
];

class BlizzardVisualAcceptanceActiveProxy extends ActiveProxyNotifier {
  @override
  Stream<OutboundInfo> build() => Stream.value(blizzardVisualAcceptanceProxy);
}

class BlizzardVisualAcceptanceAppInfo extends AppInfo {
  @override
  Future<AppInfoEntity> build() async => const AppInfoEntity(
    name: 'Blizzard VPN',
    version: '0.0.1',
    buildNumber: '22',
    release: Release.general,
    operatingSystem: 'ios-simulator',
    operatingSystemVersion: '26.5',
    environment: Environment.prod,
  );
}
