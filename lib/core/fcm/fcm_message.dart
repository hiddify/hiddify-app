// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fcm_message.freezed.dart';

@freezed
class FcmMessage with _$FcmMessage {
  const FcmMessage._();

  const factory FcmMessage({
    required String subscriptionUrl,
    required String profileId,
  }) = _FcmMessage;

  factory FcmMessage.fromMap(Map<String, dynamic> data) {
    final subscriptionUrl = data['subscriptionUrl'] as String?;
    final profileId = data['profileId'] as String?;

    if (subscriptionUrl == null || subscriptionUrl.isEmpty) {
      throw FormatException('FCM message missing or empty subscriptionUrl');
    }

    if (profileId == null || profileId.isEmpty) {
      throw FormatException('FCM message missing or empty profileId');
    }

    return FcmMessage(
      subscriptionUrl: subscriptionUrl,
      profileId: profileId,
    );
  }

  bool get isValid => subscriptionUrl.isNotEmpty && profileId.isNotEmpty;

  bool get hasValidUrl {
    final uri = Uri.tryParse(subscriptionUrl);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }
}
*/
