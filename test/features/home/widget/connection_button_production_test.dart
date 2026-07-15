import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/identity/data/identity_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _ConnectionState extends ConnectionNotifier {
  @override
  Stream<ConnectionStatus> build() => Stream.value(const ConnectionStatus.disconnected());
}

class _ProfileState extends ActiveProfile {
  _ProfileState(this.source);

  final Stream<ProfileEntity?> source;

  @override
  Stream<ProfileEntity?> build() => source;
}

class _ProxyState extends ActiveProxyNotifier {
  @override
  Stream<OutboundInfo> build() => const Stream.empty();
}

class _ReconnectState extends ConfigOptionNotifier {
  @override
  Future<bool> build() async => false;
}

void main() {
  Future<void> pumpProductionHome(
    WidgetTester tester,
    Stream<ProfileEntity?> profiles, {
    bool wholePage = false,
  }) async {
    final translations = await AppLocale.en.build();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => translations),
          connectionNotifierProvider.overrideWith(_ConnectionState.new),
          activeProfileProvider.overrideWith(() => _ProfileState(profiles)),
          activeProxyNotifierProvider.overrideWith(_ProxyState.new),
          configOptionNotifierProvider.overrideWith(_ReconnectState.new),
          installationIdentityProvider.overrideWith((ref) => 'test-installation'),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [NovaThemeData.dark]),
          home: wholePage ? const HomePage() : const Scaffold(body: ConnectionButton()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('disables the production connection action while profile state is loading', (tester) async {
    await pumpProductionHome(tester, const Stream.empty());

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('home_connection_button'))).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets('disables the production connection action when profile loading fails', (tester) async {
    await pumpProductionHome(tester, Stream.error(StateError('profile failed')));
    await tester.pump();

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('home_connection_button'))).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets('HomePage keeps its server action disabled while the profile provider loads', (tester) async {
    await pumpProductionHome(tester, const Stream.empty(), wholePage: true);

    final cardTap = find.descendant(of: find.byType(NovaServerCard), matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(cardTap).onTap, isNull);
    expect(
      find.descendant(of: find.byType(NovaServerCard), matching: find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );
  });

  testWidgets('HomePage surfaces a profile-provider error without enabling server navigation', (tester) async {
    await pumpProductionHome(tester, Stream.error(StateError('profile failed')), wholePage: true);
    await tester.pump();

    final cardTap = find.descendant(of: find.byType(NovaServerCard), matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(cardTap).onTap, isNull);
    expect(
      find.descendant(of: find.byType(NovaServerCard), matching: find.byIcon(Icons.error_outline_rounded)),
      findsOneWidget,
    );
  });
}
