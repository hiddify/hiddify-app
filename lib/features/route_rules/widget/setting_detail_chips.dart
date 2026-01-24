import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class SettingDetailChips<T extends Object> extends HookConsumerWidget {
  const SettingDetailChips({
    super.key,
    required this.values,
    this.t,
    this.scrollController,
    this.useEllipsis = false,
    this.isPackageName = false,
  });

  final List<T> values;
  final Map<String, String>? t;
  final ScrollController? scrollController;
  final bool useEllipsis;
  final bool isPackageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = scrollController ?? useScrollController();
    final showStartBtn = useState(false);
    final showEndBtn = useState(true);

    useEffect(() {
      void listener() {
        showStartBtn.value = controller.position.pixels > controller.position.minScrollExtent;
        showEndBtn.value = controller.position.pixels < controller.position.maxScrollExtent;
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void scrollToEnd() {
      controller.animateTo(
        controller.offset + 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    void scrollToStart() {
      controller.animateTo(
        controller.offset - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.position.maxScrollExtent <= 0) {
            showStartBtn.value = false;
            showEndBtn.value = false;
          } else {
            showStartBtn.value = controller.position.pixels > controller.position.minScrollExtent;
            showEndBtn.value = controller.position.pixels < controller.position.maxScrollExtent;
          }
        });
        return Container(
          padding: const EdgeInsets.only(bottom: 8),
          height: 32,
          child: PlatformUtils.isDesktop
              ? Stack(
                  children: [
                    ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: values.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => SettingDetailChip<T>(
                        value: values[index],
                        t: t,
                        useEllipsis: useEllipsis,
                        isPackageName: isPackageName,
                      ),
                      separatorBuilder: (context, index) => const Gap(8),
                    ),
                    Row(
                      children: [
                        if (showStartBtn.value) ScrollBtn(isStart: true, onTap: scrollToStart),
                        const Spacer(),
                        if (showEndBtn.value) ScrollBtn(isStart: false, onTap: scrollToEnd),
                      ],
                    ),
                  ],
                )
              : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: values.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => SettingDetailChip<T>(
                    value: values[index],
                    t: t,
                    useEllipsis: useEllipsis,
                    isPackageName: isPackageName,
                  ),
                  separatorBuilder: (context, index) => const Gap(8),
                ),
        );
      },
    );
  }
}

class SettingDetailChip<T extends Object> extends ConsumerWidget {
  const SettingDetailChip({
    super.key,
    required this.value,
    required this.t,
    required this.useEllipsis,
    required this.isPackageName,
  });

  final T value;
  final Map<String, String>? t;
  final bool useEllipsis;
  final bool isPackageName;

  Widget valueByType(T value, ThemeData theme) {
    if (value is MapEntry) {
      return Row(
        children: [
          tText('${value.key}', theme),
          VerticalDivider(width: 12, color: theme.colorScheme.onSurfaceVariant, indent: 3, endIndent: 3),
          tText('${value.value}', theme),
        ],
      );
    } else {
      return tText('$value', theme);
    }
  }

  Widget tText(String value, ThemeData theme) {
    String text = value;
    if (useEllipsis && value.length > 20) {
      text = '${value.substring(0, 10)}...${value.substring(value.length - 10)}';
    }
    return Text(t == null ? text : t![text] ?? text, style: theme.textTheme.labelMedium);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: isPackageName
          ? AndroidAppInfo(packageName: '$value')
          : Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: valueByType(value, theme)),
    );
  }
}

class AndroidAppInfo extends HookConsumerWidget {
  const AndroidAppInfo({super.key, required this.packageName});

  final String packageName;

  String useEllipsis() {
    if (packageName.length > 20) {
      return '${packageName.substring(0, 10)}...${packageName.substring(packageName.length - 10)}';
    } else {
      return packageName;
    }
  }

  Future<AppInfo?> getAppInfo() async => await InstalledApps.getAppInfo(packageName, BuiltWith.flutter);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = useFuture<AppInfo?>(useMemoized(() => getAppInfo(), [packageName]));
    if (app.hasData && app.data != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: CircleAvatar(backgroundColor: Colors.transparent, child: Image.memory(app.data!.icon!)),
            ),
            const Gap(4),
            Text(app.data!.name, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
    } else if (app.hasError || (app.hasData && app.data == null)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(useEllipsis(), style: Theme.of(context).textTheme.labelMedium),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(4),
        child: AspectRatio(aspectRatio: 1.0, child: CircularProgressIndicator()),
      );
    }
  }
}

class ScrollBtn extends ConsumerWidget {
  const ScrollBtn({super.key, required this.isStart, required this.onTap});

  final bool isStart;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const radius = Radius.circular(4);
    final borderRadius = isStart
        ? const BorderRadiusDirectional.only(topEnd: radius, bottomEnd: radius)
        : const BorderRadiusDirectional.only(topStart: radius, bottomStart: radius);
    return Material(
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius.resolve(Directionality.of(context)),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: borderRadius,
            boxShadow: [BoxShadow(color: theme.colorScheme.shadow, blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Icon(
            isStart ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
