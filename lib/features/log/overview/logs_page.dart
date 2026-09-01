import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger_setup.dart';
import 'package:hiddify/core/logger/ring/log_ring.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/log/model/log_level.dart' as engine;
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

/// How close to the bottom still counts as "at the bottom". A row is taller
/// than this, so it takes a deliberate scroll to detach, not a stray pixel.
const _bottomSlack = 24.0;

/// Below this window width the filter bar cannot hold four controls side by
/// side and still leave the search field usable, so it splits into two rows.
///
/// Window width, not the bar's own — that is how the rest of the app states a
/// breakpoint, and the bar is narrower than the window by the nav rail.
const _oneRowMinWindowWidth = 700.0;

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> with PresLogger {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// Terminal behaviour: the view follows the newest line until you scroll up,
  /// and follows again as soon as you come back to the bottom. Not in
  /// [setState] — nothing on screen depends on it.
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// go_router keeps an inactive shell branch mounted but disables its tickers.
  /// Depending on that here stops the notifier refreshing a page nobody can
  /// see, and starts it again on return.
  ///
  /// Deferred to after the frame on purpose. This runs before the first build,
  /// so the provider does not exist yet, and telling it to change state during
  /// a build would not be allowed either.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(logsOverviewNotifierProvider.notifier).setVisible(visible);
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _follow = position.maxScrollExtent - position.pixels < _bottomSlack;
  }

  /// New rows land below the fold, so following means jumping after the frame
  /// that laid them out — the extent is not known before then.
  void _stickToBottom() {
    if (!_follow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.pixels < position.maxScrollExtent) {
        _scroll.jumpTo(position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = ref.watch(logsOverviewNotifierProvider);
    final notifier = ref.watch(logsOverviewNotifierProvider.notifier);

    _stickToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.logs.title),
        actions: [
          const _BufferChip(),
          const SizedBox(width: 4),
          IconButton(
            onPressed: state.paused ? notifier.resume : notifier.pause,
            icon: Icon(
              state.paused
                  ? FluentIcons.play_20_regular
                  : FluentIcons.pause_20_regular,
            ),
            tooltip: state.paused ? t.common.resume : t.common.pause,
            iconSize: 20,
          ),
          IconButton(
            onPressed: notifier.clear,
            icon: const Icon(FluentIcons.delete_lines_20_regular),
            tooltip: t.common.clear,
            iconSize: 20,
          ),
          IconButton(
            onPressed: () =>
                ref.read(bottomSheetsNotifierProvider.notifier).showLogsShare(),
            icon: const Icon(FluentIcons.share_20_regular),
            tooltip: t.common.share,
            iconSize: 20,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // The controls sit under the list, next to the newest line rather than
      // the oldest one, which is the end everybody watches.
      body: Column(
        children: [
          Expanded(child: _LogList(logs: state.logs, controller: _scroll)),
          const Divider(height: 1),
          LogFilterBar(
            category: state.category,
            minLevel: state.minLevel,
            onCategory: notifier.filterCategory,
            onLevel: notifier.filterLevel,
            search: _search,
            onSearch: notifier.filterText,
            showCoreLevel: true,
          ),
        ],
      ),
    );
  }
}

/// What the core records, as opposed to the two filters beside it, which only
/// hide rows that were already recorded.
///
/// The core reads this when it connects, so a change made now shows up on the
/// next connection. The toast is the only place that can say so, since the chip
/// itself has no room for a caption.
class _CoreLevelChip extends ConsumerWidget {
  const _CoreLevelChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return _DropdownChip<engine.LogLevel>(
      label: t.pages.logs.coreLogLevel,
      value: ref.watch(ConfigOptions.logLevel),
      options: engine.LogLevel.choices,
      nameOf: (value) => value.name,
      onSelected: (value) async {
        if (value == null) return;
        // Read before the await: the status can change while it is in flight.
        final connected =
            !(ref.read(connectionNotifierProvider).value?.isDisconnected ??
                true);
        await ref.read(ConfigOptions.logLevel.notifier).update(value);
        // Nothing to reconnect while it is down — the next connection picks
        // this up on its own, so saying so would be noise.
        if (!connected) return;
        ref
            .read(inAppNotificationControllerProvider)
            .showInfoToast(t.pages.logs.coreLogLevelMsg);
      },
    );
  }
}

