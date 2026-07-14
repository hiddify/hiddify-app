import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

class NovaGroupedScaffold extends StatelessWidget {
  const NovaGroupedScaffold({super.key, this.appBar, this.body, this.floatingActionButton});

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);

    return Scaffold(
      backgroundColor: nova.groupedBackground,
      appBar: appBar,
      body: body == null ? null : SafeArea(top: false, left: false, right: false, child: body!),
      floatingActionButton: floatingActionButton,
    );
  }
}
