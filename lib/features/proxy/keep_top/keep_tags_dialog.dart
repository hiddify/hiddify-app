import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/features/proxy/widget/upload_test_dialog.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// How the picker's list is ordered.
enum _Sort { profile, ping, download, upload }

/// The status quick filters.
enum _Status { answering, paused }

/// The quick filters that narrow the list; each kind of filter counts with the others in place.
enum _Facet { status, protocol, country }

/// How many "the fastest" are, to test or to choose.
const _fastest = 10;

/// A country with fewer proxies than this is under "others" in the country filter.
const _fewCountry = 5;

/// The country filter's entry for the countries with few proxies, and the proxies with none.
const _otherCountries = '*';

/// The protocol a sing-box [type] is, as the core names it on the proxy page.
String protocolName(String type) => switch (type) {
  'shadowsocks' => 'Shadowsocks',
  'shadowsocksr' => 'ShadowsocksR',
  'vless' => 'VLESS',
  'vmess' => 'VMess',
  'trojan' => 'Trojan',
  'naive' => 'Naive',
  'wireguard' => 'WireGuard',
  'hysteria' => 'Hysteria',
  'hysteria2' => 'Hysteria2',
  'tuic' => 'TUIC',
  'anytls' => 'AnyTLS',
  'shadowtls' => 'ShadowTLS',
  'ssh' => 'SSH',
  'tor' => 'Tor',
  'socks' => 'SOCKS',
  'http' => 'HTTP',
  'warp' => 'WARP',
  'masque' => 'MASQUE',
  'psiphon' => 'Psiphon',
  'mieru' => 'Mieru',
  'awg' => 'Awg',
  'dnstt' => 'DNSTT',
  'xray' => 'xray',
  '' => '?',
  _ => type[0].toUpperCase() + type.substring(1),
};

/// The country of a proxy's [tag] by the flag in it: its two letters, or null without a flag.
String? countryOf(String tag) {
  bool regional(int rune) => rune >= 0x1F1E6 && rune <= 0x1F1FF;
  final runes = tag.runes.toList();
  for (var i = 0; i + 1 < runes.length; i++) {
    if (regional(runes[i]) && regional(runes[i + 1])) {
      return String.fromCharCodes([runes[i] - 0x1F1E6 + 0x41, runes[i + 1] - 0x1F1E6 + 0x41]);
    }
  }
  return null;
}

/// The flag of a two-letter country [code].
String flagOf(String code) => String.fromCharCodes(code.codeUnits.map((c) => c - 0x41 + 0x1F1E6));

/// Which of [profile]'s [proxies] run, chosen on a list like the proxy page's: their ping and
/// speeds, sorted and filtered by country, protocol and status, and tested one, the chosen, the
/// fastest or all at once. Proxies keep top paused can be run for the while, and go back to how
/// they were when the picker is dismissed. Pops the chosen tags in the profile's order.
class KeepTagsDialog extends HookConsumerWidget {
  const KeepTagsDialog({super.key, required this.profile, required this.proxies});

  final ProfileEntity profile;
  final List<ProfileProxy> proxies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.keepTags;
    final theme = Theme.of(context);
    final s = theme.colorScheme;

    final tags = useMemoized(() => [for (final p in proxies) p.tag], [proxies]);
    final protocols = useMemoized(() => {for (final p in proxies) p.tag: protocolName(p.type)}, [proxies]);
    final countries = useMemoized(
      () => {
        for (final p in proxies)
          if (countryOf(p.tag) case final code?) p.tag: code,
      },
      [proxies],
    );