/// How many records the ring keeps. A tap cycles the three sizes rather than
/// opening a menu — there are only three, and the value is readable on the chip
/// either way.
class _BufferChip extends ConsumerWidget {
  const _BufferChip();

  static const _sizes = <int>[1000, 2500, 5000];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final size = ref.watch(Preferences.logBufferSize);

    return InkWell(
      onTap: () {
        final next = _sizes[(_sizes.indexOf(size) + 1) % _sizes.length];
        ref.read(logsOverviewNotifierProvider.notifier).setCapacity(next);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: _chipShape(theme),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.pages.logs.buffer,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
            Text('$size', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Borrowed from the per-app-proxy page, so the whole app draws a dropdown the
/// same way: a filled rounded rect with a hairline, not a pill.
BoxDecoration _chipShape(ThemeData theme) => BoxDecoration(
  borderRadius: BorderRadius.circular(8),
  color: theme.colorScheme.surface,
  border: Border.all(color: theme.colorScheme.outlineVariant),
);

/// Category, level, free text and the way into what gets recorded.
///
/// The first three only hide rows — the ring keeps every record regardless, so
/// turning a filter off brings the history back. [trailing] does the opposite,
/// which is why a divider separates it.
///
/// Shared with the share sheet, which asks the same two questions about what to
/// send and passes neither a search field nor the advanced button.
class LogFilterBar extends ConsumerWidget {
  const LogFilterBar({
    super.key,
    required this.category,
    required this.minLevel,
    required this.onCategory,
    required this.onLevel,
    this.search,
    this.onSearch,
    this.showCoreLevel = false,
  });

  final LogCategory? category;
  final Level minLevel;
  final ValueChanged<LogCategory?> onCategory;
  final ValueChanged<Level> onLevel;

  /// Left out by the share sheet, which carries the page's text over rather
  /// than asking for it a second time.
  final TextEditingController? search;
  final ValueChanged<String>? onSearch;

  /// Also left out by the share sheet: it decides what to send from what has
  /// already been recorded, and cannot change what the core records.
  final bool showCoreLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final chips = [
      _DropdownChip<LogCategory>(
        label: t.pages.logs.category,
        value: category,
        options: LogCategory.values,
        nameOf: (value) => value.name,
        allLabel: t.common.all,
        onSelected: onCategory,
      ),
      const SizedBox(width: 6),
      _DropdownChip<Level>(
        label: t.pages.logs.level,
        value: minLevel,
        options: uiLevels,
        nameOf: (value) => value.shortName,
        // No "All": trace is the lowest level anything is written at, so it
        // already selects everything.
        onSelected: (value) => onLevel(value!),
      ),
      if (showCoreLevel) ...[
        const SizedBox(width: 6),
        const _CoreLevelChip(),
      ],
    ];

    // A window narrower than the breakpoint reaches this size a frame before
    // the nav rail collapses, so the bar can be asked to draw while the page is
    // still short of room. The narrow form survives that: its chips wrap rather
    // than overflow.
    final oneRow = MediaQuery.sizeOf(context).width >= _oneRowMinWindowWidth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: search == null
          ? Row(children: chips)
          : oneRow
          ? Row(
              children: [
                Expanded(child: _search(theme, t)),
                const SizedBox(width: 8),
                ...chips,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _search(theme, t),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 6,
                  children: chips,
                ),
              ],
            ),
    );
  }

  /// Filled and rounded rather than underlined, so the area you can click is
  /// the area you can see. The padding is part of that: without it the field is
  /// only as tall as its text, about 18px, and most clicks land beside it.
  Widget _search(ThemeData theme, Translations t) {
    return TextField(
      controller: search,
      onChanged: onSearch,
      style: theme.textTheme.labelMedium,
      cursorHeight: 14,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintText: t.common.filter,
        hintStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.only(right: 10, top: 9, bottom: 9),
        prefixIcon: Icon(
          FluentIcons.search_20_regular,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 30),
      ),
    );
  }
}

