// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
package com.hiddify.hiddify

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * DEPRECATED: This custom Firebase Messaging Service is no longer used.
 * 
 * This class has been disabled to avoid conflicts with Flutter's firebase_messaging plugin's
 * own FirebaseMessagingService. The Flutter plugin automatically handles all FCM messages and
 * token refresh through its own service implementation.
 * 
 * The service declaration has been commented out in AndroidManifest.xml to prevent it from
 * intercepting FCM messages that should be handled by the Flutter plugin.
 * 
 * If custom native FCM handling is needed in the future, the recommended approach is to:
 * 1. Extend the Flutter plugin's FirebaseMessagingService implementation
 * 2. Have a single service that both calls into Flutter and performs any extra native work
 * 3. Avoid creating competing services for com.google.firebase.MESSAGING_EVENT
 * 
 * @deprecated This class is not referenced and should not be used.
 */
@Deprecated("This service conflicts with Flutter firebase_messaging plugin's own service. Use the Flutter plugin's service instead.")
class FcmService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FcmService"
        private const val PREFS_NAME = "fcm_prefs"
        private const val PREFS_KEY_TOKEN = "fcm_token"
    }

    /**
     * Handle incoming FCM messages silently without displaying notifications.
     * 
     * This method is called when:
     * - App is in foreground
     * - App is in background
     * - App is terminated
     * 
     * The Firebase Messaging plugin automatically routes data-only messages to Flutter's
     * background message handler (firebaseMessagingBackgroundHandler in fcm_service.dart).
     */
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val messageId = message.messageId
        val data = message.data

        Log.d(TAG, "FCM message received: messageId=$messageId, data=$data")

        // Validate that required data fields are present
        val subscriptionUrl = data["subscriptionUrl"]
        val profileId = data["profileId"]

        if (subscriptionUrl.isNullOrEmpty() || profileId.isNullOrEmpty()) {
            Log.w(TAG, "FCM message missing required fields: subscriptionUrl=$subscriptionUrl, profileId=$profileId")
            return
        }

        // Message is valid - Firebase Messaging plugin will automatically forward
        // to Flutter's background message handler for processing
        // No notification is displayed - processing is silent
    }

    /**
     * Handle FCM token refresh.
     * 
     * Called when a new FCM token is generated (e.g., after app reinstall, device restore,
     * or token rotation). The token should be sent to the backend server.
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)

        Log.d(TAG, "FCM token refreshed: ${token.take(20)}...")

        // Store token in SharedPreferences for future use
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(PREFS_KEY_TOKEN, token)
            .apply()
    }
}
*/
