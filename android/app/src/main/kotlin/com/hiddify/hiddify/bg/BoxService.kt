package com.hiddify.hiddify.bg

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.lifecycle.MutableLiveData
import com.hiddify.hiddify.Application
import com.hiddify.hiddify.R
import com.hiddify.hiddify.Settings
import com.hiddify.hiddify.constant.Action
import com.hiddify.hiddify.constant.Alert
import com.hiddify.hiddify.constant.Status
import go.Seq
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.SystemProxyStatus
import io.nekohasekai.mobile.Mobile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File

class BoxService(
        private val service: Service,
        private val platformInterface: PlatformInterface
) : CommandServerHandler {

    companion object {
        private const val TAG = "A/BoxService"
        private const val COMMAND_SERVER_TIMEOUT = 3600 // افزایش timeout به 1 ساعت

        private var initializeOnce = false
        private lateinit var workingDir: File
        private var serviceStartTime: Long = 0
        
        private fun initialize() {
            if (initializeOnce) return
            val baseDir = Application.application.filesDir
            
            baseDir.mkdirs()
            val externalFilesDir = Application.application.getExternalFilesDir(null)
            if (externalFilesDir == null) {
                Log.e(TAG, "External storage is unavailable. Using internal storage as fallback.")
                workingDir = File(baseDir, "working")
                workingDir.mkdirs()
            } else {
                workingDir = externalFilesDir
                workingDir.mkdirs()
            }
            val tempDir = Application.application.cacheDir
            tempDir.mkdirs()
            Log.d(TAG, "base dir: ${baseDir.path}")
            Log.d(TAG, "working dir: ${workingDir.path}")
            Log.d(TAG, "temp dir: ${tempDir.path}")
            
            Mobile.setup(baseDir.path, workingDir.path, tempDir.path, false)
            Libbox.redirectStderr(File(workingDir, "stderr.log").path)
            initializeOnce = true
            return
        }

        fun parseConfig(path: String, tempPath: String, debug: Boolean): String {
            return try {
                Mobile.parse(path, tempPath, debug)
                ""
            } catch (e: Exception) {
                Log.w(TAG, e)
                e.message ?: "invalid config"
            }
        }

        fun buildConfig(path: String, options: String): String {
            return Mobile.buildConfig(path, options)
        }

        fun start() {
            val intent = runBlocking {
                withContext(Dispatchers.IO) {
                    Intent(Application.application, Settings.serviceClass())
                }
            }
            ContextCompat.startForegroundService(Application.application, intent)
        }

        fun stop() {
            Application.application.sendBroadcast(
                    Intent(Action.SERVICE_CLOSE).setPackage(
                            Application.application.packageName
                    )
            )
        }

        fun reload() {
            Application.application.sendBroadcast(
                    Intent(Action.SERVICE_RELOAD).setPackage(
                            Application.application.packageName
                    )
            )
        }
    }

    var fileDescriptor: ParcelFileDescriptor? = null

    private val status = MutableLiveData(Status.Stopped)
    private val binder = ServiceBinder(status)
    private val notification = ServiceNotification(status, service)
    private var boxService: BoxService? = null
    private var commandServer: CommandServer? = null
    private var receiverRegistered = false
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Action.SERVICE_CLOSE -> {
                    stopService()
                }

                Action.SERVICE_RELOAD -> {
                    serviceReload()
                }

                PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        serviceUpdateIdleMode()
                    }
                }
            }
        }
    }

    private fun startCommandServer() {
        val commandServer =
                CommandServer(this, COMMAND_SERVER_TIMEOUT)
        commandServer.start()
        this.commandServer = commandServer
        Log.d(TAG, "CommandServer started with timeout: $COMMAND_SERVER_TIMEOUT seconds")
    }

    private var activeProfileName = ""
    private suspend fun startService(delayStart: Boolean = false) {
        try {
            serviceStartTime = System.currentTimeMillis()
            Log.d(TAG, "=== SERVICE START DIAGNOSTICS ===")
            Log.d(TAG, "Time: $serviceStartTime")
            Log.d(TAG, "Battery: ${getBatteryLevel()}%")
            Log.d(TAG, "Network: ${getNetworkType()}")
            Log.d(TAG, "Doze: ${isDozeMode()}")
            Log.d(TAG, "Available Memory: ${getAvailableMemoryMB()}MB")
            Log.d(TAG, "===================================")
            
            Log.d(TAG, "starting service")
            withContext(Dispatchers.Main) {
                notification.show(activeProfileName, R.string.status_starting)
            }

            val selectedConfigPath = Settings.activeConfigPath
            if (selectedConfigPath.isBlank()) {
                stopAndAlert(Alert.EmptyConfiguration)
                return
            }

            activeProfileName = Settings.activeProfileName

            val configOptions = Settings.configOptions
            if (configOptions.isBlank()) {
                stopAndAlert(Alert.EmptyConfiguration)
                return
            }

            val content = try {
                Mobile.buildConfig(selectedConfigPath, configOptions)
            } catch (e: Exception) {
                Log.w(TAG, e)
                stopAndAlert(Alert.EmptyConfiguration)
                return
            }

            if (Settings.debugMode) {
                File(workingDir, "current-config.json").writeText(content)
            }

            withContext(Dispatchers.Main) {
                notification.show(activeProfileName, R.string.status_starting)
                binder.broadcast {
                    it.onServiceResetLogs(listOf())
                }
            }

            DefaultNetworkMonitor.start()
            Libbox.registerLocalDNSTransport(LocalResolver)
            Libbox.setMemoryLimit(!Settings.disableMemoryLimit)

            val newService = try {
                Libbox.newService(content, platformInterface)
            } catch (e: Exception) {
                stopAndAlert(Alert.CreateService, e.message)
                return
            }

            if (delayStart) {
                delay(1000L)
            }

            newService.start()
            boxService = newService
            commandServer?.setService(boxService)
            
            // تنظیم listener برای network monitoring
            DefaultNetworkMonitor.setListener(newService)
            
            status.postValue(Status.Started)

            withContext(Dispatchers.Main) {
                notification.show(activeProfileName, R.string.status_started)
            }
            notification.start()
            Log.d(TAG, "Service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
            stopAndAlert(Alert.StartService, e.message)
            return
        }
    }

    override fun serviceReload() {
        Log.d(TAG, "Service reload requested")
        notification.close()
        status.postValue(Status.Starting)
        
        // استفاده از coroutine به جای runBlocking برای جلوگیری از ANR
        GlobalScope.launch(Dispatchers.IO) {
            try {
                // Close existing file descriptor
                val pfd = fileDescriptor
                if (pfd != null) {
                    pfd.close()
                    fileDescriptor = null
                }
                
                // Detach command server
                commandServer?.setService(null)
                
                // Close and cleanup box service
                boxService?.apply {
                    runCatching {
                        close()
                    }.onFailure {
                        writeLog("service: error when closing: $it")
                        Log.e(TAG, "Error closing box service", it)
                    }
                    Seq.destroyRef(refnum)
                }
                boxService = null
                
                // Wait a bit before restart to ensure cleanup
                delay(1000)
                
                Log.d(TAG, "Starting service after reload")
                // Restart service
                startService(delayStart = true)
            } catch (e: Exception) {
                Log.e(TAG, "Error during service reload", e)
                stopAndAlert(Alert.StartService, "Reload failed: ${e.message}")
            }
        }
    }

    override fun getSystemProxyStatus(): SystemProxyStatus {
        val status = SystemProxyStatus()
        if (service is VPNService) {
            status.available = service.systemProxyAvailable
            status.enabled = service.systemProxyEnabled
        }
        return status
    }

    override fun setSystemProxyEnabled(isEnabled: Boolean) {
        serviceReload()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun serviceUpdateIdleMode() {
        val isIdle = Application.powerManager.isDeviceIdleMode
        Log.d(TAG, "Device idle mode changed: $isIdle")
        
        try {
            if (isIdle) {
                Log.d(TAG, "Device entering idle mode, pausing service")
                boxService?.pause()
            } else {
                Log.d(TAG, "Device exiting idle mode, waking service")
                boxService?.wake()
                
                // Verification: check if connection is working after wake
                GlobalScope.launch(Dispatchers.IO) {
                    delay(2000) // Wait 2 seconds for wake to complete
                    
                    if (!verifyConnectionHealth()) {
                        Log.w(TAG, "Connection verification failed after wake, reloading service")
                        serviceReload()
                    } else {
                        Log.d(TAG, "Connection verified successfully after wake")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling idle mode change", e)
            // Attempt service reload if wake/pause fails
            serviceReload()
        }
    }
    
    private suspend fun verifyConnectionHealth(): Boolean {
        return try {
            // بررسی اینکه service هنوز زنده است
            val service = boxService
            if (service == null) {
                Log.w(TAG, "Box service is null during health check")
                return false
            }
            
            // بررسی اینکه status هنوز Started است
            if (status.value != Status.Started) {
                Log.w(TAG, "Service status is not Started: ${status.value}")
                return false
            }
            
            // می‌توانیم اینجا چک‌های بیشتری اضافه کنیم
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error verifying connection health", e)
            false
        }
    }

    private fun stopService() {
        if (status.value != Status.Started) return
        status.value = Status.Stopping
        if (receiverRegistered) {
            service.unregisterReceiver(receiver)
            receiverRegistered = false
        }
        notification.close()
        GlobalScope.launch(Dispatchers.IO) {
            val pfd = fileDescriptor
            if (pfd != null) {
                pfd.close()
                fileDescriptor = null
            }
            commandServer?.setService(null)
            boxService?.apply {
                runCatching {
                    close()
                }.onFailure {
                    writeLog("service: error when closing: $it")
                }
                Seq.destroyRef(refnum)
            }
            boxService = null
            Libbox.registerLocalDNSTransport(null)
            DefaultNetworkMonitor.stop()

            commandServer?.apply {
                close()
                Seq.destroyRef(refnum)
            }
            commandServer = null
            Settings.startedByUser = false
            withContext(Dispatchers.Main) {
                status.value = Status.Stopped
                service.stopSelf()
            }
        }
    }
    override fun postServiceClose() {
        // Not used on Android
    }

    private suspend fun stopAndAlert(type: Alert, message: String? = null) {
        Settings.startedByUser = false
        withContext(Dispatchers.Main) {
            if (receiverRegistered) {
                service.unregisterReceiver(receiver)
                receiverRegistered = false
            }
            notification.close()
            binder.broadcast { callback ->
                callback.onServiceAlert(type.ordinal, message)
            }
            status.value = Status.Stopped
        }
    }

    fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (status.value != Status.Stopped) return Service.START_NOT_STICKY
        status.value = Status.Starting

        if (!receiverRegistered) {
            ContextCompat.registerReceiver(service, receiver, IntentFilter().apply {
                addAction(Action.SERVICE_CLOSE)
                addAction(Action.SERVICE_RELOAD)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
                }
            }, ContextCompat.RECEIVER_NOT_EXPORTED)
            receiverRegistered = true
        }

        GlobalScope.launch(Dispatchers.IO) {
            Settings.startedByUser = true
            initialize()
            try {
                startCommandServer()
            } catch (e: Exception) {
                stopAndAlert(Alert.StartCommandServer, e.message)
                return@launch
            }
            startService()
        }
        return Service.START_NOT_STICKY
    }

    fun onBind(intent: Intent): IBinder {
        return binder
    }

    fun onDestroy() {
        binder.close()
    }

    fun onRevoke() {
        stopService()
    }

    fun writeLog(message: String) {
        binder.broadcast {
            it.onServiceWriteLog(message)
        }
    }
    
    // Helper methods for diagnostics
    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = Application.application.getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
            batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (e: Exception) {
            -1
        }
    }
    
    private fun getNetworkType(): String {
        return try {
            val network = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Application.connectivity.activeNetwork
            } else {
                return "Unknown"
            }
            
            if (network == null) {
                return "No Network"
            }
            
            val capabilities = Application.connectivity.getNetworkCapabilities(network)
            when {
                capabilities == null -> "Unknown"
                capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) -> "WiFi"
                capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR) -> "Mobile"
                capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
                else -> "Other"
            }
        } catch (e: Exception) {
            "Error"
        }
    }
    
    private fun isDozeMode(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Application.powerManager.isDeviceIdleMode
        } else {
            false
        }
    }
    
    private fun getAvailableMemoryMB(): Long {
        return try {
            val activityManager = Application.application.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val memInfo = android.app.ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            memInfo.availMem / (1024 * 1024) // Convert to MB
        } catch (e: Exception) {
            -1
        }
    }

}