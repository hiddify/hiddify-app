const String fallbackObscuredAddress = "*.*.*.*";

String obscureIp(String ip) {
  try {
    if (ip.contains(".")) {
      final splits = ip.split(".");
      return "${splits.first}.*.*.${splits.last}";
    } else if (ip.contains(":")) {
      final splits = ip.split(":");
      return [splits.first, ...splits.sublist(1).map((part) => "*" * part.length)].join(":");
    }
    // ignore: empty_catches
  } catch (e) {}
  return fallbackObscuredAddress;
}
