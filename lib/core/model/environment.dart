import 'package:dartx/dartx.dart';

enum Environment {
  prod,
  dev;

  static const sentryDSN = String.fromEnvironment("sentry_dsn");
}

enum Release {
  general("general"),
  googlePlay("google-play");

  const Release(this.key);

  final String key;

  bool get allowCustomUpdateChecker => this == general;

  static Release read() =>
      Release.values.firstOrNullWhere(
        (e) => e.key == const String.fromEnvironment("release"),
      ) ??
      Release.general;
}
