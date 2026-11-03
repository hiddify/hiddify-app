import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The WARP settings of one chain hop: its tunnel, licence and peer first, then the scanner, the
/// MASQUE and the AmneziaWG tunnels folded away. Only what the hop offers and its tunnel and peer
/// use is shown, and a value left empty is the core's default, shown as auto. Extra security offers
/// the tunnel, the licence and the MTU only.
class WarpHopOptions extends ConsumerWidget {
  const WarpHopOptions(this.hop, {super.key});

  final WarpHopPreferences hop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final warp = t.pages.settings.chain.warp;
    final tunnel = ref.watch(hop.tunnel);
    final sources = WarpEndpointSource.of(detour: hop.detour);
    final endpointPreference = hop.endpoint;
    final stored = endpointPreference == null ? null : ref.watch(endpointPreference);
    final endpoint = sources.contains(stored) ? stored! : sources.first;
    final cleanIp = hop.cleanIp;
    final cleanPort = hop.cleanPort;
    // the custom address is the WireGuard peer: the MASQUE tunnel reads its own
    final custom =
        endpoint == WarpEndpointSource.custom && tunnel.usesWireGuardPeer && cleanIp != null && cleanPort != null;
    final scanner = hop.scanner;
    final masque = hop.masque;
    final awg = hop.awg;
    return Column(
      children: [
        ChoicePreferenceWidget(
          selected: tunnel,
          preferences: ref.watch(hop.tunnel.notifier),
          choices: WarpTunnel.values,
          title: warp.tunnel,
          icon: Icons.cable_rounded,
          presentChoice: (value) => value.present(t),
        ),
        ValuePreferenceWidget(
          value: ref.watch(hop.licenseKey),
          preferences: ref.watch(hop.licenseKey.notifier),
          title: warp.licenseKey,
          icon: Icons.key_rounded,
          presentValue: (value) => value.isEmpty ? t.common.notSet : value,
        ),
        if (endpointPreference != null)
          ChoicePreferenceWidget<WarpEndpointSource>(
            selected: endpoint,
            preferences: ref.watch(endpointPreference.notifier),
            choices: sources,
            title: warp.endpoint,
            icon: Icons.travel_explore_rounded,
            presentChoice: (value) => value.present(t),
          ),
        if (custom) ...[
          ValuePreferenceWidget(
            value: ref.watch(cleanIp),
            preferences: ref.watch(cleanIp.notifier),
            title: warp.customServer,
            icon: Icons.dns_rounded,
            presentValue: (value) => value.isEmpty ? t.common.notSet : value,
          ),
          ValuePreferenceWidget(
            value: ref.watch(cleanPort),
            preferences: ref.watch(cleanPort.notifier),
            title: warp.port,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            validateInput: isPort,
            digitsOnly: true,
            presentValue: (value) => value == 0 ? t.common.auto : '$value',
          ),
        ],
        ValuePreferenceWidget(
          value: ref.watch(hop.mtu),
          preferences: ref.watch(hop.mtu.notifier),
          title: warp.mtu,
          icon: Icons.straighten_rounded,
          inputToValue: int.tryParse,
          digitsOnly: true,
          presentValue: (value) => value == 0 ? t.common.auto : '$value',
        ),
        if (scanner != null && endpoint == WarpEndpointSource.scan) _ScannerSection(scanner),
        if (tunnel.usesWireGuardPeer && hop.noise != null) _NoiseSection(hop),
        if (masque != null && (tunnel == WarpTunnel.masque || tunnel == WarpTunnel.auto)) _MasqueSection(masque),
        if (awg != null && (tunnel == WarpTunnel.amneziaWg || tunnel == WarpTunnel.auto)) _AwgSection(awg),
      ],
    );
  }
}

typedef _Preference<T> = StateNotifierProvider<PreferencesNotifier<T, String>, T>;

/// The noise the WireGuard peer sends before its handshake (the WireGuard and AmneziaWG tunnels):
/// left empty, the scanner finds the one that gets through.
class _NoiseSection extends ConsumerWidget {
  const _NoiseSection(this.hop);

