import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/utils/utils.dart';

/// Builds a single merged sing-box config from N active profiles, so the
/// sing-box core can treat all outbounds from all profiles as one pool and
/// auto-select the fastest one via a top-level `urltest` group named `select`.
///
/// Strategy:
///   1. For each active profile, ask the core to generate its full sing-box
///      JSON via `ProfileRepository.generateConfig(id)` (which calls
///      `core.fgClient.parse(...)` and returns a fully-expanded config string).
///   2. Parse each JSON, walk its `outbounds` array, and for every
///      non-group, non-meta outbound (i.e. real proxy entries like vless /
///      vmess / trojan / hysteria / wireguard / ssh ...), prefix its `tag`
///      with `${profileId}::${originalTag}` to avoid tag collisions between
///      profiles. Skip the per-profile `selector` / `urltest` / `balancer`
///      groups and the meta outbounds (`direct`, `bypass`, `direct-fragment`,
///      `dns`, `block`).
///   3. After all outbounds from all profiles are collected, append a single
///      new top-level `urltest` group tagged `select` whose `outbounds` field
///      contains every prefixed real-outbound tag. The core's URLTest
///      machinery (driven by `url-test-interval` from `SingboxConfigOption`)
///      will then pick the lowest-delay one automatically.
///   4. Merge `inbounds`, `route`, `dns`, `log`, `experimental` from the
///      FIRST profile (they should all be identical because they come from
///      the same `SingboxConfigOption`/global options).
///   5. Write the merged JSON to `ProfilePathResolver.mergedFile()` and
///      return its absolute path.
class MergedConfigBuilder with InfraLogger {
  MergedConfigBuilder({
    required ProfileRepository profileRepository,
    required ProfilePathResolver profilePathResolver,
  }) : _profileRepository = profileRepository,
       _profilePathResolver = profilePathResolver;

  final ProfileRepository _profileRepository;
  final ProfilePathResolver _profilePathResolver;

  /// Tags that the sing-box core generates as meta / infrastructure outbounds.
  /// We never pool these — only real proxy outbounds go into the merged
  /// `select` group.
  static const _metaOutboundTags = {'direct', 'bypass', 'direct-fragment', 'dns', 'block'};

  /// Outbound types that represent meta / infrastructure outbounds.
  static const _metaOutboundTypes = {'direct', 'dns', 'block'};

  /// Outbound types that represent groups, not real proxies.
  static const _groupOutboundTypes = {'selector', 'urltest', 'balancer'};

  /// Build the merged config file from [profiles] and return its absolute
  /// path. If [profiles] is empty, returns a [ProfileFailure.notFound] on the
  /// left. If [profiles] has exactly one entry, this still works (the merged
  /// config will simply contain that one profile's outbounds plus the
  /// `select` urltest group).
  TaskEither<ProfileFailure, String> buildMergedConfig(List<ProfileEntity> profiles) {
    if (profiles.isEmpty) {
      return TaskEither.left(const ProfileFailure.notFound());
    }
    return _build(profiles);
  }

