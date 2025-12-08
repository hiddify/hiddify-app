import 'package:freezed_annotation/freezed_annotation.dart';
import '../../config/model/config.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String name,
    required String url,
    required DateTime lastUpdated,
    @Default([]) List<Config> configs,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}