  final WarpHopPreferences hop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final warp = t.pages.settings.chain.warp;
    final ranges = [hop.noise!, hop.noiseSize!, hop.noiseDelay!];
    final noiseMode = hop.noiseMode!;
    Widget range(_Preference<OptionalRange> preference, String title, IconData icon) => ValuePreferenceWidget(
      value: ref.watch(preference),
      preferences: ref.watch(preference.notifier),
      title: title,
      icon: icon,
      inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
      presentValue: (value) => _presentRange(t, value),
      formatInputValue: (value) => value.format(),
    );
    return _Section(
      title: warp.noise.title,
      icon: Icons.graphic_eq_rounded,
      changed: ref.watch(noiseMode).isNotEmpty || ranges.any((range) => ref.watch(range).format().isNotEmpty),
      onReset: () {
        for (final range in ranges) {
          ref.read(range.notifier).reset();
        }
        ref.read(noiseMode.notifier).reset();
      },
      children: [
        range(hop.noise!, warp.noise.count, Icons.web_stories_rounded),
        ChoicePreferenceWidget<String>(
          selected: ref.watch(noiseMode),
          preferences: ref.watch(noiseMode.notifier),
          // the core's named noise presets; a mode typed in before stays choosable
          choices: {..._noiseModes, ref.watch(noiseMode)}.toList(),
          title: warp.noise.mode,
          icon: Icons.mode_standby_rounded,
          presentChoice: (mode) => _presentNoiseMode(t, mode),
        ),
        range(hop.noiseSize!, warp.noise.size, Icons.settings_ethernet_rounded),
        range(hop.noiseDelay!, warp.noise.delay, Icons.schedule_rounded),
      ],
    );
  }
}

/// The scanner that finds the unblocker's peer, when it scans.
class _ScannerSection extends ConsumerWidget {
  const _ScannerSection(this.preference);

  final _Preference<SingboxWarpScannerOption> preference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.chain.warp.scanner;
    final scanner = ref.watch(preference);
    void save(SingboxWarpScannerOption next) => ref.read(preference.notifier).update(next);
    return _Section(
      title: text.title,
      icon: Icons.radar_rounded,
      changed: scanner != const SingboxWarpScannerOption(),
      onReset: () => ref.read(preference.notifier).reset(),
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.graphic_eq_rounded),
          title: Text(text.searchNoise),
          value: scanner.searchNoise,
          onChanged: (value) => save(scanner.copyWith(searchNoise: value)),
        ),
        _NumberTile(text.maxRtt, Icons.speed_rounded, scanner.maxRtt, (v) => save(scanner.copyWith(maxRtt: v))),
        _NumberTile(text.timeout, Icons.timer_outlined, scanner.timeout, (v) => save(scanner.copyWith(timeout: v))),
        _NumberTile(
          text.count,
          Icons.format_list_numbered_rounded,
          scanner.count,
          (v) => save(scanner.copyWith(count: v)),
        ),
        _NumberTile(
          text.concurrency,
          Icons.call_split_rounded,
          scanner.concurrency,
          (v) => save(scanner.copyWith(concurrency: v)),
        ),
        _TextTile(
          text.ports,
          Icons.device_hub_rounded,
          scanner.ports.join(', '),
          (v) => save(
            scanner.copyWith(ports: _list(v).map(int.tryParse).whereType<int>().where((p) => isPort('$p')).toList()),
          ),
        ),
        _TextTile(
          text.cidrs,
          Icons.lan_outlined,
          scanner.cidrs.join(', '),
          (v) => save(scanner.copyWith(cidrs: _list(v))),
        ),
      ],
    );
  }
}

/// The MASQUE tunnel, run by the masque and auto tunnels.
class _MasqueSection extends ConsumerWidget {
  const _MasqueSection(this.preference);

