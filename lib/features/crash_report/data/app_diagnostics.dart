import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Preferences whose value is a secret or names the user's own apps: the report says only whether
/// they are set (or how many entries a list has), never what they hold.
final _hiddenPreference = RegExp(
  'password|secret|license|token|pairing|clean-ip|per_app_proxy_(include|exclude)_list|window_',
);

/// A longer value (a rule list, a JSON blob) is cut, so one preference cannot crowd out the logs.
const _maxPreferenceLength = 4000;

/// What the core can not know and a developer asks first: which build this is, on what system,
/// what the app thinks the connection is doing, the user's settings without secrets, the profile
/// in use without its link, what every proxy answered and which networks the device has.
///
/// Every section is gathered on its own: one that fails or times out says why, and the others
/// still make it into the report. The zip is scrubbed of addresses, links and secrets by the core
/// on top of what is left out here.
Future<Map<String, Object?>> collectAppDiagnostics(Ref ref) async {
  Future<Object?> section(Future<Object?> Function() collect) async {
    try {
      return await collect().timeout(const Duration(seconds: 5));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  return {
    'collectedAt': DateTime.now().toUtc().toIso8601String(),
    'app': await section(() => _app(ref)),
    'system': await section(() async => _system(ref)),
    'connection': await section(() async => _connection(ref)),
    'profiles': await section(() => _profiles(ref)),
    'core': await section(() => _core(ref)),
    'proxies': await section(() => _proxies(ref)),
    'network': await section(_network),
    'settings': await section(() async => _settings(ref)),
  };
}

Future<Map<String, Object?>> _app(Ref ref) async {
  final info = await ref.read(appInfoProvider.future);
  return {
    'name': info.name,
    'version': info.version,
    'build': info.buildNumber,
    'release': info.release.key,
    'environment': info.environment.name,
    'portable': Environment.isPortable,
    'executable': Platform.resolvedExecutable.split(Platform.pathSeparator).last,
  };
}

Map<String, Object?> _system(Ref ref) => {
  'os': Platform.operatingSystem,
  'osVersion': Platform.operatingSystemVersion,
  'dart': Platform.version,
  'processors': Platform.numberOfProcessors,
  'systemLocale': Platform.localeName,
  'appLocale': ref.read(localePreferencesProvider).name,
  'timeZone': DateTime.now().timeZoneName,
  'timeZoneOffset': DateTime.now().timeZoneOffset.toString(),
};

Map<String, Object?> _connection(Ref ref) {
  final status = ref.read(connectionNotifierProvider);
  return {
    'status': status.valueOrNull?.toString() ?? (status.hasError ? 'error: ${status.error}' : 'loading'),
    'singleChannelCore': ref.read(hiddifyCoreServiceProvider).core.isSingleChannel(),
  };
}

Future<Map<String, Object?>> _profiles(Ref ref) async {
  final count = await ref.read(profileDataSourceProvider).watchProfilesCount().first;
  final active = await ref.read(activeProfileProvider.future);
  return {
    'count': count,
    'active': switch (active) {
      null => null,
      final RemoteProfileEntity profile => {
        'type': 'remote',
        'lastUpdate': profile.lastUpdate.toUtc().toIso8601String(),
        'updateInterval': profile.options?.updateInterval.toString(),
        if (profile.subInfo case final sub?)
          'subscription': {
            'upload': sub.upload,
            'download': sub.download,
            'total': sub.total,
            'expire': sub.expire.toUtc().toIso8601String(),
            'expired': sub.isExpired,
          },
        'headers': profile.populatedHeaders?.keys.toList(),
        'hasUserOverride': profile.userOverride != null,
      },
      final LocalProfileEntity profile => {
        'type': 'local',
        'lastUpdate': profile.lastUpdate.toUtc().toIso8601String(),
        'headers': profile.populatedHeaders?.keys.toList(),
        'hasUserOverride': profile.userOverride != null,
      },
    },
  };
}

/// The core that runs the tunnel: memory, goroutines and connections tell a leak or a hang apart
/// from a network that drops everything.
Future<Map<String, Object?>> _core(Ref ref) async {
  final core = ref.read(hiddifyCoreServiceProvider).core;
  final info = await core.bgClient.getSystemInfo(Empty(), options: CallOptions(timeout: const Duration(seconds: 3)));
  return {
    'memory': info.memory.toInt(),
    'goroutines': info.goroutines,
    'connectionsIn': info.connectionsIn,
    'connectionsOut': info.connectionsOut,
    'uplinkTotal': info.uplinkTotal.toInt(),
    'downlinkTotal': info.downlinkTotal.toInt(),
  };
}

/// Every group and proxy with what its last test answered, without its host or port: the tag
/// matches the core log's lines about it.
Future<List<Map<String, Object?>>> _proxies(Ref ref) async {
  final core = ref.read(hiddifyCoreServiceProvider).core;
  final groups = await core.bgClient
      .outboundsInfo(Empty(), options: CallOptions(timeout: const Duration(seconds: 3)))
      .first;
  return [
    for (final group in groups.items)
      {
        'tag': group.tag,
        'type': group.type,
        'selected': group.selected,
        'items': [
          for (final item in group.items)
            {
              'tag': item.tag,
              'type': item.type,
              'status': item.status.name,
              'delay': item.urlTestDelay,
              if (item.hasUrlTestTime()) 'testedAt': item.urlTestTime.toDateTime().toIso8601String(),
              if (item.isSelected) 'selected': true,
              if (item.isGroup) 'group': true,
              if (item.hasIpinfo()) 'exitCountry': item.ipinfo.countryCode,
              if (item.detour.isNotEmpty) 'detour': item.detour,
              if (item.uploadSpeed != 0) 'uploadSpeed': item.uploadSpeed.toInt(),
              if (item.downloadSpeed != 0) 'downloadSpeed': item.downloadSpeed.toInt(),
            },
        ],
      },
  ];
}

/// The device's interfaces and which kinds of address each has, not the addresses: enough to see
/// a VPN or tunnel interface left behind, or a network without IPv4 or IPv6.
Future<List<Map<String, Object?>>> _network() async {
  final interfaces = await NetworkInterface.list(includeLinkLocal: true);
  return [
    for (final interface in interfaces)
      {
        'name': interface.name,
        'ipv4': interface.addresses.where((a) => a.type == InternetAddressType.IPv4).length,
        'ipv6': interface.addresses.where((a) => a.type == InternetAddressType.IPv6 && !a.isLinkLocal).length,
        'ipv6LinkLocal': interface.addresses.where((a) => a.type == InternetAddressType.IPv6 && a.isLinkLocal).length,
        'loopback': interface.addresses.any((a) => a.isLoopback),
      },
  ];
}

Map<String, Object?> _settings(Ref ref) {
  final preferences = ref.read(sharedPreferencesProvider).requireValue;
  final keys = preferences.getKeys().toList()..sort();
  return {for (final key in keys) key: _preferenceValue(key, preferences.get(key))};
}

Object? _preferenceValue(String key, Object? value) {
  if (_hiddenPreference.hasMatch(key)) {
    return switch (value) {
      null => null,
      final List<Object?> list => '<${list.length} entries>',
      final String text when key.endsWith('_list') => '<${text.split(';').where((e) => e.isNotEmpty).length} entries>',
      final String text when text.isEmpty => '<empty>',
      _ => '<set>',
    };
  }
  if (value is String && value.length > _maxPreferenceLength) {
    return '${value.substring(0, _maxPreferenceLength)}… <${value.length} characters>';
  }
  return value;
}
