import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef AdaptiveMenuBuilder = Widget Function(BuildContext context, void Function() toggleVisibility, Widget? child);

class AdaptiveMenuItem<T> {
  AdaptiveMenuItem({
    required this.title,
    this.leadingIcon,
    this.trailingIcon,
    this.divider = false,
    this.onTap,
    this.isSelected,
    this.subItems,
  });

  final String title;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool divider;
  final T Function()? onTap;
  final bool? isSelected;
  final List<AdaptiveMenuItem>? subItems;

  (String, Widget?, Widget?, bool, T Function()?, bool?, List<AdaptiveMenuItem<dynamic>>?) _equality() =>
      (title, leadingIcon, trailingIcon, divider, onTap, isSelected, subItems);

  @override
  bool operator ==(covariant AdaptiveMenuItem other) {
    if (identical(this, other)) return true;
    return other._equality() == _equality();
  }

  @override
  int get hashCode => _equality().hashCode;
}

class AdaptiveMenu extends HookConsumerWidget {
  const AdaptiveMenu({super.key, required this.items, required this.builder, required this.child});

  final Iterable<AdaptiveMenuItem> items;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> buildMenuItems(Iterable<AdaptiveMenuItem> scopeItems) {
      final menuItems = <Widget>[];
      for (final item in scopeItems) {
        if (item.subItems != null) {
          final subItems = buildMenuItems(item.subItems!);
          menuItems.add(
            SubmenuButton(
              menuChildren: subItems,
              leadingIcon: item.leadingIcon,
              trailingIcon: item.trailingIcon,
              child: Text(item.title),
            ),
          );
        } else {
          menuItems.add(
            MenuItemButton(
              leadingIcon: item.leadingIcon,
              trailingIcon: item.trailingIcon,
              onPressed: item.onTap,
              child: Text(item.title),
            ),
          );
        }
        if (item.divider) menuItems.add(const Divider());
      }
      return menuItems;
    }

    final menu = MenuAnchor(
      builder: (context, controller, child) => builder(context, () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      }, child),
      menuChildren: buildMenuItems(items),
      child: child,
    );

    // MenuAnchor positions the menu against the whole screen and ignores the
    // system bars, so near the bottom of the screen (a profile in the bottom
    // sheet) its last item ended up under the Android navigation bar. The only
    // obstructions its layout respects are display features (a foldable's
    // hinge), so report the status and navigation bars as such: the menu then
    // opens above the anchor when it does not fit below, like at a hinge.
    // The insets come from the view itself, since the sheet and the list the
    // anchor sits in have already removed them from its MediaQuery.
    final view = MediaQueryData.fromView(View.of(context));
    final top = view.padding.top;
    final bottom = view.padding.bottom + view.viewInsets.bottom;
    if (top <= 0 && bottom <= 0) return menu;
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        displayFeatures: [
          ...mediaQuery.displayFeatures,
          if (top > 0) _systemBar(Rect.fromLTWH(0, 0, view.size.width, top)),
          if (bottom > 0) _systemBar(Rect.fromLTWH(0, view.size.height - bottom, view.size.width, bottom)),
        ],
      ),
      child: menu,
    );
  }

  static DisplayFeature _systemBar(Rect bounds) =>
      DisplayFeature(bounds: bounds, type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown);
}
