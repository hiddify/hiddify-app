import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/utils/utils.dart';

bool showDrawerButton(BuildContext context) {
  // if (!useMobileRouter) return true;
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location || location == const ProfilesOverviewRoute().location) return true;
  if (location.startsWith(const ProfilesOverviewRoute().location)) return true;
  return true;
}

class NestedAppBar extends StatelessWidget {
  const NestedAppBar({
    super.key,
    this.title,
    this.actions,
    this.pinned = true,
    this.forceElevated = false,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final bool pinned;
  final bool forceElevated;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    RootScaffold.canShowDrawer(context);

    return PlatformSliverAppBar(
      leading: (RootScaffold.stateKey.currentState?.hasDrawer ?? false) && showDrawerButton(context)
          ? DrawerButton(
              onPressed: () {
                RootScaffold.stateKey.currentState?.openDrawer();
              },
            )
          : (Navigator.of(context).canPop()
              ? IconButton(
                  // icon: Icon(context.isRtl ? Icons.arrow_forward : Icons.arrow_back),
                  icon: Icon(Icons.arrow_back),

                  // padding: EdgeInsets.only(right: context.isRtl ? 50 : 0),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // Pops the current route off the navigator stack
                  },
                )
              : null),
      title: title,
      // title: PlatformText("", style: Theme.of(context).textTheme.labelSmall),
      material: (context, platform) => MaterialSliverAppBarData(
        actions: actions,
        pinned: pinned,
        forceElevated: forceElevated,
        bottom: bottom,
      ),
      cupertino: (_, __) => CupertinoSliverAppBarData(
        // middle: title,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
      ),
    );
  }
}
