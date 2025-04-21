import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PlatformListSection extends StatelessWidget {
  Widget sectionTitle;
  final List<Widget>? items;
  final Widget? page;
  final Widget sectionIcon;
  final bool showAppBar;
  final bool openOnLoad;
  final Widget? title;
  final bool bottomSheet;

  PlatformListSection({
    required this.sectionIcon,
    required String sectionTitle,
    this.items,
    this.page,
    this.showAppBar = true,
    this.openOnLoad = false,
    this.title,
    this.bottomSheet = false,
  }) : sectionTitle = Text(sectionTitle);

  void _navigateToDetailsPage(BuildContext context) {
    if (bottomSheet) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Scaffold(
          appBar: showAppBar ? AppBar(title: sectionTitle) : null,
          body: page ?? (items == null ? Container() : ListView(children: items!)),
        ),
      );
    } else {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          appBar: showAppBar ? AppBar(title: sectionTitle) : null,
          body: page ?? (items == null ? Container() : ListView(children: items!)),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Start from the right
          const end = Offset.zero; // End at the center
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ));
    }
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
