import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/one_tap/mit_release.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class MitResiliencePreferences {
  static final autoRecovery = PreferencesNotifier.create<bool, bool>('mit_auto_recovery', true);
  static final backupProfiles = PreferencesNotifier.create<List<String>, List<String>>('mit_backup_profiles', []);
}

class MitVpnEnvironment {
  const MitVpnEnvironment({this.networkAvailable = false, this.permissionGranted = false,
    this.stopEpoch = 0, this.protectionSupported = false, this.alwaysOn, this.lockdown});
  final bool networkAvailable, permissionGranted, protectionSupported;
  final int stopEpoch;
  final bool? alwaysOn, lockdown;
}

class MitVpnPlatform {
  static const channel = MethodChannel('com.hiddify.app/platform');
  Future<MitVpnEnvironment> environment() async {
    final m = await channel.invokeMapMethod<String, dynamic>('mit_vpn_environment') ?? {};
    return MitVpnEnvironment(networkAvailable: m['networkAvailable'] == true,
      permissionGranted: m['permissionGranted'] == true, stopEpoch: m['stopEpoch'] as int? ?? 0,
      protectionSupported: m['protectionSupported'] == true,
      alwaysOn: m['alwaysOn'] as bool?, lockdown: m['lockdown'] as bool?);
  }
  Future<void> openProtectionSettings() => channel.invokeMethod<void>('mit_open_vpn_settings');
  Future<void> openBatterySettings() => channel.invokeMethod<void>('mit_open_battery_settings');
}

final mitVpnPlatformProvider = Provider<MitVpnPlatform>((ref) => MitVpnPlatform());
final mitRecoveryViewProvider = StateProvider<MitRecoveryView>((ref) => const MitRecoveryView());

class MitRecoveryView {
  const MitRecoveryView({this.active = false, this.attempt = 0, this.phase = 'idle'});
  final bool active;
  final int attempt;
  // Only fixed tokens reach the UI and diagnostic report.
  final String phase;
  String? get label => !active ? null : phase == 'network'
      ? 'Нет сети — ждём подключения' : 'Восстанавливаем соединение… ($attempt/6)';
}

/// Bounded session-only retry policy. Network loss does not spend attempts.
/// A healthy connection must last two minutes before a new retry budget is granted.
class MitRecoveryPlan {
  bool armed = false;
  int generation = 0, attempts = 0, stopEpoch = 0;
  DateTime? _unhealthySince, _lastAttempt, _healthySince;
  final Map<String, int> _perProfile = {};

  void start(int epoch) {
    cancel();
    armed = true; stopEpoch = epoch; attempts = 0; _perProfile.clear();
  }
  void cancel() {
    armed = false; generation++; _unhealthySince = null; _lastAttempt = null; _healthySince = null;
  }

  String? next({required DateTime now, required ConnectionStatus status,
    required MitVpnEnvironment environment, required String currentProfile,
    required List<String> backups}) {
    if (!armed) return null;
    if (environment.stopEpoch != stopEpoch || !environment.permissionGranted) { cancel(); return null; }
    if (status is Connected && environment.networkAvailable) {
      _unhealthySince = null;
      _healthySince ??= now;
      if (now.difference(_healthySince!) >= const Duration(minutes: 2)) {
        attempts = 0; _perProfile.clear(); _lastAttempt = null;
      }
      return null;
    }
    _healthySince = null;
    if (status is Disconnecting || status is HotReloading) return null;
    _unhealthySince ??= now;
    final grace = status is Disconnected ? 3 : 45;
    if (!environment.networkAvailable || now.difference(_unhealthySince!).inSeconds < grace) return null;
    const delays = [3, 8, 20, 45, 90, 90];
    if (attempts >= delays.length) { cancel(); return null; }
    if (_lastAttempt != null && now.difference(_lastAttempt!).inSeconds < delays[attempts]) return null;
    var target = currentProfile;
    if ((_perProfile[target] ?? 0) >= 2) {
      final available = backups.where((id) => id != currentProfile && (_perProfile[id] ?? 0) < 2);
      if (available.isNotEmpty) target = available.first;
      // Without a selected backup, retry the current profile within the total budget.
    }
    attempts++; _perProfile[target] = (_perProfile[target] ?? 0) + 1; _lastAttempt = now;
    return target;
  }
}

String mitSafeDiagnosticReport({required ConnectionStatus? status, required MitRecoveryView recovery,
  required bool autoRecovery, required int backupCount, required MitVpnEnvironment? environment}) {
  // Never accept arbitrary strings, exceptions, log lines, names, IDs or URLs.
  final state = switch (status) {
    Connected() => 'connected', Connecting() => 'connecting', Waiting() => 'waiting',
    NoAvailableProxies() => 'unavailable', Disconnecting() => 'disconnecting',
    HotReloading() => 'reloading', Disconnected() => 'disconnected', _ => 'unknown',
  };
  final phase = {'idle','retry','network','exhausted','blocked','connected'}.contains(recovery.phase) ? recovery.phase : 'unknown';
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'Mit’s VPN', 'version': MitRelease.buildName, 'build': MitRelease.buildNumber,
    'platform': 'Android', 'connection': state, 'auto_recovery': autoRecovery,
    'recovery': phase, 'attempt': recovery.attempt.clamp(0, 6), 'backup_count': backupCount.clamp(0, 100),
    'network_available': environment?.networkAvailable, 'vpn_permission': environment?.permissionGranted,
    'always_on': environment?.alwaysOn, 'lockdown': environment?.lockdown,
  });
}
