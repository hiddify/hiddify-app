package com.hiddify.hiddify.bg

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.hiddify.hiddify.Settings
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
            }

            else -> return
        }
        GlobalScope.launch(Dispatchers.IO) {
            if (Settings.startedByUser) {
                withContext(Dispatchers.Main) {
                    BoxService.start()
                }
            }
        }
    }

}