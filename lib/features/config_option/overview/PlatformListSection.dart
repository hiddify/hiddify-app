import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformListSection extends StatelessWidget {
  Widget sectionTitle;
  final List<Widget>? items;
  final Widget? page;
  final Widget sectionIcon;
  final bool showAppBar;
  final bool openOnLoad;
  final Widget? title;

  PlatformListSection({
    required this.sectionIcon,
    required String sectionTitle,
    this.items,
    this.page,
    this.showAppBar = true,
    this.openOnLoad = false,
    this.title,
  }) : sectionTitle = Text(sectionTitle);

  void _navigateToDetailsPage(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
        appBar: showAppBar ? AppBar(title: sectionTitle) : null,
        body: page ?? (items == null ? Container() : ListView(children: items!)),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Start from the right
        const end = Offset.zero; // End at the center
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
      leading: sectionIcon,
      title: title ?? sectionTitle,
      onTap: () => _navigateToDetailsPage(context),
      trailing: const Icon(FluentIcons.chevron_right_20_regular),
    ));
  }
}
