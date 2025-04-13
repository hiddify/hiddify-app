import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/add/widgets/free_btns.dart';
import 'package:hiddify/features/profile/add/widgets/widgets.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddProfileModal extends HookConsumerWidget {
  const AddProfileModal({
    super.key,
    this.url,
  });
  static const warpConsentGiven = "warp_consent_given";
  final String? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addProfileState = ref.watch(addProfileProvider);
    final freeSwitch = ref.watch(freeSwitchProvider);
    final isDesktop = PlatformUtils.isDesktop;
    final loadingProfile = addProfileState.isLoading;

    ref.listen(
      addProfileProvider,
      (previous, next) {
        if (next case AsyncData(value: final _?)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (context.mounted && context.canPop()) context.pop();
            },
          );
        }
      },
    );

    useMemoized(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (url != null && context.mounted) {
        if (loadingProfile) return;
        ref.read(addProfileProvider.notifier).add(url!);
      }
    });
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fixBtnsHeight = (constraints.maxWidth - AddProfileModalConst.fixBtnsGap * AddProfileModalConst.fixBtnsGapCount) / AddProfileModalConst.fixBtnsItemCount;
          final fullHeight = fixBtnsHeight + AddProfileModalConst.navBarHeight + 32;
          final initial = !freeSwitch || loadingProfile ? fullHeight : fullHeight + 180;
          var min = !freeSwitch || loadingProfile ? fullHeight : fullHeight + 100;
          var max = !freeSwitch || loadingProfile ? fullHeight / constraints.maxHeight : 0.85;
          if (isDesktop) {
            min = initial;
            max = initial / constraints.maxHeight;
          }
          return DraggableScrollableSheet(
            initialChildSize: initial / constraints.maxHeight,
            minChildSize: min / constraints.maxHeight,
            maxChildSize: max,
            expand: false,
            builder: (context, scrollController) {
              return loadingProfile
                  ? const Loading()
                  : Column(
                      children: [
                        const Gap(AddProfileModalConst.fixBtnsGap),
                        FixBtns(height: fixBtnsHeight),
                        if (freeSwitch) Expanded(child: FreeBtns(scrollController: scrollController)) else const Spacer(),
                        const NavBar(),
                      ],
                    );
            },
          );
        },
      ),
    );
  }
}
