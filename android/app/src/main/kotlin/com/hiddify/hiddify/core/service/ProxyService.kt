package com.hiddify.hiddify.core.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import com.hiddify.hiddify.core.settings.Settings

class ProxyService : Service() {

    companion object {
        private const val TAG = "A/ProxyService"
    }

    private var boxService: BoxServiceWrapper? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "ProxyService onCreate")
        boxService = BoxServiceWrapper(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ProxyService onStartCommand: ${intent?.action}")
        boxService?.handleStartCommand(intent, flags, startId)
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "ProxyService onDestroy")
        boxService?.handleDestroy()
        boxService = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    inner class BoxServiceWrapper(private val proxyService: ProxyService) : BoxService() {
        
        override fun createService(): Int {
            val notification = this.notification
            proxyService.startForeground(
                ServiceNotification.NOTIFICATION_ID,
                notification.build(Settings.activeProfileName)
            )
            return START_STICKY
        }

        override fun destroyService() {
            proxyService.stopForeground(STOP_FOREGROUND_REMOVE)
            proxyService.stopSelf()
        }
        
        fun handleStartCommand(intent: Intent?, flags: Int, startId: Int) {
            // BoxService handles lifecycle internally
        }
        
        fun handleDestroy() {
            // BoxService handles lifecycle internally
        }
    }
}