  final _Preference<SingboxWarpMasqueOption> preference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.chain.warp.masque;
    final masque = ref.watch(preference);
    void save(SingboxWarpMasqueOption next) => ref.read(preference.notifier).update(next);
    Widget toggle(String title, IconData icon, bool value, SingboxWarpMasqueOption Function(bool) apply) =>
        SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title),
          value: value,
          onChanged: (v) => save(apply(v)),
        );
    return _Section(
      title: text.title,
      icon: Icons.http_rounded,
      changed: masque != const SingboxWarpMasqueOption(),
      onReset: () => ref.read(preference.notifier).reset(),
      children: [
        _ChoiceTile(
          title: text.vhttp,
          icon: Icons.http_rounded,
          value: masque.vhttp.isEmpty ? 'auto' : masque.vhttp,
          choices: {'auto': t.common.auto, 'h3': 'HTTP/3', 'h2': 'HTTP/2'},
          onSaved: (value) => save(masque.copyWith(vhttp: value)),
        ),
        _TextTile(
          text.serverName,
          Icons.badge_outlined,
          masque.serverName,
          (v) => save(masque.copyWith(serverName: v)),
        ),
        toggle(text.useIpv6, Icons.looks_6_outlined, masque.useIpv6, (v) => masque.copyWith(useIpv6: v)),
        _NumberTile(
          text.udpTimeout,
          Icons.timer_off_outlined,
          masque.udpTimeout,
          (v) => save(masque.copyWith(udpTimeout: v)),
        ),
        _NumberTile(
          text.keepalive,
          Icons.favorite_outline_rounded,
          masque.udpKeepalive,
          (v) => save(masque.copyWith(udpKeepalive: v)),
        ),
        _NumberTile(
          text.packetSize,
          Icons.straighten_rounded,
          masque.udpInitialPacketSize,
          (v) => save(masque.copyWith(udpInitialPacketSize: v)),
        ),
        _NumberTile(
          text.reconnectDelay,
          Icons.replay_rounded,
          masque.reconnectDelay,
          (v) => save(masque.copyWith(reconnectDelay: v)),
        ),
        toggle(text.tlsInsecure, Icons.lock_open_rounded, masque.tlsInsecure, (v) => masque.copyWith(tlsInsecure: v)),
        toggle(text.fragment, Icons.call_split_rounded, masque.tlsFragment, (v) => masque.copyWith(tlsFragment: v)),
        if (masque.tlsFragment)
          _NumberTile(
            text.fragmentDelay,
            Icons.timer_outlined,
            masque.tlsFragmentFallbackDelay,
            (v) => save(masque.copyWith(tlsFragmentFallbackDelay: v)),
          ),
        toggle(
          text.recordFragment,
          Icons.receipt_long_outlined,
          masque.tlsRecordFragment,
          (v) => masque.copyWith(tlsRecordFragment: v),
        ),
        toggle(text.ech, Icons.enhanced_encryption_rounded, masque.echEnabled, (v) => masque.copyWith(echEnabled: v)),
        if (masque.echEnabled) ...[
          _TextTile(
            text.echConfig,
            Icons.description_outlined,
            masque.echConfig,
            (v) => save(masque.copyWith(echConfig: v)),
          ),
          _TextTile(
            text.echQueryServerName,
            Icons.search_rounded,
            masque.echQueryServerName,
            (v) => save(masque.copyWith(echQueryServerName: v)),
          ),
        ],
      ],
    );
  }
}

/// The AmneziaWG tunnel, run by the awg and auto tunnels; all empty keeps the core's preset.
class _AwgSection extends ConsumerWidget {
  const _AwgSection(this.preference);

  final _Preference<SingboxWarpAwgOption> preference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.chain.warp.awg;
    final awg = ref.watch(preference);
    void save(SingboxWarpAwgOption next) => ref.read(preference.notifier).update(next);
    Widget number(String title, int value, SingboxWarpAwgOption Function(int) apply) =>
        _NumberTile(title, Icons.tune_rounded, value, (v) => save(apply(v)));
    Widget text_(String title, String value, SingboxWarpAwgOption Function(String) apply) =>
        _TextTile(title, Icons.tag_rounded, value, (v) => save(apply(v)));
    return _Section(
      title: text.title,
      icon: Icons.blur_on_rounded,
      changed: awg != const SingboxWarpAwgOption(),
      onReset: () => ref.read(preference.notifier).reset(),
      children: [
        number(text.jc, awg.jc, (v) => awg.copyWith(jc: v)),
        number(text.jmin, awg.jmin, (v) => awg.copyWith(jmin: v)),
        number(text.jmax, awg.jmax, (v) => awg.copyWith(jmax: v)),
        number('S1', awg.s1, (v) => awg.copyWith(s1: v)),
        number('S2', awg.s2, (v) => awg.copyWith(s2: v)),
        number('S3', awg.s3, (v) => awg.copyWith(s3: v)),
        number('S4', awg.s4, (v) => awg.copyWith(s4: v)),
        text_('H1', awg.h1, (v) => awg.copyWith(h1: v)),
        text_('H2', awg.h2, (v) => awg.copyWith(h2: v)),
        text_('H3', awg.h3, (v) => awg.copyWith(h3: v)),
        text_('H4', awg.h4, (v) => awg.copyWith(h4: v)),
        text_('I1', awg.i1, (v) => awg.copyWith(i1: v)),
        text_('I2', awg.i2, (v) => awg.copyWith(i2: v)),
        text_('I3', awg.i3, (v) => awg.copyWith(i3: v)),
        text_('I4', awg.i4, (v) => awg.copyWith(i4: v)),
        text_('I5', awg.i5, (v) => awg.copyWith(i5: v)),
      ],
    );
  }
}

