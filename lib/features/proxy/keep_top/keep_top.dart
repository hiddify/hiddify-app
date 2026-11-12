import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_tags_dialog.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keep_top.g.dart';

// Keep top: of a profile with many proxies, the core runs only the fastest few, picked by their
// first pings, and stops the others (hiddify-core v2/hcore/keep_top.go). How many is the profile's
// `keep-top`: the user's choice in its user override, else the subscription's `keep-top` header,
// else [keepTopDefault]; -1 runs them all. The user changes it from the end of the proxy list.

/// A profile with more proxies than this is big: the keep top card shows even when all run.
const bigProfileProxies = 20;

/// How many proxies keep top keeps when neither the user nor the subscription says.
const keepTopDefault = ProfileParser.keepTopDefault;

/// The countries offered first to keep proxies of.
const preferredCountries = ['DE', 'GB', 'FR', 'US', 'CA', 'NL', 'TR'];

/// The keep-top that keeps every proxy answering its first ping and pauses the others
/// (hiddify-core config.KeepTopAnswering).
const keepTopAnswering = -2;

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

/// How many of [proxies] that keep top paused for being outside [regions] answered faster than
/// the fastest one running: by their ping, else the one cached from the last run. 0 without
/// [regions], or before any running one answered.
int fasterOutsideRegions(Iterable<OutboundInfo> proxies, Iterable<String> regions) {
  final wanted = {for (final code in regions) code.toUpperCase()};
  if (wanted.isEmpty) return 0;
  int? delayOf(OutboundInfo p) => ConnectionConst.isValidDelay(p.urlTestDelay)
      ? p.urlTestDelay
      : ConnectionConst.isValidDelay(p.sortDelay)
      ? p.sortDelay
      : null;
  String? regionOf(OutboundInfo p) {
    final looked = p.ipinfo.countryCode.toUpperCase();
    return looked.length == 2 ? looked : countryOf(p.tag);
  }

  int? fastest;
  for (final p in proxies) {
    if (p.resting || p.isGroup) continue;
    if (delayOf(p) case final delay? when fastest == null || delay < fastest) fastest = delay;
  }
  if (fastest == null) return 0;
  return proxies.where((p) {
    if (!p.resting) return false;
    final region = regionOf(p);
    final delay = delayOf(p);
    return region != null && !wanted.contains(region) && delay != null && delay < fastest!;
  }).length;
}

extension KeepTopProfile on ProfileEntity {
  /// How many of its proxies run, the fastest; -1 for all.
  int get keepTop => userOverride?.keepTop ?? keepTopHeader ?? keepTopDefault;

  int? get keepTopHeader => ProfileParser.keepTopHeader(populatedHeaders?['keep-top']?.toString());

  /// The proxies the user chose to run, and only them; none when the user chose none.
  List<String> get keepTags => userOverride?.keepTags ?? const [];

  /// The proxies the user asked to keep loaded, whatever their ping, beside the fastest.
  List<String> get keepTopPinned => userOverride?.keepTopPinned ?? const [];

  /// Whether the proxy list offers keep top for its [total] proxies: a big profile, or one whose
  /// keep top was chosen, by the user or the subscription, even "all", so it can be changed back.
  bool offersKeepTop(int total) =>
      total > bigProfileProxies || userOverride?.keepTop != null || keepTags.isNotEmpty || keepTopHeader != null;

  /// Keep top leaves some of the profile's proxies at rest: a count, the answering ones, or the
  /// ones of some countries.
  bool get keepsTop =>
      keepTags.isEmpty &&
      (keepTop > 0 || keepTop == keepTopAnswering || (userOverride?.keepTopCountries?.isNotEmpty ?? false));
}

@Riverpod(keepAlive: true)
class KeepTopNotifier extends _$KeepTopNotifier with AppLogger {
  @override
  void build() {}

  /// Saves [keepTop] as the user's choice for [profile] (-1 for all its proxies), in place of the
  /// proxies the user chose before, with whether a [quick] test picks them (unchanged when null),
  /// and applies it at once when the profile is connected.
  Future<void> set(ProfileEntity profile, int keepTop, {bool? quick, List<String>? countries}) {
    final override = profile.userOverride ?? const UserOverride();
    return _save(
      profile,
      override.copyWith(
        keepTop: keepTop,
        keepTags: null,
        keepTopQuick: quick ?? override.keepTopQuick,
        keepTopCountries: countries ?? override.keepTopCountries,
      ),
    );
  }

  /// The countries of [profile]'s proxies, with how many each has: where a running proxy's IP
  /// is, else the flag in its name. The most proxies first, then in [preferredCountries]' order.
  Future<List<(String, int)>> countries(ProfileEntity profile) async {
    final proxies = await readProfileProxies(ref.read(profilePathResolverProvider).file(profile.id));
    final live = {
      for (final e in ref.read(proxiesOverviewNotifierProvider).valueOrNull?.items ?? const <OutboundInfo>[]) e.tag: e,
    };
    final counts = <String, int>{};
    for (final proxy in proxies) {
      final looked = live[proxy.tag]?.ipinfo.countryCode.toUpperCase() ?? '';
      final code = looked.length == 2 ? looked : countryOf(proxy.tag);
      if (code != null) counts[code] = (counts[code] ?? 0) + 1;
    }
    int rank(String code) {
      final i = preferredCountries.indexOf(code);
      return i < 0 ? preferredCountries.length : i;
    }

    return [for (final e in counts.entries) (e.key, e.value)]..sort(
      (a, b) => a.$2 != b.$2
          ? b.$2.compareTo(a.$2)
          : (rank(a.$1) != rank(b.$1) ? rank(a.$1).compareTo(rank(b.$1)) : a.$1.compareTo(b.$1)),
    );
  }

  /// Keeps the proxy [tag] of [profile] loaded whatever its ping ([keep]), or leaves it to keep
  /// top again, and applies it at once when the profile is connected: the core takes it without
  /// a restart.
  Future<void> setPinned(ProfileEntity profile, String tag, {required bool keep}) {
    final pinned = {...profile.keepTopPinned};
    if (!(keep ? pinned.add(tag) : pinned.remove(tag))) return Future.value();
    return _save(profile, (profile.userOverride ?? const UserOverride()).copyWith(keepTopPinned: pinned.toList()));
  }

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
    final choice = await ref
        .read(dialogNotifierProvider.notifier)
        .showKeepTop(
          count: count,
          keep: current == keepTopAnswering || (current > 0 && current < count) ? current : keepTopDefault,
          quick: profile.userOverride?.keepTopQuick ?? true,
          countries: profile.userOverride?.keepTopCountries ?? const [],
          available: await countries(profile),
        );
    if (choice == null) return;
    if (choice.keep == KeepTopDialog.pickByHand) {
      await pick(profile);
    } else {
      await set(profile, choice.keep, quick: choice.quick, countries: choice.countries);
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
}
