package com.hiddify.hiddify.bg

import android.app.Service
import android.content.Intent

class ProxyService : Service(), PlatformInterfaceWrapper {

    private val service = BoxService(this, this)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int) =
        service.onStartCommand(intent, flags, startId)

    override fun onBind(intent: Intent) = service.onBind(intent)
    override fun onDestroy() = service.onDestroy()

    override fun writeLog(message: String) = service.writeLog(message)
}