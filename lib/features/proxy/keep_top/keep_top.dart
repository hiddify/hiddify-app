import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keep_top.g.dart';

// Keep top: of a profile with many proxies, the core runs only the fastest few, picked by their
// first pings, and stops the others (hiddify-core v2/hcore/keep_top.go). How many is the profile's
// `keep-top`: the user's choice in its user override, else the subscription's `keep-top` header;
// -1, or neither, runs them all. The user is asked once for a big profile that has neither.

/// A profile with more proxies than this is big: the user is asked whether to run only the fastest.
const bigProfileProxies = 20;

/// How many proxies "keep the fastest" keeps.
const keepTopDefault = 10;

/// The proxies of a profile's config, as the core counts them for keep top (UserProxyTags).
int countProxies(String config) => profileProxies(config).length;

/// A proxy of a profile: its tag, and its sing-box type (`vless`, `shadowsocks`, ...).
typedef ProfileProxy = ({String tag, String type});

/// The proxies of a profile's config, as the core lists them (UserProxyTags), in the config's order.
List<ProfileProxy> profileProxies(String config) {
  final json = jsonDecode(config);
  if (json is! Map) return const [];
  final proxies = <ProfileProxy>[];
  for (final key in const ['outbounds', 'endpoints']) {
    for (final out in json[key] as List? ?? const []) {
      if (out is! Map) continue;
      final tag = out['tag'] as String? ?? '';
      final type = out['type'] as String? ?? '';
      if (_notProxies.contains(type) || _builtInTags.contains(tag) || tag.contains('§hide§')) continue;
      proxies.add((tag: tag, type: type));
    }
  }
  return proxies;
}

const _notProxies = {'block', 'selector', 'urltest', 'custom', 'dns'};
const _builtInTags = {'direct', 'bypass', 'block', 'select', 'lowest'};

/// How many proxies the profile has; 0 when its config can not be read.
@riverpod
Future<int> profileProxyCount(Ref ref, String profileId) =>
    readProxyCount(ref.watch(profilePathResolverProvider).file(profileId));

/// How many proxies the config [file] has; 0 when it can not be read.
Future<int> readProxyCount(File file) async => (await readProfileProxies(file)).length;

/// The proxies the config [file] has; none when it can not be read.
Future<List<ProfileProxy>> readProfileProxies(File file) async {
  if (!file.existsSync()) return const [];
  final config = await file.readAsString();
  // a big subscription is megabytes of JSON
  return Isolate.run(() {
    try {
      return profileProxies(config);
    } on FormatException {
      return const <ProfileProxy>[];
    }
  });
}

extension KeepTopProfile on ProfileEntity {
  /// How many of its proxies run, the fastest; -1 for all.
  int get keepTop => userOverride?.keepTop ?? keepTopHeader ?? -1;

  int? get keepTopHeader => ProfileParser.keepTopHeader(populatedHeaders?['keep-top']?.toString());

  /// The proxies the user chose to run, and only them; none when the user chose none.
  List<String> get keepTags => userOverride?.keepTags ?? const [];

  /// The user chose, or the subscription did: no need to ask.
  bool get keepTopDecided => userOverride?.keepTop != null || keepTopHeader != null || keepTags.isNotEmpty;
}

@Riverpod(keepAlive: true)
class KeepTopNotifier extends _$KeepTopNotifier with AppLogger {
  /// Profiles being asked about now.
  final _asking = <String>{};

  @override
  void build() {}

  /// Saves [keepTop] as the user's choice for [profile] (-1 for all its proxies), in place of the
  /// proxies the user chose before, and applies it at once when the profile is connected.
  Future<void> set(ProfileEntity profile, int keepTop) =>
      _save(profile, (profile.userOverride ?? const UserOverride()).copyWith(keepTop: keepTop, keepTags: null));

  /// Saves [tags] as the proxies of [profile] that run, and only them, and applies them at once
  /// when the profile is connected.
  Future<void> setTags(ProfileEntity profile, List<String> tags) =>
      _save(profile, (profile.userOverride ?? const UserOverride()).copyWith(keepTags: tags));

  Future<void> _save(ProfileEntity profile, UserOverride override) async {
    final updated = profile.copyWith(userOverride: override);
    final saved = await ref.read(profileRepositoryProvider).requireValue.setUserOverride(profile.id, override).run();
    if (saved.isLeft()) {
      loggy.warning('could not save keep top for the profile: $saved');
      return;
    }
    final active = await ref.read(activeProfileProvider.future);
    if (active?.id == profile.id) await ref.read(connectionNotifierProvider.notifier).reconnect(updated);
  }

  /// Asks how many of [profile]'s [count] proxies run, the fastest, or which ones, and applies the
  /// answer; one already running stays chosen. Nothing changes when the dialog is dismissed.
  Future<void> choose(ProfileEntity profile, int count) async {
    final current = profile.keepTop;
    final keep = await ref
        .read(dialogNotifierProvider.notifier)
        .showKeepTop(count: count, keep: current > 0 && current < count ? current : keepTopDefault);
    if (keep == KeepTopDialog.pickByHand) {
      await pick(profile);
    } else if (keep != null) {
      await set(profile, keep);
    }
  }

  /// Asks which of [profile]'s proxies run, and applies them; false when dismissed.
  Future<bool> pick(ProfileEntity profile) async {
    final proxies = await readProfileProxies(ref.read(profilePathResolverProvider).file(profile.id));
    if (proxies.isEmpty) return false;
    final chosen = await ref.read(dialogNotifierProvider.notifier).showKeepTags(profile: profile, proxies: proxies);
    if (chosen == null || chosen.isEmpty) return false;
    await setTags(profile, chosen);
    return true;
  }

  /// Runs all of [profile]'s proxies for a while, so the paused ones can be pinged and tested
  /// while the user chooses; [restore] puts the user's choice back.
  Future<void> wakeAll(ProfileEntity profile) =>
      _save(profile, (profile.userOverride ?? const UserOverride()).copyWith(keepTop: -1, keepTags: null));

  /// Puts back the choice [profile] had, after [wakeAll].
  Future<void> restore(ProfileEntity profile) => _save(profile, profile.userOverride ?? const UserOverride());

  /// Asks, once for each profile, whether a big [profile] runs only its fastest proxies.
  Future<void> askIfBig(ProfileEntity? profile) async {
    if (profile == null || profile.keepTopDecided || !_asking.add(profile.id)) return;
    try {
      // not through profileProxyCountProvider: read, nothing keeps it alive until it is counted
      final count = await readProxyCount(ref.read(profilePathResolverProvider).file(profile.id));
      loggy.debug('keep top: the active profile has $count proxies');
      if (count <= bigProfileProxies) return;
      // the sheet a profile was added from closes first, so its pop is not taken by this dialog
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final keep = await ref.read(dialogNotifierProvider.notifier).showKeepTop(count: count, keep: keepTopDefault);
      // the profile may have changed meanwhile; its latest user override is the one to change
      final latest = await ref.read(profileRepositoryProvider).requireValue.getById(profile.id).run();
      final current = latest.toNullable() ?? profile;
      if (current.keepTopDecided) return;
      if (keep == KeepTopDialog.pickByHand && await pick(current)) return;
      // dismissed, it runs them all as before; the end of the proxy list still offers the choice
      await set(current, keep == null || keep == KeepTopDialog.pickByHand ? -1 : keep);
    } catch (error, stackTrace) {
      loggy.warning('keep top: could not ask about the profile', error, stackTrace);
    } finally {
      _asking.remove(profile.id);
    }
  }
}
