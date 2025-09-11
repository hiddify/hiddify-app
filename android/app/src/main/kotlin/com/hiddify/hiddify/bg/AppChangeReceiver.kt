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
        checkUpdate(context, intent)
    }

    private fun checkUpdate(context: Context, intent: Intent) {
//        if (!Settings.perAppProxyEnabled) {
//            return
//        }
//        val perAppProxyUpdateOnChange = Settings.perAppProxyUpdateOnChange
//        if (perAppProxyUpdateOnChange == Settings.PER_APP_PROXY_DISABLED) {
//            return
//        }
//        val packageName = intent.dataString?.substringAfter("package:")
//        if (packageName.isNullOrBlank()) {
//            return
//        }
//        if ((perAppProxyUpdateOnChange == Settings.PER_APP_PROXY_INCLUDE)) {
//            Settings.perAppProxyList = Settings.perAppProxyList + packageName
//        } else {
//            Settings.perAppProxyList = Settings.perAppProxyList - packageName
//        }
    }

}