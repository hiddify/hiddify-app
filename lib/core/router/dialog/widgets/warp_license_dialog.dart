import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WarpLicenseDialog extends HookConsumerWidget {
  const WarpLicenseDialog({super.key});

  // for focus management
  KeyEventResult _handleKeyEvent(KeyEvent event, String key) {
    if (KeyboardConst.select.contains(event.logicalKey) && event is KeyUpEvent) {
      UriUtils.tryLaunch(Uri.parse(WarpConst.url[key]!));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // for focus management
    final focusStates = <String, ValueNotifier<bool>>{
      WarpConst.warpTermsOfServiceKey: useState<bool>(false),
      WarpConst.warpPrivacyPolicyKey: useState<bool>(false),
    };
    final focusNodes = <String, FocusNode>{
      WarpConst.warpTermsOfServiceKey: useFocusNode(),
      WarpConst.warpPrivacyPolicyKey: useFocusNode(),
    };
    useEffect(() {
      for (final entry in focusNodes.entries) {
        entry.value.addListener(() => focusStates[entry.key]!.value = entry.value.hasPrimaryFocus);
      }
      return null;
    }, []);
    return AlertDialog(
      title: Text(t.dialogs.warpLicense.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Focus(
                focusNode: focusNodes[WarpConst.warpTermsOfServiceKey],
                onKeyEvent: (node, event) => _handleKeyEvent(event, WarpConst.warpTermsOfServiceKey),
                child: const Gap(0.1),
              ),
              Focus(
                focusNode: focusNodes[WarpConst.warpPrivacyPolicyKey],
                onKeyEvent: (node, event) => _handleKeyEvent(event, WarpConst.warpPrivacyPolicyKey),
                child: const Gap(0.1),
              ),
              Text.rich(
                t.dialogs.warpLicense.description(
                  tos: (text) => TextSpan(
                    text: text,
                    style: TextStyle(
                      color: focusStates[WarpConst.warpTermsOfServiceKey]!.value ? Colors.green : Colors.blue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await UriUtils.tryLaunch(Uri.parse(Constants.cfWarpTermsOfService));
                      },
                  ),
                  privacy: (text) => TextSpan(
                    text: text,
                    style: TextStyle(
                      color: focusStates[WarpConst.warpPrivacyPolicyKey]!.value ? Colors.green : Colors.blue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await UriUtils.tryLaunch(Uri.parse(Constants.cfWarpPrivacyPolicy));
                      },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.pop(false);
          },
          child: Text(t.common.decline),
        ),
        TextButton(
          onPressed: () {
            context.pop(true);
          },
          child: Text(t.common.agree),
        ),
      ],
    );
  }
}
