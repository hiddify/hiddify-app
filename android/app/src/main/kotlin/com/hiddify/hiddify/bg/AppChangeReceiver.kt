package com.hiddify.hiddify.bg

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.hiddify.hiddify.Settings

class AppChangeReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "A/AppChangeReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // checkUpdate(context, intent)
    }
}