import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generic_list_notifier.g.dart';

@riverpod
class GenericListNotifier extends _$GenericListNotifier {
  late int? _ruleListOrder;
  late RuleEnum _ruleEnum;

  @override
  List<dynamic> build(int? ruleListOrder, RuleEnum ruleEnum) {
    _ruleListOrder = ruleListOrder;
    _ruleEnum = ruleEnum;
    final value = ref.read(ruleNotifierProvider(ruleListOrder)).writeToJsonMap()['${ruleEnum.getIndex()}'];
    if (value is List) return value;
    return [];
  }

  void add(dynamic value) {
    if (!_isValid(value)) return;
    state = [...state, value];
    _save();
  }

  void update(int index, dynamic value) {
    if (!_isValid(value)) return;
    state = List.from(state)..[index] = value;
    _save();
  }

  void remove(int index) {
    state = List.from(state)..removeAt(index);
    _save();
  }

  void reset() {
    state = [];
    _save();
  }

  void _save() => ref.read(ruleNotifierProvider(_ruleListOrder).notifier).update<List<dynamic>>(_ruleEnum, state);

  bool _isValid(dynamic value) {
    if (value == null) return false;
    if (state.contains(value)) {
      ref.read(inAppNotificationControllerProvider).showErrorToast('Value is exist');
      return false;
    }
    return true;
  }
}
