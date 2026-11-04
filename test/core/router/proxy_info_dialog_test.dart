import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/widgets/proxy_info_dialog.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _NoProxies extends ProxiesOverviewNotifier {
  @override
  Stream<OutboundGroup?> build() => Stream.value(null);
}

class _NoMainOutbounds extends MainOutboundsNotifier {
  @override
  Stream<OutboundGroupList> build() => const Stream.empty();
}

void main() {
  Future<Translations> show(WidgetTester tester, OutboundInfo proxy) async {
    final container = ProviderContainer(
      overrides: [
        translationsProvider.overrideWith((ref) => AppLocale.en.build()),
        proxiesOverviewNotifierProvider.overrideWith(_NoProxies.new),
        mainOutboundsNotifierProvider.overrideWith(_NoMainOutbounds.new),
      ],
    );
    addTearDown(container.dispose);
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
}
