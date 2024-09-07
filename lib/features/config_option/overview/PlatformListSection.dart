import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformListSection extends StatelessWidget {
  final String sectionTitle;
  final List<Widget> items;

  PlatformListSection({required this.sectionTitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PlatformWidget(
        material: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                sectionTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Card(
              elevation: 4.0,
              child: Column(children: items),
            ),
          ],
        ),
        cupertino: (_, __) => CupertinoListSection.insetGrouped(
            header: Text(sectionTitle), // Only show header here for Cupertino
            children: items),
      ),
    );
  }
}
