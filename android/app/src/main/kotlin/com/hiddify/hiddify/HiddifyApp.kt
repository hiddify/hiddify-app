package com.hiddify.hiddify

import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.PowerManager
import android.os.StrictMode
import androidx.core.content.getSystemService
import com.hiddify.hiddify.bg.AppChangeReceiver
import go.Seq
class HiddifyApp : Application() {
    private var appChangeReceiver: AppChangeReceiver? = null

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)

        instance = this
    }

    override fun onCreate() {
        super.onCreate()

        Seq.setContext(this)

        if (BuildConfig.DEBUG) {
            StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder()
                    .detectAll()
                    .penaltyLog()
                    .build()
            )
            StrictMode.setVmPolicy(
                StrictMode.VmPolicy.Builder()
                    .detectLeakedClosableObjects()
                    .penaltyLog()
                    .build()
            )
        }

        appChangeReceiver = AppChangeReceiver()
        registerReceiver(appChangeReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addDataScheme("package")
        })
    }

    override fun onTerminate() {
        super.onTerminate()
        appChangeReceiver?.let {
            runCatching { unregisterReceiver(it) }
        }
        appChangeReceiver = null
    }

    companion object {
        lateinit var instance: HiddifyApp
        val notification by lazy { instance.getSystemService<NotificationManager>()!! }
        val connectivity by lazy { instance.getSystemService<ConnectivityManager>()!! }
        val packageManager by lazy { instance.packageManager }
        val powerManager by lazy { instance.getSystemService<PowerManager>()!! }
        val notificationManager by lazy { instance.getSystemService<NotificationManager>()!! }
    }

}