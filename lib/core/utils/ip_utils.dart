const String fallbackObscuredAddress = '*.*.*.*';

String obscureIp(String ip) {
  try {
    if (ip.contains('.')) {
      final splits = ip.split('.');
      return '${splits.first}.*.*.${splits.last}';
    } else if (ip.contains(':')) {
      final splits = ip.split(':');
      return [
        splits.first,
        ...splits.sublist(1).map((part) => '*' * part.length),
      ].join(':');
    }
  } catch (_) {
    // Intentionally empty - fallback to obscured address
  }
  return fallbackObscuredAddress;
}
