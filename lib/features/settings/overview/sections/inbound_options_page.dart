import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/lan_sharing_tile.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/features/settings/widget/proxy_secret_editor.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InboundOptionsPage extends HookConsumerWidget with AppLogger {
  const InboundOptionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.inbound;
    final mode = ref.watch(ConfigOptions.serviceMode);
    final vpn = mode == ServiceMode.tun || mode == ServiceMode.router;
    final shared = ref.watch(ConfigOptions.allowConnectionFromLan);
    final localAuth = ref.watch(ConfigOptions.localProxyAuth);
    final mixedPort = ref.watch(ConfigOptions.mixedPort);
    final lanPort = ref.watch(ConfigOptions.lanSharingPort);
    // the local port is this device's own: in VPN mode it opens only when asked to
    String localPort(int value) =>
        vpn && !ref.watch(ConfigOptions.localProxyInVpn) ? '$value · ${text.closedInVpnLocal}' : '$value';
    // the transparent ports serve the network in VPN mode, while it is shared
    String port(int value) => vpn && !shared ? '$value · ${text.closedInVpn}' : '$value';
    // the two proxy ports are apart: one asks for the secret, the other need not
    bool Function(String) portApartFrom(int other) =>
        (input) => isPort(input) && int.tryParse(input) != other;

    final tproxy = PlatformUtils.isLinux;
    // redirect reads the original address from Linux netfilter or the macOS pf, which the App
    // Store's sandbox does not reach
    final redirect = PlatformUtils.isLinux || (PlatformUtils.isMacOS && Release.read() != Release.appStore);
    final direct = PlatformUtils.isDesktop;

    return Scaffold(
      appBar: AppBar(title: Text(text.title)),
      body: ListView(
        children: [
          ChoicePreferenceWidget(
            selected: mode,
            preferences: ref.watch(ConfigOptions.serviceMode.notifier),
            choices: ServiceMode.choices,
            title: text.serviceMode,
            icon: Icons.tune_rounded,
            presentChoice: (value) => value.present(t),
          ),
          SwitchListTile.adaptive(
            title: Text(text.strictRoute),
            secondary: const Icon(Icons.merge_rounded),
            value: ref.watch(ConfigOptions.strictRoute),
            onChanged: ref.read(ConfigOptions.strictRoute.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.tunImplementation),
            preferences: ref.watch(ConfigOptions.tunImplementation.notifier),
            choices: TunImplementation.values,
            title: text.tunImplementation,
            icon: Icons.trip_origin_rounded,
            presentChoice: (value) => value.present(t),
          ),
          _GroupHeader(text.localProxy),
          ValuePreferenceWidget(
            value: mixedPort,
            preferences: ref.watch(ConfigOptions.mixedPort.notifier),
            title: text.mixedPort,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            digitsOnly: true,
            validateInput: portApartFrom(lanPort),
            presentValue: localPort,
            trailing: SwitchPreferenceWidget(preference: ConfigOptions.enableMixedPort),
          ),
          SwitchListTile.adaptive(
            title: Text(text.localProxyInVpn),
            subtitle: Text(text.localProxyInVpnHint),
            secondary: const Icon(Icons.vpn_lock_rounded),
            value: ref.watch(ConfigOptions.localProxyInVpn),
            onChanged: ref.read(ConfigOptions.localProxyInVpn.notifier).update,
          ),
          SwitchListTile.adaptive(
            title: Text(text.localProxyAuth),
            subtitle: Text(
              mode == ServiceMode.systemProxy
                  ? '${text.localProxyAuthHint}\n${text.notAsSystemProxy}'
                  : text.localProxyAuthHint,
            ),
            secondary: const Icon(Icons.password_rounded),
            value: localAuth,
            onChanged: ref.read(ConfigOptions.localProxyAuth.notifier).update,
          ),
          if (localAuth) const _ProxySecretTile(),
          _GroupHeader(text.lanGroup),
          const LanSharingPreferenceWidget(),
          ValuePreferenceWidget(
            value: lanPort,
            preferences: ref.watch(ConfigOptions.lanSharingPort.notifier),
            title: text.lanSharingPort,
            icon: Icons.lan_rounded,
            inputToValue: int.tryParse,
            digitsOnly: true,
            validateInput: portApartFrom(mixedPort),
          ),
          const _ProxySecretTile(),
          if (tproxy || redirect || direct) _GroupHeader(text.otherPorts),
          if (tproxy)
            ValuePreferenceWidget(
              value: ref.watch(ConfigOptions.tproxyPort),
              preferences: ref.watch(ConfigOptions.tproxyPort.notifier),
              title: text.tproxyPort,
              icon: Icons.device_hub_rounded,
              inputToValue: int.tryParse,
              digitsOnly: true,
              validateInput: isPort,
              presentValue: port,
              trailing: SwitchPreferenceWidget(preference: ConfigOptions.enableTproxyPort),
            ),
          if (redirect)
            ValuePreferenceWidget(
              value: ref.watch(ConfigOptions.redirectPort),
              preferences: ref.watch(ConfigOptions.redirectPort.notifier),
              title: text.redirectPort,
              icon: Icons.device_hub_rounded,
              inputToValue: int.tryParse,
              digitsOnly: true,
              validateInput: isPort,
              presentValue: port,
              trailing: SwitchPreferenceWidget(preference: ConfigOptions.enableRedirectPort),
            ),
          if (direct)
            ValuePreferenceWidget(
              value: ref.watch(ConfigOptions.directPort),
              preferences: ref.watch(ConfigOptions.directPort.notifier),
              title: text.directPort,
              icon: Icons.device_hub_rounded,
              inputToValue: int.tryParse,
              digitsOnly: true,
              validateInput: isPort,
              presentValue: port,
              trailing: SwitchPreferenceWidget(preference: ConfigOptions.enableDirectPort),
            ),
          const Gap(16),
        ],
      ),
    );
  }
}

/// The title of a group of settings on the page.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 4),
      child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

/// The password of the user "hiddify" that the LAN sharing port asks for, and the local port while
/// it requires one. A new one can be made; removing it, at the user's own risk, leaves the ports
/// open to any app or device that reaches them.
class _ProxySecretTile extends HookConsumerWidget {
  const _ProxySecretTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.inbound;
    final theme = Theme.of(context);
    final secret = ref.watch(ConfigOptions.lanSharingPassword);
    // hidden until asked for, as anyone looking at the screen could use it
    final revealed = useState(false);
    return ListTile(
      leading: Icon(secret.isEmpty ? Icons.lock_open_rounded : Icons.key_rounded),
      title: Text(text.proxySecret),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: secret.isEmpty
            ? Text(text.noSecret, style: TextStyle(color: theme.colorScheme.error))
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: revealed.value
                    ? ProxySecretText(secret, style: theme.textTheme.bodyMedium)
                    : Text('••••••••', style: theme.textTheme.bodyMedium),
              ),
      ),
      trailing: secret.isEmpty
          ? null
          : IconButton(
              tooltip: revealed.value ? t.dialogs.qrCode.hidePassword : t.dialogs.qrCode.showPassword,
              icon: Icon(revealed.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => revealed.value = !revealed.value,
            ),
      onTap: () => editProxySecret(ref),
    );
  }
}
