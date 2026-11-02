import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';

/// A proxy's display type on one line. The endpoint the WARP scanner chose stays hidden behind a
/// magnifier: a tap on it shows the endpoint in place, another tap hides it again.
class ProxyTypeLabel extends HookWidget {
  const ProxyTypeLabel(this.type, {super.key, this.style, this.prefix = '', this.suffix = const []});

  final String type;
  final TextStyle? style;

  /// Text before the type, such as a separator.
  final String prefix;

  /// Spans after the type, such as the server a group picked.
  final List<InlineSpan> suffix;

  @override
  Widget build(BuildContext context) {
    final shown = useState(false);
    final parts = splitScannerEndpoint(type);
    final InlineSpan span;
    if (parts == null) {
      span = TextSpan(text: '$prefix$type', children: suffix);
    } else {
      final base = DefaultTextStyle.of(context).style.merge(style);
      final color = shown.value ? Theme.of(context).colorScheme.primary : base.color;
      span = TextSpan(
        text: '$prefix${parts.before} · ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => shown.value = !shown.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Icon(Icons.search_rounded, size: (base.fontSize ?? 12) + 3, color: color),
              ),
            ),
          ),
          if (shown.value)
            TextSpan(
              text: ' ${parts.endpoint}',
              style: TextStyle(color: color),
            ),
          TextSpan(text: parts.after),
          ...suffix,
        ],
      );
    }
    return Text.rich(span, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
  }
}
