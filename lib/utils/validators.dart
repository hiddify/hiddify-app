/// https://gist.github.com/dperini/729294
final _urlRegex = RegExp(
  // r"^(?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z0-9\u00a1-\uffff][a-z0-9\u00a1-\uffff_-]{0,62})?[a-z0-9\u00a1-\uffff]\.)+(?:[a-z\u00a1-\uffff]{2,}\.?))(?::\d{2,5})?(?:[/?#]\S*)?$",
  r'^(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?:[0-9]{1,3}\.){3}[0-9]{1,3}|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?#?.*$',
);

/// https://stackoverflow.com/a/12968117
final _portRegex = RegExp(r"^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$");

// android package-name
// RegExp(r'^([A-Za-z]{1}[A-Za-z\d_]*\.)+[A-Za-z][A-Za-z\d_]*$');
// windows prcess name
// RegExp(r"^(?!\s)[a-zA-Z\d\s\-\]\^!@#$%&()[+_=~'`.,;]+(?<![\s.]|CON|PRN|AUX|NUL|COM[\d]|COM[¹²³]|LPT[\d]|LPT[¹²³])\.(exe|bat|cmd|com)$", caseSensitive: false);
// linux process name
// RegExp(r'''^(?!\s)[a-zA-Z\d\s\-\]\^\\!?@#$%&*()[<>+_=|~'`".,:;]+(?<!\s)$''');
// mac process name
// RegExp(r'''^(?!\s)[a-zA-Z\d\s\-\]\^\\!?@#$%&*()[<>+_=|~'`".,;]+(?<!\s)$''');
// domain
// RegExp(r'^((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+([a-z]{2,63}|xn--[a-z0-9-]{1,63})$');

final _processNameWindowsRegex = RegExp(r'^[^<>:"\\/|?*]+(?<![\s.])\.(exe|bat|cmd|com)$', caseSensitive: false);

final _processNameLinuxRegex = RegExp(r'^[^\\]+$');

final _processNameMacOSRegex = RegExp(r'^[^\\:]+$');

final _processPathWindowsRegex = RegExp(
  r'^[a-zA-Z]:\\([^<>:"\\/|?*]*(?<!\\)\\)*[^<>:"\\/|?*]+(?<![\s.])\.(exe|bat|cmd|com)$',
  caseSensitive: false,
);

final _processPathLinuxRegex = RegExp(r'^/([^/]*(?<!/)/)*[^/]+$');

final _processPathMacOSRegex = RegExp(r'^/([^/:]*(?<!/)/)*[^/:]+$');

final _portOrPortRangeRegex = RegExp(
  r'^(65000|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3})(-(65000|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}))?$',
);

final _ipCidrRegex = RegExp(
  r'^(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})\.(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})\.(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2}).(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})(/(3[0-2]|[1-2]\d|\d))?$',
);

final _domainRegex = RegExp(r'^([a-zA-Z\d\-]+\.)+[a-zA-Z\d\-]{2,}$', caseSensitive: false);

final _domainSuffix = RegExp(r'^\.[a-zA-Z\d\-]{2,}$', caseSensitive: false);

/// https://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url/3809435#3809435
bool isUrl(String input) {
  return _urlRegex.hasMatch(input.trim().toLowerCase());
}

bool isPort(String input) {
  return _portRegex.hasMatch(input);
}

bool isProcessName(String input) {
  if (_processNameWindowsRegex.hasMatch(input) ||
      _processNameLinuxRegex.hasMatch(input) ||
      _processNameMacOSRegex.hasMatch(input)) {
    return true;
  } else {
    return false;
  }
}

bool isProcessPath(String input) {
  if (_processPathWindowsRegex.hasMatch(input) ||
      _processPathLinuxRegex.hasMatch(input) ||
      _processPathMacOSRegex.hasMatch(input)) {
    return true;
  } else {
    return false;
  }
}

bool isPortOrPortRange(String input) {
  return _portOrPortRangeRegex.hasMatch(input);
}

bool isIpCidr(String input) {
  return _ipCidrRegex.hasMatch(input);
}

bool isDomain(String input) {
  return _domainRegex.hasMatch(input);
}

bool isDomainSuffix(String input) {
  return _domainSuffix.hasMatch(input);
}
