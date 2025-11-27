package com.hiddify.hiddify.bg

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.hiddify.hiddify.Settings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                if (Settings.startedByUser) {
                    withContext(Dispatchers.Main) {
                        BoxService.start()
                    }
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}