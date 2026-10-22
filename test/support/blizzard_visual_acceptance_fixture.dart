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
