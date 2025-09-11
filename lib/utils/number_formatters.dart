import 'package:humanizer/humanizer.dart';

extension ByteFormatter on int {
  String size() => bytes().toString();

  static final _sizeOfFormat =
      InformationSizeFormat(permissibleValueUnits: {InformationUnit.gibibyte});

  String sizeGB() => _sizeOfFormat.format(bytes());

  String sizeOf(int total) =>
      "${_sizeOfFormat.format(bytes())} / ${_sizeOfFormat.format(total.bytes())}";

  static final _rateFormat =
      InformationRateFormat(permissibleRateUnits: {RateUnit.second});

  String speed() => _rateFormat.format(bytes().per(const Duration(seconds: 1)));
}
