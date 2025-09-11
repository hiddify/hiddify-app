import 'dart:convert';

typedef WarpResponse = ({
  String log,
  String accountId,
  String accessToken,
  String wireguardConfig,
});

WarpResponse warpFromJson(dynamic json) {
  if (json
      case {
        "account-id": final String newAccountId,
        "access-token": final String newAccessToken,
        "log": final String log,
        "config": final Map<String, dynamic> wireguardConfig,
      }) {
    return (
      log: log,
      accountId: newAccountId,
      accessToken: newAccessToken,
      wireguardConfig: jsonEncode(wireguardConfig),
    );
  }
  throw Exception("invalid response");
}
