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
