import 'package:flutter/material.dart';

//Helper class for storing details for each navigation action in my_adaptive_layout.dart
class ShellRouteAction {
  final IconData icon;
  final String title;

  /// The icon of the selected destination. Defaults to [icon].
  final IconData? selectedIcon;

  ShellRouteAction(this.icon, this.title, {this.selectedIcon});
}
