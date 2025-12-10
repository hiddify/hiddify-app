// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hiddify/core/fcm/fcm_data_providers.dart';
import 'package:hiddify/core/fcm/fcm_message.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_notifier.g.dart';

@Riverpod(keepAlive: true)
class FcmNotifier extends _$FcmNotifier with InfraLogger {
  StreamSubscription<FcmMessage>? _messageSubscription;
  StreamSubscription<FcmMessage>? _pollingSubscription;

  @override
  FcmMessage? build() {
    if (Platform.isLinux || Platform.isWindows) {
      // Polling setup for Linux and Windows
      loggy.info('Initializing FCM polling service for ${Platform.operatingSystem}');
      ref.watch(fcmPollingServiceProvider.future).then((pollingService) {
        _pollingSubscription = pollingService.messageStream.listen(
          (message) {
            loggy.debug('Polling message received in notifier: ${message.profileId}');
            _handleForegroundMessage(message);
          },
          onError: (error) {
            loggy.error('Error in polling message stream', error);
          },
        );
      }).catchError((error) {
        loggy.error('Error initializing polling service', error);
      });

      // Clean up polling subscription on dispose
      ref.onDispose(() {
        _pollingSubscription?.cancel();
        _pollingSubscription = null;
      });
    } else {
      // FCM setup for macOS, Android, iOS
      try {
        loggy.info('Initializing native FCM service for ${Platform.operatingSystem}');
        final fcmService = ref.read(fcmServiceProvider);

        // Register handler for background/terminated messages
        // These bypass the action toast since user already tapped the notification
        fcmService.setBackgroundMessageHandler(handleBackgroundMessage);

        // Set up message listener for foreground messages
        // These show action toasts for user confirmation
        _messageSubscription = fcmService.messageStream.listen(
          (message) {
            loggy.debug('FCM message received in notifier: ${message.profileId}');
            _handleForegroundMessage(message);
          },
          onError: (error) {
            loggy.error('Error in FCM message stream', error);
          },
        );

        // Clean up subscription on dispose
        ref.onDispose(() {
          _messageSubscription?.cancel();
          _messageSubscription = null;
        });
      } catch (e) {
        if (Platform.isMacOS) {
          loggy.warning('FCM initialization failed on macOS, falling back to polling', e);
          // Initialize polling service as fallback
          ref.watch(fcmPollingServiceProvider.future).then((pollingService) {
            _pollingSubscription = pollingService.messageStream.listen(
              (message) {
                loggy.debug('Polling message received in notifier (macOS fallback): ${message.profileId}');
                _handleForegroundMessage(message);
              },
              onError: (error) {
                loggy.error('Error in polling message stream (macOS fallback)', error);
              },
            );
          }).catchError((error) {
            loggy.error('Error initializing polling service (macOS fallback)', error);
          });

          // Clean up polling subscription on dispose
          ref.onDispose(() {
            _pollingSubscription?.cancel();
            _pollingSubscription = null;
          });
        } else {
          rethrow; // Re-throw for Android/iOS as FCM is required
        }
      }
    }

    return null;
  }

  /// Handle foreground message (app is open and visible).
  ///
  /// These messages show an action toast for user confirmation before updating,
  /// since the user hasn't explicitly tapped a notification.
  void _handleForegroundMessage(FcmMessage message) {
    loggy.debug('Handling foreground FCM message for profile: ${message.profileId}');

    // Update state with the received message
    state = message;

    // Get profile repository to fetch profile name
    final profileRepository = ref.read(profileRepositoryProvider).requireValue;

    // Silently update profile without showing toast
    profileRepository.getByName(message.profileId).then((profile) {
      if (profile == null) {
        loggy.warning('Profile not found: ${message.profileId}');
        return;
      }

      if (profile is! RemoteProfileEntity) {
        loggy.warning('Profile is not a remote profile: ${message.profileId}');
        return;
      }

      // Silently update the profile
      _updateProfile(message);
    }).catchError((error) {
      loggy.error('Failed to fetch profile for FCM message', error);
    });
  }

  Future<void> _updateProfile(FcmMessage message) async {
    loggy.info('Updating profile ${message.profileId} with URL: ${message.subscriptionUrl}');

    final notificationController = ref.read(inAppNotificationControllerProvider);
    final profileRepository = ref.read(profileRepositoryProvider).requireValue;

    try {
      // Fetch the profile
      final profile = await profileRepository.getByName(message.profileId);

      if (profile == null) {
        loggy.warning('Profile not found for update: ${message.profileId}');
        notificationController.showErrorToast('Profile not found');
        return;
      }

      if (profile is! RemoteProfileEntity) {
        loggy.warning('Cannot update local profile: ${message.profileId}');
        notificationController.showErrorToast('Cannot update local profile');
        return;
      }

      // Create updated profile with new URL
      final updatedProfile = profile.copyWith(url: message.subscriptionUrl);

      // Update the subscription
      final updateResult = await profileRepository
          .updateSubscription(
            updatedProfile,
            patchBaseProfile: true,
          )
          .run();

      updateResult.fold(
        (failure) {
          loggy.error('Failed to update profile subscription', failure);
          notificationController.showErrorToast(
            'Failed to update profile: ${failure.toString()}',
          );
        },
        (_) {
          loggy.info('Profile ${message.profileId} updated successfully');
          notificationController.showSuccessToast(
            'Profile ${profile.name} updated successfully',
          );
        },
      );
    } catch (e, stackTrace) {
      loggy.error('Unexpected error updating profile', e, stackTrace);
      notificationController.showErrorToast('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle background/terminated message (called when user taps notification).
  ///
  /// This method is called for messages opened from:
  /// - Background state: User taps notification while app is in background
  /// - Terminated state: User taps notification to open app from terminated state
  ///
  /// These messages bypass the action toast since the user already explicitly
  /// tapped the notification, indicating intent to update.
  Future<void> handleBackgroundMessage(RemoteMessage remoteMessage) async {
    loggy.debug('Handling background FCM message: ${remoteMessage.messageId}');

    try {
      final data = remoteMessage.data;
      if (data.isEmpty) {
        loggy.warning('Background FCM message has no data payload');
        return;
      }

      final message = FcmMessage.fromMap(data);
      if (!message.isValid || !message.hasValidUrl) {
        loggy.warning('Invalid background FCM message');
        return;
      }

      // Directly update without showing action toast (user already tapped notification)
      await _updateProfile(message);
    } catch (e, stackTrace) {
      loggy.error('Error handling background FCM message', e, stackTrace);
    }
  }
}
*/
