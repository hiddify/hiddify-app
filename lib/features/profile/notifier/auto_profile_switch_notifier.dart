import 'dart:async';

import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_profile_switch_notifier.g.dart';

/// Auto-switch notifier.
///
/// Watches the active-proxy group stream from the sing-box core. For every
/// url-test result it checks, per active profile, whether ALL of that
/// profile's outbounds are unreachable (delay == 0 or >= 65000). If a profile
/// has been entirely unreachable for [failureThreshold] consecutive checks,
/// it is automatically deactivated by calling
/// `ProfilesNotifier.toggleActiveProfile(id, false)`. Deactivating it
/// triggers the listener in `ConnectionNotifier` which rebuilds the merged
/// config without that profile's outbounds and reconnects — i.e. the app
/// "switches to a different profile by itself" when one is dead.
///
/// This is conservative: a profile is only disabled if EVERY one of its
/// outbounds is failing. If even one outbound is healthy, the profile stays
/// active (and the core's urltest machinery will keep using that one healthy
/// outbound).
@Riverpod(keepAlive: true)
class AutoProfileSwitchNotifier extends _$AutoProfileSwitchNotifier with AppLogger {
  StreamSubscription? _sub;
  final Map<String, int> _failureStreak = {};

  /// Number of consecutive url-test rounds a profile must be entirely dead
  /// before we auto-disable it. With the default `url-test-interval` of 10
  /// minutes this is ~30 minutes of total failure.
  static const int failureThreshold = 3;

  @override
  void build() {
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    final serviceRunning = ref.watch(serviceRunningProvider);
    if (!serviceRunning) return;

    final activeProfiles = ref.watch(activeProfilesProvider).valueOrNull ?? const <ProfileEntity>[];
    if (activeProfiles.isEmpty) return;

    final proxyRepo = ref.watch(proxyRepositoryProvider);
    _sub?.cancel();
    _sub = proxyRepo.watchActiveProxies().listen((event) {
      event.match(
        (l) {
          loggy.warning('error in active proxy stream', l);
        },
        (groups) => _handleGroups(groups, activeProfiles),
      );
    });

    ref.watch(activeProfilesProvider); // re-subscribe if the active set changes
  }

  void _handleGroups(List<OutboundGroup> groups, List<ProfileEntity> activeProfiles) {
    if (groups.isEmpty) return;
    // The merged config exposes exactly ONE top-level `select` group whose
    // items are all the prefixed outbounds (`${profileId}::${tag}`).
    final selectGroup = groups.firstWhere(
      (g) => g.tag == 'select',
      orElse: () => groups.first,
    );
    final items = selectGroup.items;

    // For each active profile, count healthy / total outbounds.
    for (final profile in activeProfiles) {
      final prefix = '${profile.id}::';
      final profileItems = items.where((i) => i.tag.startsWith(prefix)).toList();
      if (profileItems.isEmpty) continue;

      final healthy = profileItems.where((i) {
        final d = i.urlTestDelay;
        return d > 0 && d < 65000;
      }).length;

      if (healthy == 0) {
        // All outbounds of this profile are dead.
        final streak = (_failureStreak[profile.id] ?? 0) + 1;
        _failureStreak[profile.id] = streak;
        loggy.info(
          'profile [${profile.name}] has 0 healthy outbounds '
          '(${streak}/${failureThreshold})',
        );
        if (streak >= failureThreshold) {
          loggy.warning('auto-disabling dead profile [${profile.name}]');
          _failureStreak.remove(profile.id);
          // Deactivate the profile. The ConnectionNotifier listener will
          // pick up the change and reconnect without this profile.
          Future.microtask(() async {
            await ref
                .read(profilesNotifierProvider.notifier)
                .toggleActiveProfile(profile.id, false);
          });
        }
      } else {
        // At least one outbound is healthy — reset the failure streak.
        _failureStreak.remove(profile.id);
      }
    }

    // Clean up streaks for profiles that are no longer active.
    _failureStreak.removeWhere((id, _) => !activeProfiles.any((p) => p.id == id));
  }

  /// Manually trigger a url-test cycle (used by the home page when the user
  /// taps the active proxy card or pulls to refresh). This forces a fresh
  /// delay measurement so the auto-switch logic can re-evaluate.
  Future<void> triggerUrlTest() async {
    final serviceRunning = ref.read(serviceRunningProvider);
    if (!serviceRunning) return;
    await ref.read(proxyRepositoryProvider).urlTest('select').run();
  }
}