    final selected = useState<Set<String>>({...profile.keepTags.where(tags.contains)});
    final query = useState('');
    final sort = useState(_Sort.profile);
    final countryFilter = useState(<String>{});
    // the countries with few proxies, and the proxies with none, are one entry: the list stays short
    final fewCountries = useMemoized(() {
      final totals = <String, int>{};
      for (final code in countries.values) {
        totals[code] = (totals[code] ?? 0) + 1;
      }
      return {
        for (final MapEntry(:key, :value) in totals.entries)
          if (value < _fewCountry) key,
      };
    }, [countries]);
    // the entry a proxy's country is under: its own, or the others'
    String countryEntry(String tag) => switch (countries[tag]) {
      final code? when !fewCountries.contains(code) => code,
      _ => _otherCountries,
    };
    final protocolFilter = useState(<String>{});
    // the proxies that answer first: those are the ones worth choosing
    final statusFilter = useState(<_Status>{_Status.answering});
    final woke = useState(false);
    // the chosen proxies in the list whatever the other filters; off, those they hide go to the
    // tray at the bottom
    final showChosen = useState(true);

    // what the core knows of the proxies it runs: ping, speeds
    final group = ref.watch(proxiesOverviewNotifierProvider).valueOrNull;
    final live = {
      for (final e in group?.items ?? const <OutboundInfo>[])
        if (!e.isGroup) e.tag: e,
    };
    final connected = group != null && live.isNotEmpty;

    // a paused proxy, as the core would show it: its tag without the core's mark, its protocol
    OutboundInfo info(String tag) =>
        live[tag] ??
        OutboundInfo(tag: tag, tagDisplay: tag.replaceFirst(RegExp('§.*'), '').trimRight(), type: protocols[tag]);
    bool answers(OutboundInfo e) => e.urlTestDelay > 0 && e.urlTestDelay < 65000;
    bool paused(String tag) => connected && !live.containsKey(tag);
    bool hasStatus(String tag, _Status status) => switch (status) {
      // not connected, nothing answers yet: the filter would hide every proxy
      _Status.answering => !connected || answers(info(tag)),
      _Status.paused => paused(tag),
    };

    final needle = query.value.trim().toLowerCase();
    // whether [tag] passes the search and every filter but [skip]'s, so a filter's counts say what
    // ticking it would show
    bool passes(String tag, {_Facet? skip}) {
      if (needle.isNotEmpty && !tag.toLowerCase().contains(needle)) return false;
      if (skip != _Facet.country &&
          countryFilter.value.isNotEmpty &&
          !countryFilter.value.contains(countryEntry(tag))) {
        return false;
      }
      if (skip != _Facet.protocol &&
          protocolFilter.value.isNotEmpty &&
          !protocolFilter.value.contains(protocols[tag])) {
        return false;
      }
      if (skip != _Facet.status &&
          statusFilter.value.isNotEmpty &&
          !statusFilter.value.any((status) => hasStatus(tag, status))) {
        return false;
      }
      return true;
    }

    final shown = tags.where((tag) => passes(tag) || (showChosen.value && selected.value.contains(tag))).toList();
    final shownSet = shown.toSet();
    // the profile's order breaks ties, so a sort never shuffles equal rows
    final order = {for (final (i, tag) in tags.indexed) tag: i};
    int byOrder(String a, String b) => order[a]!.compareTo(order[b]!);
    switch (sort.value) {
      case _Sort.profile:
        break;
      case _Sort.ping:
        shown.sort((a, b) {
          final (x, y) = (info(a), info(b));
          if (answers(x) != answers(y)) return answers(x) ? -1 : 1;
          final delay = answers(x) ? x.urlTestDelay.compareTo(y.urlTestDelay) : 0;
          return delay != 0 ? delay : byOrder(a, b);
        });
      // by the one speed, then the other, then ping, as on the proxy page
      case _Sort.download:
        shown.sort((a, b) {
          final speed = compareBySpeeds(info(a), info(b), uploadFirst: false);
          return speed != 0 ? speed : byOrder(a, b);
        });
      case _Sort.upload:
        shown.sort((a, b) {
          final speed = compareBySpeeds(info(a), info(b), uploadFirst: true);
          return speed != 0 ? speed : byOrder(a, b);
        });
    }

    // the counts each filter would show, with the other filters in place
    final statusCounts = {
      for (final status in _Status.values)
        status: tags.where((tag) => passes(tag, skip: _Facet.status) && hasStatus(tag, status)).length,
    };
    final protocolCounts = _counts([
      for (final tag in tags)
        if (passes(tag, skip: _Facet.protocol)) protocols[tag]!,
    ], keep: protocolFilter.value);
    final countryCounts = _counts([
      for (final tag in tags)
        if (passes(tag, skip: _Facet.country)) countryEntry(tag),
    ], keep: countryFilter.value);

