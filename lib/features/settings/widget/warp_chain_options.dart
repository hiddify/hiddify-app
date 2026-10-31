import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The WARP settings of one chain hop.
///
/// The mode is not a WARP setting — it is the hop's mode, chosen by the page — so it comes in
/// from outside and decides which sections are shown. Both chain levels build this widget with
/// their own [WarpChainPreferences], so the two never drift apart.
class WarpChainOptions extends ConsumerWidget {
  const WarpChainOptions({super.key, required this.mode, required this.preferences});

  final ChainMode mode;
  final WarpChainPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final warp = t.pages.settings.chain.warp;
    final endpoint = ref.watch(preferences.endpoint);
    return Column(
      children: [
        ValuePreferenceWidget(
          value: ref.watch(preferences.licenseKey),
          preferences: ref.watch(preferences.licenseKey.notifier),
          title: warp.licenseKey,
          icon: Icons.key_rounded,
          presentValue: (value) => value.isEmpty ? t.common.notSet : value,
        ),
        ChoicePreferenceWidget<WarpEndpointSource>(
          selected: endpoint,
          preferences: ref.watch(preferences.endpoint.notifier),
          choices: WarpEndpointSource.selectable,
          title: warp.endpoint,
          icon: Icons.travel_explore_rounded,
          presentChoice: (value) => switch (value) {
            WarpEndpointSource.profile => warp.endpointSources.profile,
            WarpEndpointSource.scan => warp.endpointSources.scan,
            WarpEndpointSource.custom => warp.endpointSources.custom,
          },
        ),
        // A pinned address is meaningless for auto: the WireGuard and MASQUE peers live in
        // different ranges, so one address cannot serve both legs.
        if (endpoint == WarpEndpointSource.custom && mode != ChainMode.warpAuto) ...[
          ValuePreferenceWidget(
            value: ref.watch(preferences.cleanIp),
            preferences: ref.watch(preferences.cleanIp.notifier),
            title: warp.customServer,
            icon: Icons.dns_rounded,
            presentValue: (value) => value.isEmpty ? t.common.notSet : value,
          ),
          ValuePreferenceWidget(
            value: ref.watch(preferences.cleanPort),
            preferences: ref.watch(preferences.cleanPort.notifier),
            title: warp.port,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            validateInput: isPort,
            digitsOnly: true,
          ),
        ],
        ValuePreferenceWidget(
          value: ref.watch(preferences.mtu),
          preferences: ref.watch(preferences.mtu.notifier),
          title: warp.mtu,
          icon: Icons.straighten_rounded,
          inputToValue: int.tryParse,
          presentValue: (value) => value == 0 ? '' : value.toString(),
        ),
        if (endpoint == WarpEndpointSource.scan) ..._scanner(ref, t),
        if (mode == ChainMode.warpMasque || mode == ChainMode.warpAuto) ..._masque(ref, t),
        if (mode == ChainMode.warpAwg || mode == ChainMode.warpAuto) ..._awg(ref, t),
        if (mode != ChainMode.warpMasque && preferences.noise != null) ..._noise(ref, t),
      ],
    );
  }

  List<Widget> _scanner(WidgetRef ref, Translations t) {
    final warp = t.pages.settings.chain.warp;
    final scanner = ref.watch(preferences.scanner);
    void save(SingboxWarpScannerOption next) => ref.read(preferences.scanner.notifier).update(next);
    return [
      _WarpSwitch(
        title: warp.scanner.searchNoise,
        icon: Icons.graphic_eq_rounded,
        value: scanner.searchNoise,
        onChanged: (value) => save(scanner.copyWith(searchNoise: value)),
      ),
      _WarpField(
        title: warp.scanner.maxRtt,
        icon: Icons.speed_rounded,
        value: scanner.maxRtt == 0 ? '' : scanner.maxRtt.toString(),
        hint: '1000',
        digitsOnly: true,
        onSaved: (value) => save(scanner.copyWith(maxRtt: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.scanner.count,
        icon: Icons.travel_explore_rounded,
        value: scanner.count == 0 ? '' : scanner.count.toString(),
        hint: '64',
        digitsOnly: true,
        onSaved: (value) => save(scanner.copyWith(count: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.scanner.concurrency,
        icon: Icons.call_split_rounded,
        value: scanner.concurrency == 0 ? '' : scanner.concurrency.toString(),
        hint: '8',
        digitsOnly: true,
        onSaved: (value) => save(scanner.copyWith(concurrency: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.scanner.timeout,
        icon: Icons.timer_outlined,
        value: scanner.timeout == 0 ? '' : scanner.timeout.toString(),
        hint: '2000',
        digitsOnly: true,
        onSaved: (value) => save(scanner.copyWith(timeout: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.scanner.ports,
        icon: Icons.device_hub_rounded,
        value: scanner.ports.join(','),
        hint: '443,500,1701',
        onSaved: (value) => save(
          scanner.copyWith(ports: value.split(',').map((port) => int.tryParse(port.trim())).whereType<int>().toList()),
        ),
      ),
      _WarpField(
        title: warp.scanner.cidrs,
        icon: Icons.lan_outlined,
        value: scanner.cidrs.join(','),
        hint: '162.159.192.0/24',
        onSaved: (value) => save(
          scanner.copyWith(cidrs: value.split(',').map((cidr) => cidr.trim()).where((cidr) => cidr.isNotEmpty).toList()),
        ),
      ),
    ];
  }

  List<Widget> _masque(WidgetRef ref, Translations t) {
    final warp = t.pages.settings.chain.warp;
    final masque = ref.watch(preferences.masque);
    void save(SingboxWarpMasqueOption next) => ref.read(preferences.masque.notifier).update(next);
    return [
      _WarpChoice(
        title: warp.masque.vhttp,
        icon: Icons.http_rounded,
        value: masque.vhttp,
        choices: const ['auto', 'h3', 'h2'],
        onChanged: (value) => save(masque.copyWith(vhttp: value)),
      ),
      _WarpField(
        title: warp.masque.serverName,
        icon: Icons.badge_outlined,
        value: masque.serverName,
        hint: 'consumer-masque.cloudflareclient.com',
        onSaved: (value) => save(masque.copyWith(serverName: value)),
      ),
      _WarpSwitch(
        title: warp.masque.useIpv6,
        icon: Icons.numbers_rounded,
        value: masque.useIpv6,
        onChanged: (value) => save(masque.copyWith(useIpv6: value)),
      ),
      _WarpField(
        title: warp.masque.udpTimeout,
        icon: Icons.timer_off_outlined,
        value: masque.udpTimeout == 0 ? '' : masque.udpTimeout.toString(),
        digitsOnly: true,
        onSaved: (value) => save(masque.copyWith(udpTimeout: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.masque.keepalive,
        icon: Icons.favorite_outline_rounded,
        value: masque.udpKeepalive == 0 ? '' : masque.udpKeepalive.toString(),
        hint: '30',
        digitsOnly: true,
        onSaved: (value) => save(masque.copyWith(udpKeepalive: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.masque.packetSize,
        icon: Icons.straighten_rounded,
        value: masque.udpInitialPacketSize == 0 ? '' : masque.udpInitialPacketSize.toString(),
        digitsOnly: true,
        onSaved: (value) => save(masque.copyWith(udpInitialPacketSize: int.tryParse(value) ?? 0)),
      ),
      _WarpField(
        title: warp.masque.reconnectDelay,
        icon: Icons.replay_rounded,
        value: masque.reconnectDelay == 0 ? '' : masque.reconnectDelay.toString(),
        digitsOnly: true,
        onSaved: (value) => save(masque.copyWith(reconnectDelay: int.tryParse(value) ?? 0)),
      ),
      _WarpSwitch(
        title: warp.masque.tlsInsecure,
        icon: Icons.lock_open_rounded,
        value: masque.tlsInsecure,
        onChanged: (value) => save(masque.copyWith(tlsInsecure: value)),
      ),
      _WarpSwitch(
        title: warp.masque.fragment,
        icon: Icons.call_split_rounded,
        value: masque.tlsFragment,
        onChanged: (value) => save(masque.copyWith(tlsFragment: value)),
      ),
      if (masque.tlsFragment)
        _WarpField(
          title: warp.masque.fragmentDelay,
          icon: Icons.timer_outlined,
          value: masque.tlsFragmentFallbackDelay == 0 ? '' : masque.tlsFragmentFallbackDelay.toString(),
          digitsOnly: true,
          onSaved: (value) => save(masque.copyWith(tlsFragmentFallbackDelay: int.tryParse(value) ?? 0)),
        ),
      _WarpSwitch(
        title: warp.masque.recordFragment,
        icon: Icons.receipt_long_outlined,
        value: masque.tlsRecordFragment,
        onChanged: (value) => save(masque.copyWith(tlsRecordFragment: value)),
      ),
      _WarpSwitch(
        title: warp.masque.ech,
        icon: Icons.enhanced_encryption_rounded,
        value: masque.echEnabled,
        onChanged: (value) => save(masque.copyWith(echEnabled: value)),
      ),
      if (masque.echEnabled) ...[
        _WarpField(
          title: warp.masque.echConfig,
          icon: Icons.description_outlined,
          value: masque.echConfig,
          onSaved: (value) => save(masque.copyWith(echConfig: value)),
        ),
        _WarpField(
          title: warp.masque.echQueryServerName,
          icon: Icons.search_rounded,
          value: masque.echQueryServerName,
          onSaved: (value) => save(masque.copyWith(echQueryServerName: value)),
        ),
      ],
    ];
  }

  List<Widget> _awg(WidgetRef ref, Translations t) {
    final warp = t.pages.settings.chain.warp;
    final awg = ref.watch(preferences.awg);
    void save(SingboxWarpAwgOption next) => ref.read(preferences.awg.notifier).update(next);
    Widget number(String title, int value, SingboxWarpAwgOption Function(SingboxWarpAwgOption, int) apply) => _WarpField(
      title: title,
      icon: Icons.tune_rounded,
      value: value == 0 ? '' : value.toString(),
      digitsOnly: true,
      onSaved: (input) => save(apply(awg, int.tryParse(input) ?? 0)),
    );
    Widget text(String title, String value, SingboxWarpAwgOption Function(SingboxWarpAwgOption, String) apply) =>
        _WarpField(title: title, icon: Icons.tag_rounded, value: value, onSaved: (input) => save(apply(awg, input)));
    return [
      number(warp.awg.jc, awg.jc, (o, v) => o.copyWith(jc: v)),
      number(warp.awg.jmin, awg.jmin, (o, v) => o.copyWith(jmin: v)),
      number(warp.awg.jmax, awg.jmax, (o, v) => o.copyWith(jmax: v)),
      number(warp.awg.s1, awg.s1, (o, v) => o.copyWith(s1: v)),
      number(warp.awg.s2, awg.s2, (o, v) => o.copyWith(s2: v)),
      number('S3', awg.s3, (o, v) => o.copyWith(s3: v)),
      number('S4', awg.s4, (o, v) => o.copyWith(s4: v)),
      text(warp.awg.h1, awg.h1, (o, v) => o.copyWith(h1: v)),
      text(warp.awg.h2, awg.h2, (o, v) => o.copyWith(h2: v)),
      text(warp.awg.h3, awg.h3, (o, v) => o.copyWith(h3: v)),
      text(warp.awg.h4, awg.h4, (o, v) => o.copyWith(h4: v)),
      text('I1', awg.i1, (o, v) => o.copyWith(i1: v)),
      text('I2', awg.i2, (o, v) => o.copyWith(i2: v)),
      text('I3', awg.i3, (o, v) => o.copyWith(i3: v)),
      text('I4', awg.i4, (o, v) => o.copyWith(i4: v)),
      text('I5', awg.i5, (o, v) => o.copyWith(i5: v)),
    ];
  }

  List<Widget> _noise(WidgetRef ref, Translations t) {
    final warp = t.pages.settings.chain.warp;
    final noise = preferences.noise!;
    final noiseSize = preferences.noiseSize!;
    final noiseDelay = preferences.noiseDelay!;
    final noiseMode = preferences.noiseMode!;
    return [
      ValuePreferenceWidget(
        value: ref.watch(noise),
        preferences: ref.watch(noise.notifier),
        title: warp.noise.count,
        icon: Icons.web_stories_rounded,
        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
        presentValue: (value) => value.present(t),
        formatInputValue: (value) => value.format(),
      ),
      ValuePreferenceWidget(
        value: ref.watch(noiseSize),
        preferences: ref.watch(noiseSize.notifier),
        title: warp.noise.size,
        icon: Icons.settings_ethernet_rounded,
        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
        presentValue: (value) => value.present(t),
        formatInputValue: (value) => value.format(),
      ),
      ValuePreferenceWidget(
        value: ref.watch(noiseDelay),
        preferences: ref.watch(noiseDelay.notifier),
        title: warp.noise.delay,
        icon: Icons.schedule_rounded,
        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
        presentValue: (value) => value.present(t),
        formatInputValue: (value) => value.format(),
      ),
      ValuePreferenceWidget(
        value: ref.watch(noiseMode),
        preferences: ref.watch(noiseMode.notifier),
        title: warp.noise.mode,
        icon: Icons.mode_standby_rounded,
        presentValue: (value) => value.isEmpty ? '' : value,
      ),
    ];
  }
}

/// One text field of a WARP block, edited in a dialog and written back with copyWith.
class _WarpField extends StatelessWidget {
  const _WarpField({
    required this.title,
    required this.icon,
    required this.value,
    required this.onSaved,
    this.hint,
    this.digitsOnly = false,
  });

  final String title;
  final IconData icon;
  final String value;
  final String? hint;
  final bool digitsOnly;
  final ValueChanged<String> onSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: value.isEmpty ? null : Text(value, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final input = await showDialog<String>(
          context: context,
          builder: (context) => _WarpFieldDialog(title: title, initial: value, hint: hint, digitsOnly: digitsOnly),
        );
        if (input != null) onSaved(input.trim());
      },
    );
  }
}

/// One choice of a WARP block, out of a fixed list of strings.
class _WarpChoice extends StatelessWidget {
  const _WarpChoice({
    required this.title,
    required this.icon,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final String value;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value.isEmpty ? choices.first : value;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(current),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              for (final choice in choices)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(choice),
                  child: Row(
                    children: [
                      Icon(
                        choice == current ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(choice),
                    ],
                  ),
                ),
            ],
          ),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _WarpFieldDialog extends StatefulWidget {
  const _WarpFieldDialog({required this.title, required this.initial, this.hint, this.digitsOnly = false});

  final String title;
  final String initial;
  final String? hint;
  final bool digitsOnly;

  @override
  State<_WarpFieldDialog> createState() => _WarpFieldDialogState();
}

class _WarpFieldDialogState extends State<_WarpFieldDialog> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: widget.digitsOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

/// One boolean field of a WARP block.
class _WarpSwitch extends StatelessWidget {
  const _WarpSwitch({required this.title, required this.icon, required this.value, required this.onChanged});

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
