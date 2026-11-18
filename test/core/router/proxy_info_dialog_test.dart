import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/dialog/widgets/proxy_info_dialog.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoProxies extends ProxiesOverviewNotifier {
  @override
  Stream<OutboundGroup?> build() => Stream.value(null);
}

// no profile: the dialog reads the active one for keep top, which would open the database
class _NoProfile extends ActiveProfile {
  @override
  Stream<ProfileEntity?> build() => Stream.value(null);
}

class _NoMainOutbounds extends MainOutboundsNotifier {
  @override
  Stream<OutboundGroupList> build() => const Stream.empty();
}

/// The core's list with [hop] as the chain hop.
class _WithHop extends MainOutboundsNotifier {
  _WithHop(this.hop);
  final OutboundInfo hop;

  @override
  Stream<OutboundGroupList> build() => Stream.value(OutboundGroupList(chainHop: hop));
}

final _psiphonHop = OutboundInfo(tag: 'psiphon-hop', tagDisplay: 'Psiphon', type: 'Psiphon', urlTestDelay: 300);

void main() {
  Future<Translations> show(
    WidgetTester tester,
    OutboundInfo proxy, {
    OutboundInfo? hop,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer(
      overrides: [
        translationsProvider.overrideWith((ref) => AppLocale.en.build()),
        proxiesOverviewNotifierProvider.overrideWith(_NoProxies.new),
        mainOutboundsNotifierProvider.overrideWith(hop == null ? _NoMainOutbounds.new : () => _WithHop(hop)),
        activeProfileProvider.overrideWith(_NoProfile.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sharedPreferencesProvider.future);
    final t = await container.read(translationsProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProxyInfoDialog(outboundInfo: proxy)),
          ),
        ),
      ),
    );
    await tester.pump();
    return t;
  }

  testWidgets('a failed proxy says why', (tester) async {
    const reason = 'connect MASQUE tunnel: CONNECT-IP: 403 Forbidden';
    final t = await show(
      tester,
      OutboundInfo(tag: 'WARP-MASQUE', tagDisplay: 'WARP-MASQUE', status: Status.FAILED, error: reason),
    );
    expect(find.text(t.dialogs.proxyInfo.error), findsOneWidget);
    expect(find.text(reason), findsOneWidget);
  });

  testWidgets('a proxy that works has no failure box', (tester) async {
    final t = await show(tester, OutboundInfo(tag: 'proxy', tagDisplay: 'proxy', urlTestDelay: 120));
    expect(find.text(t.dialogs.proxyInfo.error), findsNothing);
  });

  testWidgets('the Psiphon unblocker hop offers to change its country', (tester) async {
    final t = await show(
      tester,
      _psiphonHop,
      hop: _psiphonHop,
      prefs: {'chain-status': 'unblocker', 'unblocker-mode': 'psiphon'},
    );
    expect(find.text(t.dialogs.proxyInfo.changeCountry), findsOneWidget);
  });

  testWidgets('the Psiphon extra security hop offers to change its country', (tester) async {
    final t = await show(
      tester,
      _psiphonHop,
      hop: _psiphonHop,
      prefs: {'chain-status': 'extraSecurity', 'extra-security-mode': 'psiphon'},
    );
    expect(find.text(t.dialogs.proxyInfo.changeCountry), findsOneWidget);
  });

  testWidgets('a WARP hop does not offer a country', (tester) async {
    final t = await show(
      tester,
      _psiphonHop,
      hop: _psiphonHop,
      prefs: {'chain-status': 'unblocker', 'unblocker-mode': 'warp'},
    );
    expect(find.text(t.dialogs.proxyInfo.changeCountry), findsNothing);
  });

  testWidgets('a proxy that is not the hop does not offer a country', (tester) async {
    final t = await show(
      tester,
      OutboundInfo(tag: 'proxy', tagDisplay: 'proxy'),
      hop: _psiphonHop,
      prefs: {'chain-status': 'unblocker', 'unblocker-mode': 'psiphon'},
    );
    expect(find.text(t.dialogs.proxyInfo.changeCountry), findsNothing);
  });
}
