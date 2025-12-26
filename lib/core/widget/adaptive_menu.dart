import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef AdaptiveMenuBuilder = Widget Function(BuildContext context, void Function() toggleVisibility, Widget? child);

class AdaptiveMenuItem<T> {
  AdaptiveMenuItem({required this.title, this.icon, this.onTap, this.isSelected, this.subItems});

  final String title;
  final IconData? icon;
  final T Function()? onTap;
  final bool? isSelected;
  final List<AdaptiveMenuItem>? subItems;

  (String, IconData?, T Function()?, bool?, List<AdaptiveMenuItem>?) _equality() =>
      (title, icon, onTap, isSelected, subItems);

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
              leadingIcon: item.icon != null ? Icon(item.icon) : null,
              child: Text(item.title),
            ),
          );
        } else {
          menuItems.add(
            MenuItemButton(
              leadingIcon: item.icon != null ? Icon(item.icon) : null,
              onPressed: item.onTap,
              child: Text(item.title),
            ),
          );
        }
      }
      return menuItems;
    }

    return MenuAnchor(
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
  }
}
