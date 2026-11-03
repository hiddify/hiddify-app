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
int countProxies(String config) {
  final json = jsonDecode(config);
  if (json is! Map) return 0;
  var count = 0;
  for (final key in const ['outbounds', 'endpoints']) {
    for (final out in json[key] as List? ?? const []) {
      if (out is! Map) continue;
      final tag = out['tag'] as String? ?? '';
      if (_notProxies.contains(out['type']) || _builtInTags.contains(tag) || tag.contains('§hide§')) continue;
      count++;
    }
  }
  return count;
}

const _notProxies = {'block', 'selector', 'urltest', 'custom', 'dns'};
const _builtInTags = {'direct', 'bypass', 'block', 'select', 'lowest'};

/// How many proxies the profile has; 0 when its config can not be read.
@riverpod
Future<int> profileProxyCount(Ref ref, String profileId) =>
    readProxyCount(ref.watch(profilePathResolverProvider).file(profileId));

/// How many proxies the config [file] has; 0 when it can not be read.
Future<int> readProxyCount(File file) async {
  if (!file.existsSync()) return 0;
  final config = await file.readAsString();
  // a big subscription is megabytes of JSON
  return Isolate.run(() {
    try {
      return countProxies(config);
    } on FormatException {
      return 0;
    }
  });
}

extension KeepTopProfile on ProfileEntity {
  /// How many of its proxies run, the fastest; -1 for all.
  int get keepTop => userOverride?.keepTop ?? keepTopHeader ?? -1;

  int? get keepTopHeader => ProfileParser.keepTopHeader(populatedHeaders?['keep-top']?.toString());

  /// The user chose, or the subscription did: no need to ask.
  bool get keepTopDecided => userOverride?.keepTop != null || keepTopHeader != null;
}

@Riverpod(keepAlive: true)
class KeepTopNotifier extends _$KeepTopNotifier with AppLogger {
  /// Profiles being asked about now.
  final _asking = <String>{};

  @override
  void build() {}

  /// Saves [keepTop] as the user's choice for [profile] (-1 for all its proxies), and applies it
  /// at once when the profile is connected.
  Future<void> set(ProfileEntity profile, int keepTop) async {
    final override = (profile.userOverride ?? const UserOverride()).copyWith(keepTop: keepTop);
    final updated = profile.copyWith(userOverride: override);
    final saved = await ref.read(profileRepositoryProvider).requireValue.setUserOverride(profile.id, override).run();
    if (saved.isLeft()) {
      loggy.warning('could not save keep top for the profile: $saved');
      return;
    }
    final active = await ref.read(activeProfileProvider.future);
    if (active?.id == profile.id) await ref.read(connectionNotifierProvider.notifier).reconnect(updated);
  }

  /// Asks how many of [profile]'s [count] proxies run, the fastest, and applies the answer; one
  /// already running stays chosen. Nothing changes when the dialog is dismissed.
  Future<void> choose(ProfileEntity profile, int count) async {
    final current = profile.keepTop;
    final keep = await ref
        .read(dialogNotifierProvider.notifier)
        .showKeepTop(count: count, keep: current > 0 && current < count ? current : keepTopDefault);
    if (keep != null) await set(profile, keep);
  }

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
      // dismissed, it runs them all as before; the end of the proxy list still offers the choice
      await set(current, keep ?? -1);
    } catch (error, stackTrace) {
      loggy.warning('keep top: could not ask about the profile', error, stackTrace);
    } finally {
      _asking.remove(profile.id);
    }
  }
}
