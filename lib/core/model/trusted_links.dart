/// Curated allow-list of official links from verified teams, used to decide how a
/// subscription-provided link (`profile-web-page-url` / `support-url`) is opened:
/// a light confirmation for trusted links, or a serious anti-impersonation
/// warning (with a countdown) for everything else.
///
/// Why: scammers publish look-alike channels/sites (e.g. `t.me/Hiddiify` vs the
/// real `t.me/hiddify`) inside fake subscriptions to steal donations. Only links
/// that exactly match an entry here are treated as trusted.
///
/// The list is managed by the project manager. It is static for now and may
/// later be fetched from GitHub. There is no public "add my link" request flow.
///
/// Matching is EXACT (full URL). Entries and the tapped url are normalized the
/// same way before comparison (see [_normalize]):
/// - the scheme is ignored (http/https treated the same),
/// - the host is lowercased and a leading `www.` is stripped,
/// - a trailing `/` and any `#fragment` are removed,
/// - the path and query are compared exactly (case-sensitive).
///
/// So `t.me/hiddify` matches `https://t.me/hiddify/` and `https://www.t.me/hiddify`,
/// but NOT `t.me/hiddify/123`, `t.me/hiddify?x=1`, or the look-alike `t.me/Hiddiify`.
abstract class TrustedLinks {
  /// TODO(pm): test seed — Hiddify only. Complete later (e.g. MahsaNET, IRCF, …).
  static const List<String> entries = [
    'hiddify.com',
    'github.com/hiddify',
    't.me/hiddify',
  ];

  static final Set<String> _normalizedEntries = entries.map(_normalize).whereType<String>().toSet();

  /// Whether [url] exactly matches a curated trusted entry.
  static bool isTrusted(String url) {
    final normalized = _normalize(url);
    return normalized != null && _normalizedEntries.contains(normalized);
  }

  /// Canonical comparison key for [url], or null if it can't be parsed to a host.
  static String? _normalize(String url) {
    var raw = url.trim();
    if (raw.isEmpty) return null;
    // Allow entries/links written without a scheme, e.g. `t.me/hiddify`.
    if (!raw.contains('://')) raw = 'https://$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    var path = uri.path;
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$host$path$query';
  }
}
