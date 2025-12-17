package com.hiddify.hiddify.core.service

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.lifecycle.MutableLiveData
import com.hiddify.hiddify.core.HiddifyApp
import com.hiddify.hiddify.ui.MainActivity
import com.hiddify.hiddify.core.model.ServiceEvent
import com.hiddify.hiddify.core.settings.Settings
import com.hiddify.hiddify.core.constant.Alert
import com.hiddify.hiddify.core.constant.Status
import android.net.ConnectivityManager
import java.net.InetSocketAddress
import com.hiddify.hiddify.core.utils.StatsTracker
import com.hiddify.libcore.mobile.Mobile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

abstract class BoxService {

    companion object {
        private const val TAG = "A/BoxService"

        val status = MutableLiveData(Status.Stopped)
        val serviceAlerts = MutableLiveData<ServiceEvent?>(null)
        val logList = mutableListOf<String>()
        var logCallback: ((String) -> Unit)? = null
        
        private var service: BoxService? = null
        
        val isRunning: Boolean
            get() = status.value == Status.Started

        fun start(context: Context) {
            val intent = Intent(context, Settings.serviceClass())
            intent.action = Action.START
            context.startForegroundService(intent)
        }

        fun stop() {
            val svc = service ?: return
            svc.serviceScope.launch {
                svc.stopService()
            }
        }

        fun reload() {
            // Mobile.reload() if available
        }

        fun parseConfig(path: String, tempPath: String, debug: Boolean): String {
            return try {
                Mobile.parseConfig(path, tempPath, debug)
                ""
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse config", e)
                e.message ?: "Unknown error"
            }
        }

        fun buildConfig(path: String, options: String): String {
            return try {
                // Mobile.buildConfig(path, options)
                val content = File(path).readText()
                content // TODO: Apply options
            } catch (e: Exception) {
                Log.e(TAG, "Failed to build config", e)
                throw e
            }
        }
    }

    object Action {
        const val START = "com.hiddify.hiddify.START"
        const val STOP = "com.hiddify.hiddify.STOP"
        const val RECONNECT = "com.hiddify.hiddify.RECONNECT"
    }

    protected val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    protected lateinit var notification: ServiceNotification
    
    abstract fun createService(): Int
    abstract fun destroyService()

    // Abstract methods for PlatformInterface if needed, or removed
    open fun openTun(options: String): Int { return -1 }
    open fun closeTun(fd: Int) {}

    protected fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")
        
        when (intent?.action) {
            Action.START -> {
                serviceScope.launch {
                    startService()
                }
            }
            Action.STOP -> {
                serviceScope.launch {
                    stopService()
                }
            }
            Action.RECONNECT -> {
                serviceScope.launch {
                    reconnectService()
                }
            }
        }
        
        return createService()
    }

    protected fun onCreate() {
        service = this
        notification = ServiceNotification(HiddifyApp.instance)
    }

    protected fun onDestroy() {
        serviceScope.cancel()
        service = null
    }

    private suspend fun startService() {
        if (status.value != Status.Stopped) {
            Log.w(TAG, "Service is not stopped, current status: ${status.value}")
            return
        }

        status.postValue(Status.Starting)

        try {
            val configPath = Settings.activeConfigPath
            if (configPath.isBlank()) {
                serviceAlerts.postValue(ServiceEvent(Status.Stopped, Alert.EmptyConfiguration))
                status.postValue(Status.Stopped)
                return
            }

            val configFile = File(configPath)
            if (!configFile.exists()) {
                serviceAlerts.postValue(ServiceEvent(Status.Stopped, Alert.EmptyConfiguration, "Config file not found"))
                status.postValue(Status.Stopped)
                return
            }

            val configContent = configFile.readText()

            Log.d(TAG, "Starting service with config: $configPath")
            
            try {
                Mobile.start(configContent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create/start box service", e)
                serviceAlerts.postValue(ServiceEvent(Status.Stopped, Alert.CreateService, e.message))
                status.postValue(Status.Stopped)
                return
            }

            Log.d(TAG, "Service started successfully")
            status.postValue(Status.Started)
            
            // Start stats polling
            startStatsPolling()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
            serviceAlerts.postValue(ServiceEvent(Status.Stopped, Alert.StartService, e.message))
            status.postValue(Status.Stopped)
        }
    }

    private fun startStatsPolling() {
        serviceScope.launch {
            while (status.value == Status.Started) {
                delay(1000)
                val uplink = Mobile.getUplink()
                val downlink = Mobile.getDownlink()
                
                if (uplink > 0) StatsTracker.addUplink(uplink)
                if (downlink > 0) StatsTracker.addDownlink(downlink)
                
                notification.update(Settings.activeProfileName, 0, 0) // TODO: track total
            }
        }
    }

    private suspend fun stopService() {
        if (status.value == Status.Stopped) {
            Log.w(TAG, "Service is already stopped")
            return
        }

        status.postValue(Status.Stopping)

        try {
            Mobile.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop box service", e)
        }

        status.postValue(Status.Stopped)
        destroyService()
    }

    private suspend fun reconnectService() {
        stopService()
        delay(500)
        startService()
    }
}
