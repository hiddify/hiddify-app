import 'dart:typed_data';

class AppPackageInfo {
  const AppPackageInfo({required this.packageName, required this.name, required this.icon});
  final String packageName;
  final String name;
  final Uint8List? icon;
}
