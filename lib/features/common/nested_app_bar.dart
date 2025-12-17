import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/utils/utils.dart';

bool showDrawerButton(BuildContext context) {
  if (!useMobileRouter) return true;
  final location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) {
    return true;
  }
  return false;
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
  Widget build(BuildContext context) => SliverAppBar(
    leading: _buildLeading(context),
    title: title,
    actions: actions,
    pinned: pinned,
    forceElevated: forceElevated,
    bottom: bottom,
  );

  Widget? _buildLeading(BuildContext context) {
    final scaffold = RootScaffold.stateKey.currentState;
    final hasDrawer = scaffold?.hasDrawer ?? false;

    if (hasDrawer && showDrawerButton(context)) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => scaffold?.openDrawer(),
      );
    }

    if (Navigator.of(context).canPop()) {
      return IconButton(
        icon: Icon(context.isRtl ? Icons.arrow_forward : Icons.arrow_back),
        onPressed: context.pop,
      );
    }

    return null;
  }
}
