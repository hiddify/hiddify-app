import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final homePresentationDiagnosticsEnabledProvider = Provider<bool>((ref) => PlatformUtils.isIOS);

final homePresentationRuntimeIosProvider = Provider<bool>((ref) => PlatformUtils.isIOS);

final homePresentationSnapshotProvider = StateProvider<HomePresentationSnapshot?>((ref) => null);