/// A chip that opens a menu and keeps showing what was picked, so the row still
/// answers "what am I looking at" after the menu closes.
class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.options,
    required this.nameOf,
    required this.onSelected,
    this.allLabel,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) nameOf;

  /// Null for a setting rather than a filter: every value means something, so
  /// there is nothing for "All" to stand for.
  final String? allLabel;

  final ValueChanged<T?> onSelected;

  /// A PopupMenuButton reads a null result as "dismissed" and never reports it,
  /// so "All" needs a value of its own.
  static const _all = Object();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = value;

    return PopupMenuButton<Object>(
      tooltip: '',
      position: PopupMenuPosition.under,
      initialValue: current ?? _all,
      onSelected: (picked) =>
          onSelected(identical(picked, _all) ? null : picked as T),
      itemBuilder: (context) => [
        if (allLabel case final all?) PopupMenuItem(value: _all, child: Text(all)),
        for (final option in options)
          PopupMenuItem(value: option as Object, child: Text(nameOf(option))),
      ],
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 4, top: 7, bottom: 7),
        decoration: _chipShape(theme),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              current == null ? allLabel ?? '' : nameOf(current),
              style: theme.textTheme.labelSmall,
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Oldest at the top, newest at the bottom, like a terminal. Only the visible
/// rows are built, so the list can hold thousands without paying for them.
class _LogList extends ConsumerWidget {
  const _LogList({required this.logs, required this.controller});

  final List<LogRecord> logs;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      final t = ref.watch(translationsProvider).requireValue;
      return Center(
        child: Text(
          t.common.empty,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      itemCount: logs.length,
      separatorBuilder: (_, _) =>
          const Divider(indent: 16, endIndent: 16, height: 1),
      itemBuilder: (context, index) => _LogRow(record: logs[index]),
    );
  }
}

class _LogRow extends ConsumerWidget {
  const _LogRow({required this.record});

  final LogRecord record;

  /// Long press on a phone, right click on a desktop — both land here, so a
  /// single line can be shared without exporting the whole history.
  Future<void> _copy(BuildContext context, WidgetRef ref, Offset at) async {
    final t = ref.read(translationsProvider).requireValue;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;

    final picked = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        at & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              const Icon(FluentIcons.copy_20_regular, size: 18),
              const SizedBox(width: 10),
              Text(t.common.addToClipboard),
            ],
          ),
        ),
      ],
    );
    if (picked != true) return;

    await Clipboard.setData(ClipboardData(text: formatRecord(record)));
    ref
        .read(inAppNotificationControllerProvider)
        .showSuccessToast(t.common.msg.export.clipboard.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final time = record.time.toIso8601String().split('T')[1].split('.').first;

    return InkWell(
      onLongPress: () => _copy(context, ref, _center(context)),
      onSecondaryTapDown: (details) =>
          _copy(context, ref, details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  record.level.shortName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _colorFor(record.level),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.loggerName,
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(time, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 2),
            Text(messageOf(record), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Offset _center(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

Color? _colorFor(Level level) => switch (level) {
  Level.FINEST || Level.FINER => Colors.lightBlueAccent,
  Level.FINE || Level.CONFIG => Colors.grey,
  Level.INFO => Colors.lightGreen,
  Level.WARNING => Colors.orange,
  Level.SEVERE => Colors.redAccent,
  Level.SHOUT => Colors.red,
  _ => null,
};