    void toggle(String tag) =>
        selected.value = selected.value.contains(tag) ? ({...selected.value}..remove(tag)) : {...selected.value, tag};
    List<String> fastestOf(Iterable<String> among, [int count = _fastest]) =>
        fastestProxies([for (final tag in among) info(tag)], count);

    final n = selected.value.length;
    // the tests run on the proxies that run: those shown, or the chosen ones
    final chosenLive = tags.where((tag) => selected.value.contains(tag) && live.containsKey(tag)).toList();
    final shownLive = shown.where(live.containsKey).toList();

    /// Runs [run] on [targets]: every proxy that runs, together in the core; else one by one.
    Future<void> runOn(List<String> targets, Future<void> Function(String tag) run) async {
      final groupTag = group?.tag;
      if (groupTag == null || targets.isEmpty) return;
      if (targets.length == live.length) return run(groupTag);
      for (final tag in targets) {
        await run(tag);
      }
    }

    // a ping costs next to nothing: it runs at once on the proxies shown
    Future<void> ping() => runOn(shownLive, ref.read(proxiesOverviewNotifierProvider.notifier).urlTest);

    // a speed test sends megabytes through each: the speed test dialog says how much first
    Future<void> speedTest() async {
      final target = await ref
          .read(dialogNotifierProvider.notifier)
          .showPickerSpeedTest(shown: shownLive.length, chosen: chosenLive.length);
      if (target == null) return;
      final base = target == SpeedTestTarget.chosen ? chosenLive : shownLive;
      final limit = ref.read(ConfigOptions.uploadTestLimit);
      await runOn(
        limit <= 0 || base.length <= limit ? base : fastestOf(base, limit),
        ref.read(proxiesOverviewNotifierProvider.notifier).speedTest,
      );
    }

    // the rows show both speeds: a sort needs not change what the speed test measures
    void setSort(_Sort value) => sort.value = value;

    Future<void> wake() async {
      woke.value = true;
      await ref.read(keepTopNotifierProvider.notifier).wakeAll(profile);
    }

    final pausedCount = connected ? tags.where(paused).length : 0;
    final emoji = PlatformUtils.isWindows ? FontFamily.emoji : null;
    // "Others: CN JP TR …", the most common of them first
    String otherCountriesLabel(String others) {
      final codes = _counts([
        for (final code in countries.values)
          if (fewCountries.contains(code)) code,
      ]).map((e) => e.$1).toList();
      if (codes.isEmpty) return others;
      final shown = codes.take(6).join(' ');
      return '$others: $shown${codes.length > 6 ? ' …' : ''}';
    }

