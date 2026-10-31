import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'profile_details_state.freezed.dart';

/// The config the editor shows: its text, and whether it is JSON (the tree editor) or not (plain
/// text). Worked out once when it loads, not on every rebuild.
typedef EditableConfig = ({String text, bool isJson});

@freezed
class ProfileDetailsState with _$ProfileDetailsState {
  const ProfileDetailsState._();

  const factory ProfileDetailsState({
    required AsyncValue<void> loadingState,
    required ProfileEntity profile,
    // Loads after the profile: a large config takes long to generate, and the name and the
    // subscription can be edited meanwhile.
    required AsyncValue<EditableConfig> config,
    required bool isDetailsChanged,
  }) = _ProfileDetailsState;

  bool get isLoading => loadingState is AsyncLoading;
}