/// A folded group of advanced settings: "Auto" until something in it changes, then a reset.
class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.changed,
    required this.onReset,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool changed;
  final VoidCallback onReset;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(changed ? t.pages.settings.chain.warp.customized : t.common.auto),
      shape: const Border(),
      collapsedShape: const Border(),
      trailing: changed
          ? IconButton(tooltip: t.common.reset, icon: const Icon(Icons.restart_alt_rounded), onPressed: onReset)
          : null,
      childrenPadding: const EdgeInsetsDirectional.only(start: 16),
      children: children,
    );
  }
}

/// One of a WARP block's [choices] (value → its name).
class _ChoiceTile extends ConsumerWidget {
  const _ChoiceTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.choices,
    required this.onSaved,
  });

  final String title;
  final IconData icon;
  final String value;
  final Map<String, String> choices;
  final ValueChanged<String> onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(choices[value] ?? value),
      onTap: () async {
        final selected = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingRadio<String>(
              title: title,
              values: choices.keys.toList(),
              value: value,
              defaultValue: choices.keys.first,
              t: choices,
            );
        if (selected != null) onSaved(selected);
      },
    );
  }
}

/// A number of a WARP block; 0 is the core's default, shown as auto.
class _NumberTile extends ConsumerWidget {
  const _NumberTile(this.title, this.icon, this.value, this.onSaved);

  final String title;
  final IconData icon;
  final int value;
  final ValueChanged<int> onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value == 0 ? t.common.auto : '$value'),
      onTap: () async {
        final input = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingInput<int>(
              title: title,
              initialValue: value,
              mapTo: (text) => text.trim().isEmpty ? 0 : int.tryParse(text.trim()),
              valueFormatter: (value) => value == 0 ? '' : '$value',
              digitsOnly: true,
              onReset: () => onSaved(0),
            );
        if (input != null) onSaved(input);
      },
    );
  }
}

/// A text of a WARP block; empty is the core's default, shown as auto.
class _TextTile extends ConsumerWidget {
  const _TextTile(this.title, this.icon, this.value, this.onSaved);

  final String title;
  final IconData icon;
  final String value;
  final ValueChanged<String> onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? t.common.auto : value, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () async {
        final input = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingInput<String>(
              title: title,
              initialValue: value,
              mapTo: (text) => text.trim(),
              onReset: () => onSaved(''),
            );
        if (input != null) onSaved(input);
      },
    );
  }
}

/// The items of a comma separated list.
List<String> _list(String input) => input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// A noise range left empty is the scanner's to find.
String _presentRange(Translations t, OptionalRange value) => value.format().isEmpty ? t.common.auto : value.format();

/// The noise modes the core knows by name (hiddify.NoisePresets), its default packets (m4), and
/// none (''): with no noise set, the scanner finds the one that gets through.
const _noiseModes = ['', 'm4', 'random', 'quic', 'quic-mimic', 'dns', 'dns-cloudflare', 'sip', 'stun'];

String _presentNoiseMode(Translations t, String mode) {
  final m = t.pages.settings.chain.warp.noise.modes;
  return switch (mode) {
    '' => t.common.auto,
    'm4' => m.standard,
    'random' => m.random,
    'quic' => m.quic,
    'quic-mimic' => m.quicMimic,
    'dns' => m.dns,
    'dns-cloudflare' => m.dnsCloudflare,
    'sip' => m.sip,
    'stun' => m.stun,
    _ => mode,
  };
}
