import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_profile_notifier.g.dart';

/// Singular active-profile stream.
///
/// In multi-profile mode there may be MORE than one active profile at a time.
/// This notifier keeps returning the FIRST active one for backward compatibility
/// with code paths (e.g. `ChainProfileNotifier`) that still expect a single
/// `ProfileEntity?`.
@Riverpod(keepAlive: true)
class ActiveProfile extends _$ActiveProfile with AppLogger {
  @override
  Stream<ProfileEntity?> build() {
    loggy.debug("watching active profile");
    return ref.watch(profileDataSourceProvider).watchActiveProfile().map((event) => event?.toEntity());
  }
}

/// Plural active-profile stream.
///
/// Emits the FULL list of currently-active profiles. This is the source of
/// truth for the "pool all active profiles, pick the fastest node across all"
/// feature. When the user toggles a profile's active flag (UI checkbox) the
/// `ProfileDao` updates only that row, and this stream emits a new list.
@Riverpod(keepAlive: true)
class ActiveProfiles extends _$ActiveProfiles with AppLogger {
  @override
  Stream<List<ProfileEntity>> build() {
    loggy.debug("watching active profiles (plural)");
    return ref
        .watch(profileDataSourceProvider)
        .watchActiveProfiles()
        .map((event) => event.map((e) => e.toEntity()).toList());
  }
}

// TODO: move to specific feature
@Riverpod(keepAlive: true)
Stream<bool> hasAnyProfile(Ref ref) {
  return ref.watch(profileDataSourceProvider).watchProfilesCount().map((event) => event != 0).distinct();
}
