import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';

abstract class GithubReleaseParser {
  /// A release's tag: v5.4.0, optionally with a pre-release (v5.4.0-beta.1, v5.4.0.dev) or a build
  /// number (v5.4.0+540). Tags that are no version, like the rolling "draft" release, do not match.
  static final _tag = RegExp(r'^v?(\d+\.\d+\.\d+)(?:[-.]([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$');

  /// The release, or null when its tag names no version or it is a draft.
  static RemoteVersionEntity? parse(Map<String, dynamic> json) {
    if (json['draft'] == true) return null;
    final fullTag = (json['tag_name'] as String? ?? '').trim();
    final match = _tag.firstMatch(fullTag);
    if (match == null) return null;
    final suffix = match.group(2) ?? '';
    final flavor = suffix == Environment.dev.name ? Environment.dev : Environment.prod;
    final assets = [
      for (final asset in json['assets'] as List? ?? const [])
        if (asset case {'name': final String name, 'browser_download_url': final String url})
          ReleaseAsset(
            name: name,
            url: url,
            size: (asset['size'] as num?)?.toInt() ?? 0,
            digest: asset['digest'] is String ? asset['digest'] as String : null,
          ),
    ];
    return RemoteVersionEntity(
      version: match.group(1)!,
      buildNumber: match.group(3) ?? '',
      releaseTag: fullTag,
      // the release workflow uploads every release as a GitHub pre-release and it is promoted to
      // a full release once tested: until then only beta users get it, as they get a .dev tag
      preRelease: suffix.isNotEmpty || json['prerelease'] == true,
      url: json['html_url'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      flavor: flavor,
      assets: assets,
      changelog: changelog(json['body'] as String? ?? ''),
    );
  }

  /// A heading that opens the release's change log: "# Change Logs", "## Changelog",
  /// "## What's new", "## Highlights" or "## تغییرات".
  static final _changelogHeading = RegExp(
    r"^(#{1,6})\s*(?:change\s*-?\s*logs?|changes|what'?s\s+new|highlights?|تغییرات)\s*:?\s*#*\s*$",
    caseSensitive: false,
  );
  static final _heading = RegExp(r'^(#{1,6})\s');
  static final _downloads = RegExp('download', caseSensitive: false);
  static final _comment = RegExp('<!--.*?-->', dotAll: true);
  static final _rule = RegExp(r'^(?:-{3,}|\*{3,}|_{3,})$');

  /// The longest change log the dialog shows; past it the release page has the rest.
  static const maxChangelogLength = 4000;

  /// The change log section of a release body in Markdown: from its heading to the next heading
  /// of the same or a higher level, a downloads heading, a `---` rule or the download table. Null when the body has
  /// none or it is empty.
  static String? changelog(String body) {
    final lines = body.replaceAll('\r\n', '\n').replaceAll(_comment, '').split('\n');
    final start = lines.indexWhere((l) => _changelogHeading.hasMatch(l.trim()));
    if (start < 0) return null;
    final level = _changelogHeading.firstMatch(lines[start].trim())!.group(1)!.length;
    final section = <String>[];
    for (final line in lines.skip(start + 1)) {
      final trimmed = line.trim();
      final heading = _heading.firstMatch(trimmed);
      if (heading != null && (heading.group(1)!.length <= level || _downloads.hasMatch(trimmed))) break;
      if (_rule.hasMatch(trimmed) || trimmed.startsWith('<table')) break;
      section.add(line);
    }
    var text = section.join('\n').trim();
    if (text.isEmpty) return null;
    if (text.length > maxChangelogLength) {
      final cut = text.lastIndexOf('\n', maxChangelogLength);
      text = '${text.substring(0, cut > 0 ? cut : maxChangelogLength).trimRight()}\n\n…';
    }
    return text;
  }
}
