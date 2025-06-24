import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DnsOptionsPage extends HookConsumerWidget {
  const DnsOptionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.config.section.dns),
      ),
      body: ListView(
        children: [
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.remoteDnsAddress),
            icon: Icons.vpn_lock_rounded,
            preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
            title: t.config.remoteDnsAddress,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
            preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
            choices: DomainStrategy.values,
            title: t.config.remoteDnsDomainStrategy,
            icon: Icons.sync_alt_rounded,
            presentChoice: (value) => value.displayName,
          ),
          ValuePreferenceWidget(
            title: t.config.directDnsAddress,
            icon: Icons.public_rounded,
            value: ref.watch(ConfigOptions.directDnsAddress),
            preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
            preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
            choices: DomainStrategy.values,
            title: t.config.directDnsDomainStrategy,
            icon: Icons.sync_alt_rounded,
            presentChoice: (value) => value.displayName,
          ),
          SwitchListTile.adaptive(
            title: Text(t.config.enableDnsRouting),
            secondary: const Icon(Icons.private_connectivity_rounded),
            value: ref.watch(ConfigOptions.enableDnsRouting),
            onChanged: ref.read(ConfigOptions.enableDnsRouting.notifier).update,
          ),
        ],
      ),
    );
  }
}
