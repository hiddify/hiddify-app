import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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

    // MenuAnchor keeps the menu inside the overlay it opens in, but not clear
    // of the system bars, so near the bottom of the screen (a profile in the
    // bottom sheet) its last item ended up under the Android navigation bar.
    // The only obstructions its layout respects are display features (a
    // foldable's hinge), so the bars are reported as such: the menu then opens
    // above the anchor when it does not fit below, like at a hinge.
    // Display features are in the coordinates of that overlay, which is not
    // always the whole screen: a page of the home shell has its own, ending
    // above the bottom navigation. So the bars are measured against it when
    // the menu opens, once it has been laid out.
    final systemBars = useState(const <DisplayFeature>[]);

    final menu = MenuAnchor(
      builder: (context, controller, child) => builder(context, () {
        if (controller.isOpen) {
          controller.close();
        } else {
          systemBars.value = _systemBars(context);
          controller.open();
        }
      }, child),
      menuChildren: buildMenuItems(items),
      child: child,
    );

    // Always wrapped, so opening the menu does not change the tree above it.
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(displayFeatures: [...mediaQuery.displayFeatures, ...systemBars.value]),
      child: menu,
    );
  }

  /// The parts of the status and navigation bars (and the keyboard) that cover the overlay the menu
  /// opens in, in that overlay's coordinates. The insets come from the view itself, since the sheet
  /// and the list the anchor sits in have already removed them from its MediaQuery.
  static List<DisplayFeature> _systemBars(BuildContext context) {
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return const [];
    final view = MediaQueryData.fromView(View.of(context));
    final origin = overlay.localToGlobal(Offset.zero);
    final size = overlay.size;
    final top = view.padding.top - origin.dy;
    final bottom = view.size.height - view.padding.bottom - view.viewInsets.bottom - origin.dy;
    return [
      if (top > 0) _systemBar(Rect.fromLTRB(0, 0, size.width, top)),
      if (bottom < size.height) _systemBar(Rect.fromLTRB(0, bottom, size.width, size.height)),
    ];
  }

  static DisplayFeature _systemBar(Rect bounds) =>
      DisplayFeature(bounds: bounds, type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown);
}
