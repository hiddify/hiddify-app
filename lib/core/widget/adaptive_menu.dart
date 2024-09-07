import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

typedef AdaptiveMenuBuilder = Widget Function(
  BuildContext context,
  void Function() toggleVisibility,
  Widget? child,
);

class AdaptiveMenuItem<T> {
  AdaptiveMenuItem({
    required this.title,
    this.icon,
    this.onTap,
    this.isSelected,
    this.subItems,
  });

  final String title;
  final IconData? icon;
  final T Function()? onTap;
  final bool? isSelected;
  final List<AdaptiveMenuItem>? subItems;

  (String, IconData?, T Function()?, bool?, List<AdaptiveMenuItem>?) _equality() => (title, icon, onTap, isSelected, subItems);

  @override
  bool operator ==(covariant AdaptiveMenuItem other) {
    if (identical(this, other)) return true;
    return other._equality() == _equality();
  }

  @override
  int get hashCode => _equality().hashCode;
}

class AdaptiveMenu extends HookConsumerWidget {
  const AdaptiveMenu({
    super.key,
    required this.items,
    required this.builder,
    required this.child,
  });

  final Iterable<AdaptiveMenuItem> items;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isDesktop) {
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
        builder: (context, controller, child) => builder(
          context,
          () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child,
        ),
        menuChildren: buildMenuItems(items),
        child: child,
      );
    }

    final pageIndexNotifier = useValueNotifier(0);
    final nestedSheets = <SliverWoltModalSheetPage>[];
    int pageIndex = 0;

    void popSheets() {
      if (context.mounted) {
        Navigator.pop(context);
      }
      Future.delayed(const Duration(milliseconds: 200)).then((_) => pageIndexNotifier.value = 0);
    }

    List<Widget> buildSheetItems(
      Iterable<AdaptiveMenuItem> menuItems,
      int index,
    ) {
      final sheetItems = <Widget>[];
      for (final item in menuItems) {
        if (item.subItems != null) {
          final subItems = buildSheetItems(item.subItems!, index + 1);
          final subSheetIndex = ++pageIndex;
          sheetItems.add(
            PlatformListTile(
              title: Text(item.title),
              leading: item.icon != null ? Icon(item.icon) : null,
              trailing: const Icon(FluentIcons.chevron_right_20_regular, size: 20),
              onTap: () {
                pageIndexNotifier.value = subSheetIndex;
              },
            ),
          );
          nestedSheets.add(
            SliverWoltModalSheetPage(
              hasTopBarLayer: false,
              isTopBarLayerAlwaysVisible: true,
              topBarTitle: Text(item.title),
              mainContentSlivers: [
                SliverList.list(children: subItems),
              ],
            ),
          );
        } else {
          sheetItems.add(
            PlatformListTile(
              title: Text(item.title),
              leading: item.icon != null ? Icon(item.icon) : null,
              onTap: () async {
                popSheets();
                await item.onTap!();
              },
            ),
          );
        }
      }
      return sheetItems;
    }

    return builder(
      context,
      () async {
        await WoltModalSheet.show(
          context: context,
          pageIndexNotifier: pageIndexNotifier,
          onModalDismissedWithDrag: popSheets,
          onModalDismissedWithBarrierTap: popSheets,
          useSafeArea: true,
          showDragHandle: false,
          pageListBuilder: (context) => [
            SliverWoltModalSheetPage(
              hasTopBarLayer: false,
              mainContentSlivers: [
                SliverList.list(children: buildSheetItems(items, 0)),
              ],
            ),
            ...nestedSheets,
          ],
        );
      },
      child,
    );
  }
}
