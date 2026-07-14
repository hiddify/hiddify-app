String? normalizeOptionalEmail(String input) {
  final normalized = input.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

bool isValidEmail(String input) {
  final normalized = normalizeOptionalEmail(input);
  if (normalized == null || normalized.length > 254 || normalized.contains(RegExp(r'\s'))) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(normalized);
}