    return PopScope(
      // dismissed: the proxies run as they did before the picker woke them
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == null && woke.value) {
          unawaited(ref.read(keepTopNotifierProvider.notifier).restore(profile));
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 920),
          child: Column(
            children: [
              // the title, and how many are chosen
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [s.primary.withValues(alpha: .28), s.primary.withValues(alpha: .12)],
                        ),
                      ),
                      child: Icon(Icons.checklist_rounded, color: s.primary, size: 22),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.title, style: theme.textTheme.titleLarge),
                          Text(text.hint, style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    KeepTopCountPill(running: n, total: tags.length),
                  ],
                ),
              ),
              // search, sort, and the test panel's switch
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => query.value = value,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          hintText: text.search,
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    MenuAnchor(
                      builder: (context, controller, _) => IconButton.filledTonal(
                        tooltip: text.sort,
                        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                        icon: const Icon(Icons.sort_rounded),
                      ),
                      menuChildren: [
                        for (final (value, label, icon) in [
                          (_Sort.profile, text.sortProfile, Icons.format_list_numbered_rounded),
                          (_Sort.ping, text.sortPing, Icons.signal_cellular_alt_rounded),
                          (_Sort.download, text.sortDownload, Icons.arrow_downward_rounded),
                          (_Sort.upload, text.sortUpload, Icons.arrow_upward_rounded),
                        ])
                          MenuItemButton(
                            leadingIcon: Icon(icon, size: 20),
                            trailingIcon: sort.value == value
                                ? Icon(Icons.check_rounded, size: 18, color: s.primary)
                                : const SizedBox(width: 18),
                            onPressed: () => setSort(value),
                            child: Text(label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // the quick filters, in one row
              const Gap(10),
              _FilterRow(
                children: [
                  _Chip(
                    label: Text('${text.statusChosen} · ${selected.value.length}'),
                    icon: Icons.check_circle_outline_rounded,
                    selected: showChosen.value,
                    onSelected: () => showChosen.value = !showChosen.value,
                  ),
                  for (final (status, label, icon) in [
                    if (connected) (_Status.answering, text.statusAnswering, Icons.signal_cellular_alt_rounded),
                    if (pausedCount > 0) (_Status.paused, text.statusPaused, Icons.pause_circle_outline_rounded),
                  ])
                    _Chip(
                      label: Text('$label · ${statusCounts[status]}'),
                      icon: icon,
                      selected: statusFilter.value.contains(status),
                      onSelected: () => statusFilter.value = _flip(statusFilter.value, status),
                    ),
                  if (protocolCounts.isNotEmpty)
                    _FacetButton(
                      label: text.protocol,
                      any: text.anyProtocol,
                      icon: Icons.lan_outlined,
                      options: [for (final (protocol, count) in protocolCounts) (protocol, protocol, count)],
                      selected: protocolFilter.value,
                      onChanged: (value) => protocolFilter.value = value,
                    ),
                  if (countryCounts.isNotEmpty)
                    _FacetButton(
                      label: text.country,
                      any: text.anyCountry,
                      icon: Icons.public_rounded,
                      options: [
                        for (final (code, count) in countryCounts)
                          if (code != _otherCountries) (code, '${flagOf(code)}  $code', count),
                        // the others last, named by their codes
                        for (final (code, count) in countryCounts)
                          if (code == _otherCountries) (code, otherCountriesLabel(text.otherCountries), count),
                      ],
                      selected: countryFilter.value,
                      onChanged: (value) => countryFilter.value = value,
                      style: TextStyle(fontFamily: emoji),
                    ),
                ],
              ),
              // choose many at once
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: shown.isEmpty ? null : () => selected.value = {...selected.value, ...shown},
                      child: Text(text.all),
                    ),
                    if (connected)
                      TextButton(
                        onPressed: () => selected.value = {...fastestOf(shown)},
                        child: Text(text.selectFastest(n: _fastest)),
                      ),
                    TextButton(onPressed: n == 0 ? null : () => selected.value = {}, child: Text(text.none)),
                    const Spacer(),
                    Text(
                      text.shown(n: shown.length),
                      style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // why some rows have no ping
              if (!connected)
                const _ConnectCard()
              else if (pausedCount > 0 && !woke.value)
                _Banner(
                  icon: Icons.pause_circle_outline_rounded,
                  text: text.paused(n: pausedCount),
                  action: TextButton.icon(
                    onPressed: wake,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(text.wake),
                  ),
                ),
              const Gap(6),
              const Divider(height: 1),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: shown.isEmpty
                          ? Center(
                              child: Text(
                                text.noMatch,
                                style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth < 600 ? 1 : 2;
                                return GridView.builder(
                                  // room under the last rows for the test buttons
                                  padding: EdgeInsets.only(top: 6, bottom: connected ? 140 : 6),
                                  itemCount: shown.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent: 72,
                                  ),
                                  itemBuilder: (context, index) {
                                    final tag = shown[index];
                                    return _PickRow(
                                      key: ValueKey(tag),
                                      proxy: info(tag),
                                      checked: selected.value.contains(tag),
                                      paused: paused(tag),
                                      live: live.containsKey(tag),
                                      onTap: () => toggle(tag),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    // the tests, as on the proxy page: the speed test over the ping
                    if (connected)
                      PositionedDirectional(
                        end: 16,
                        bottom: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'keep-tags-speed-test',
                              onPressed: shownLive.isEmpty && chosenLive.isEmpty ? null : speedTest,
                              tooltip: t.pages.proxies.speedTest.title,
                              child: const Icon(Icons.speed_rounded, size: 26),
                            ),
                            const Gap(12),
                            FloatingActionButton(
                              heroTag: 'keep-tags-ping',
                              onPressed: shownLive.isEmpty ? null : ping,
                              tooltip: t.pages.proxies.testDelay,
                              child: const Icon(FluentIcons.flash_24_filled),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // at the bottom, by the run button: the chosen proxies the filters hide; with the ones lit in
              // the list, all always in sight
              _ChosenTray(
                count: n,
                tags: [
                  for (final tag in tags)
                    if (selected.value.contains(tag) && !shownSet.contains(tag)) tag,
                ],
                info: info,
                paused: paused,
                onRemove: toggle,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.cancel)),
                    const Gap(8),
                    FilledButton.icon(
                      onPressed: n == 0
                          ? null
                          : () => Navigator.of(context).pop(tags.where(selected.value.contains).toList()),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(text.run(n: n)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How many of each value, the most first, then by name; the [keep] ones stay at 0.
  static List<(String, int)> _counts(Iterable<String> values, {Set<String> keep = const {}}) {
    final counts = <String, int>{for (final value in keep) value: 0};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return [for (final e in counts.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
  }

  static Set<T> _flip<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

/// A filter of many values, as one chip: "Protocol", or what is ticked, opening the values with
/// their counts to tick.
class _FacetButton extends StatelessWidget {
  const _FacetButton({
    required this.label,
    required this.any,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.style,
  });

  final String label;

  /// The entry that clears the filter.
  final String any;
  final IconData icon;

  /// value, its label, its count
  final List<(String, String, int)> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final names = {for (final (value, name, _) in options) value: name};
    final title = switch (selected.length) {
      0 => label,
      1 => names[selected.first] ?? selected.first,
      _ => '${names[selected.first] ?? selected.first} +${selected.length - 1}',
    };
    return MenuAnchor(
      builder: (context, controller, _) => FilterChip(
        avatar: selected.isEmpty ? Icon(icon, size: 16) : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: style),
            const Gap(2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
        selected: selected.isNotEmpty,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        onSelected: (_) => controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(Icons.clear_all_rounded, size: 20, color: selected.isEmpty ? s.primary : null),
          onPressed: () => onChanged({}),
          child: Text(any),
        ),
        const Divider(height: 1),
        for (final (value, name, count) in options)
          CheckboxMenuButton(
            value: selected.contains(value),
            closeOnActivate: false,
            onChanged: (checked) => onChanged(checked ?? false ? {...selected, value} : ({...selected}..remove(value))),
            trailingIcon: Text(
              '$count',
              style: TextStyle(color: s.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            child: Text(name, style: style),
          ),
      ],
    );
  }
}

/// A proxy of the picker's list: the proxy page's row, lit and checked when chosen, dim while
/// paused; a tap chooses it, or no more.
class _PickRow extends StatelessWidget {
  const _PickRow({
    super.key,
    required this.proxy,
    required this.checked,
    required this.paused,
    required this.live,
    required this.onTap,
  });

  final OutboundInfo proxy;
  final bool checked;
  final bool paused;

  /// The core runs it: its ping is or will be known.
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: paused && !checked ? .55 : 1,
          // its own surface: the lit row's color stays in the list as it scrolls, not on the dialog
          child: Material(
            type: MaterialType.transparency,
            // a tap anywhere chooses it; the tests are the buttons', never a stray tap's
            // not running (paused, or not connected): no ping is coming, so none shows
            child: ProxyTile(proxy, selected: checked, onTap: onTap, testable: false, showPing: live),
          ),
        ),
        // the check, on the flag's corner
        PositionedDirectional(
          start: 8,
          top: 8,
          child: IgnorePointer(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: checked ? 1 : 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: s.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: s.surface, width: 2),
                ),
                child: Icon(Icons.check_rounded, size: 11, color: s.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How many proxies are chosen ([count]), and over the list the chosen ones its filters hide
/// ([tags]), each with its ping and a cross that unchooses it; the others are lit in the list.
class _ChosenTray extends ConsumerWidget {
  const _ChosenTray({
    required this.count,
    required this.tags,
    required this.info,
    required this.paused,
    required this.onRemove,
  });

  final int count;
  final List<String> tags;
  final OutboundInfo Function(String tag) info;
  final bool Function(String tag) paused;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.keepTags;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    Color pingColor(int delay) => switch (delay) {
      < 800 => dark ? Colors.lightGreen : Colors.green,
      < 1500 => dark ? Colors.orange : Colors.deepOrangeAccent,
      _ => dark ? Colors.redAccent : Colors.red,
    };
    final emoji = PlatformUtils.isWindows ? FontFamily.emoji : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(s.primary.withValues(alpha: count == 0 ? .04 : .10), s.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.primary.withValues(alpha: count == 0 ? .08 : .22)),
      ),
      child: Row(
        children: [
          Icon(
            count == 0 ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
            size: 18,
            color: s.primary,
          ),
          const Gap(8),
          Text(
            '${text.statusChosen} · $count',
            style: theme.textTheme.labelLarge?.copyWith(color: s.primary, fontWeight: FontWeight.w600),
          ),
          const Gap(10),
          Expanded(
            child: tags.isEmpty
                ? Text(
                    count == 0 ? text.chosenHint : text.allShown,
                    style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  )
                : SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      // the first: what the chips are
                      itemCount: tags.length + 1,
                      separatorBuilder: (_, _) => const Gap(6),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Text(
                              text.notShown,
                              style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                            ),
                          );
                        }
                        final tag = tags[index - 1];
                        final proxy = info(tag);
                        final delay = proxy.urlTestDelay;
                        final answers = delay > 0 && delay < 65000;
                        return Opacity(
                          opacity: paused(tag) ? .6 : 1,
                          child: InputChip(
                            key: ValueKey(tag),
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      proxy.tagDisplay.isEmpty ? tag : proxy.tagDisplay,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: emoji),
                                    ),
                                  ),
                                  if (answers) ...[
                                    const Gap(6),
                                    Text(
                                      '$delay',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: pingColor(delay),
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            onDeleted: () => onRemove(tag),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const StadiumBorder(),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One row of quick filters, scrolled sideways when they do not fit.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final (i, child) in children.indexed) ...[if (i > 0) const Gap(6), child],
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onSelected, this.icon});

  final Widget label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: label,
    avatar: icon == null || selected ? null : Icon(icon, size: 16),
    selected: selected,
    showCheckmark: true,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: const StadiumBorder(),
    onSelected: (_) => onSelected(),
  );
}

/// Not connected: no ping, no speeds, no tests. A card big enough to say so, with the button that
/// connects; a spinner while it connects.
class _ConnectCard extends ConsumerWidget {
  const _ConnectCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.keepTags;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final status = ref.watch(connectionNotifierProvider).valueOrNull;
    // connected, the proxies are on their way
    final connecting = status != null && status is! Disconnected;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color.alphaBlend(s.primary.withValues(alpha: .14), s.surfaceContainerHigh), s.surfaceContainerHigh],
        ),
        border: Border.all(color: s.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [s.primary.withValues(alpha: .28), s.primary.withValues(alpha: .12)]),
            ),
            child: Icon(Icons.cloud_off_rounded, color: s.primary, size: 26),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.offlineTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Gap(2),
                Text(text.offline, style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              ],
            ),
          ),
          const Gap(12),
          if (connecting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const Gap(10),
                Text(t.connection.connecting, style: theme.textTheme.labelLarge?.copyWith(color: s.primary)),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
              label: Text(t.connection.connect),
            ),
        ],
      ),
    );
  }
}

/// A note over the list, on a tinted card, with an [action] at its end.
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(s.primary.withValues(alpha: .08), s.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: s.primary),
          const Gap(10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ?action,
        ],
      ),
    );
  }
}
