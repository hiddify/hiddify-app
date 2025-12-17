package com.hiddify.hiddify.core.service

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection as AndroidServiceConnection
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.hiddify.hiddify.core.settings.Settings
import com.hiddify.hiddify.core.constant.Status

/**
 * Helper class for connecting to BoxService and observing its status
 */
class ServiceConnection(
    private val context: Context,
    private val callback: Callback,
    private val register: Boolean = true
) : AndroidServiceConnection {

    companion object {
        private const val TAG = "A/ServiceConnection"
    }

    interface Callback {
        fun onServiceStatusChanged(status: Status)
        fun onServiceConnected() {}
        fun onServiceDisconnected() {}
    }

    private var statusObserver: Observer<Status>? = null
    private var connected = false

    fun connect() {
        if (connected) return
        
        Log.d(TAG, "Connecting to service")
        statusObserver = Observer { status ->
            Log.d(TAG, "Service status changed: $status")
            callback.onServiceStatusChanged(status)
        }
        BoxService.status.observeForever(statusObserver!!)
        if (register) {
            try {
                val intent = Intent(context, Settings.serviceClass())
                context.bindService(intent, this, Context.BIND_AUTO_CREATE)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to bind service", e)
            }
        }
        
        connected = true
        BoxService.status.value?.let {
            callback.onServiceStatusChanged(it)
        }
    }

    fun disconnect() {
        if (!connected) return
        
        Log.d(TAG, "Disconnecting from service")
        
        statusObserver?.let {
            BoxService.status.removeObserver(it)
        }
        statusObserver = null
        
        if (register) {
            try {
                context.unbindService(this)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to unbind service", e)
            }
        }
        
        connected = false
    }

    override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
        Log.d(TAG, "Service connected: $name")
        callback.onServiceConnected()
    }

    override fun onServiceDisconnected(name: ComponentName?) {
        Log.d(TAG, "Service disconnected: $name")
        callback.onServiceDisconnected()
    }
}
