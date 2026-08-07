/// Builds the minimal in-app HTML page that drives the Telegram Login JS SDK.
///
/// It connects to `https://oauth.telegram.org/js/telegram-login.js` and calls
/// `Telegram.Login.init(...)` with the build-time client id, then forwards the
/// callback payload to Dart through the `TelegramAuth` JavascriptChannel.
String telegramLoginHtml({required String clientId}) {
  // The client id is numeric and must appear as a raw number literal in the JS.
  final clientIdLiteral = clientId.trim();
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <title>Telegram Login</title>
  <style>
    html, body { margin: 0; padding: 0; height: 100%; }
    body {
      display: flex; align-items: center; justify-content: center;
      background: #fff; font-family: -apple-system, Roboto, sans-serif;
    }
    #tg-widget { width: 100%; max-width: 320px; }
  </style>
</head>
<body>
  <div id="tg-widget"></div>
  <script src="https://oauth.telegram.org/js/telegram-login.js?3"></script>
  <script>
    function postToDart(payload) {
      try {
        TelegramAuth.postMessage(JSON.stringify(payload));
      } catch (e) {
        // Dart channel not ready; ignore.
      }
    }
    function onTelegramAuth(data) {
      if (!data) {
        postToDart({ error: 'empty' });
        return;
      }
      if (data.error) {
        postToDart({ error: data.error });
        return;
      }
      if (data.id_token) {
        postToDart({ id_token: data.id_token });
        return;
      }
      postToDart({ error: 'no_token' });
    }
    Telegram.Login.init({
      client_id: $clientIdLiteral,
      request_access: ['write']
    }, onTelegramAuth);
  </script>
</body>
</html>
''';
}