  TaskEither<ProfileFailure, String> _build(List<ProfileEntity> profiles) {
    return TaskEither.tryCatch(() async {
      loggy.debug('building merged config for ${profiles.length} active profile(s)');

      final List<Map<String, dynamic>> mergedOutbounds = [];
      // Take inbounds/route/dns/log/experimental from the first profile — they
      // are derived from the global SingboxConfigOption, which is shared
      // across all profiles.
      Map<String, dynamic>? headConfig;
      // For each profile, remember which prefixed tags belong to it. Used by
      // the auto-switch logic to disable a profile when ALL its outbounds
      // are unreachable.
      final Map<String, List<String>> tagsByProfile = {};

      for (final profile in profiles) {
        final configJsonStr = await _profileRepository
            .generateConfig(profile.id)
            .getOrElse((l) => throw l)
            .run();
        final Map<String, dynamic> configJson;
        try {
          configJson = jsonDecode(configJsonStr) as Map<String, dynamic>;
        } catch (e, st) {
          loggy.warning('failed to decode config json for profile [${profile.id}]', e, st);
          continue;
        }
        headConfig ??= configJson;

        final rawOutbounds = configJson['outbounds'];
        if (rawOutbounds is! List) continue;
        final profileTags = <String>[];
        for (final rawOb in rawOutbounds) {
          if (rawOb is! Map<String, dynamic>) continue;
          final type = rawOb['type']?.toString() ?? '';
          final tag = rawOb['tag']?.toString() ?? '';
          if (tag.isEmpty) continue;
          // Skip group outbounds (selector / urltest / balancer) — these are
          // per-profile grouping constructs that we will replace with a
          // single merged `select` group.
          if (_groupOutboundTypes.contains(type)) continue;
          // Skip meta outbounds.
          if (_metaOutboundTags.contains(tag)) continue;
          if (_metaOutboundTypes.contains(type)) continue;

          // Defensive copy so we don't mutate the original config map.
          final ob = Map<String, dynamic>.from(rawOb);
          final prefixedTag = '${profile.id}::$tag';
          ob['tag'] = prefixedTag;
          mergedOutbounds.add(ob);
          profileTags.add(prefixedTag);
        }
        tagsByProfile[profile.id] = profileTags;
      }

      if (mergedOutbounds.isEmpty) {
        throw const ProfileFailure.invalidConfig(null, null);
      }

      // Always make sure the meta outbounds exist in the merged config — if
      // the head profile didn't include them (e.g. some configs omit `dns`
      // or `block`), we add safe defaults so the core doesn't fail to start.
      final existingTags = mergedOutbounds.map((e) => e['tag']?.toString() ?? '').toSet();
      void ensureMeta(String tag, String type) {
        if (!existingTags.contains(tag)) {
          mergedOutbounds.add({'tag': tag, 'type': type});
        }
      }

      ensureMeta('direct', 'direct');
      ensureMeta('block', 'block');
      ensureMeta('dns', 'dns');

      // The single top-level urltest group that pools every real outbound
      // from every active profile. The sing-box core's URLTest machinery
      // will auto-pick the lowest-delay member.
      final allTags = mergedOutbounds.map((e) => e['tag']?.toString() ?? '').where((t) => t.isNotEmpty).toList();
      final selectGroup = <String, dynamic>{
        'tag': 'select',
        'type': 'urltest',
        'outbounds': allTags,
        // Optional: explicit url-test config; the core also reads
        // `url-test-interval` / `connection-test-url` from the global
        // SingboxConfigOption, so leaving these out is fine.
      };
      mergedOutbounds.add(selectGroup);

      final mergedConfig = <String, dynamic>{
        // Re-use the first profile's metadata blocks.
        if (headConfig != null) ...{
          'log': headConfig['log'],
          'dns': headConfig['dns'],
          'inbounds': headConfig['inbounds'],
          'experimental': headConfig['experimental'],
        },
        'outbounds': mergedOutbounds,
      };

      // Patch the route block so the default outbound points to the merged
      // `select` group. The head profile's route likely pointed to its own
      // top-level `select` group (same tag) — so just take a shallow copy
      // and force the `outbound` field to `select`.
      if (headConfig != null && headConfig['route'] is Map<String, dynamic>) {
        final routeCopy = Map<String, dynamic>.from(headConfig['route'] as Map);
        routeCopy['outbound'] = 'select';
        // Some sing-box versions use `outbounds` (array) on the route or a
        // `default` field. Set both for safety.
        routeCopy['default'] = 'select';
        mergedConfig['route'] = routeCopy;
      }

      final file = _profilePathResolver.mergedFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(mergedConfig));
      loggy.info(
        'merged config written to [${file.path}] with ${allTags.length} outbound(s) '
        'from ${profiles.length} profile(s)',
      );
      return file.path;
    }, (err, st) {
      if (err is ProfileFailure) return err;
      return ProfileUnexpectedFailure(err, st);
    });
  }
}
