package com.hiddify.hiddify.bg

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.MutableLiveData
import com.hiddify.hiddify.Application
import com.hiddify.hiddify.R
import com.hiddify.hiddify.Settings
import com.hiddify.hiddify.constant.Action
import com.hiddify.hiddify.constant.Alert
import com.hiddify.hiddify.constant.Status
import com.hiddify.hiddify.utils.DeviceMemory
import com.hiddify.hiddify.utils.GrpcClientProvider
import com.hiddify.core.mobile.SetupOptions

import go.Seq
import com.hiddify.core.libbox.Libbox
import com.hiddify.core.mobile.Mobile
import com.hiddify.core.mobile.CoreStoppedListener


import com.hiddify.core.libbox.CommandServer
import com.hiddify.core.libbox.CommandServerHandler
import com.hiddify.core.libbox.Notification
import com.hiddify.core.libbox.PlatformInterface
import com.hiddify.core.libbox.SystemProxyStatus
import com.hiddify.hiddify.BuildConfig
import com.hiddify.hiddify.MainActivity
import com.hiddify.hiddify.constant.Bugs
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.ensureActive
import kotlin.coroutines.coroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File

class BoxService(
        private val service: Service,
        private val platformInterface: PlatformInterface
)  {

    companion object {
        private const val TAG = "A/BoxService"

        // The running service's platform interface. The core keeps one per process, and the front
        // core's setup would replace it with null, so MethodHandler passes this one instead.
        @Volatile
        var activePlatformInterface: PlatformInterface? = null
            private set

        private var initializeOnce = false
        private lateinit var workingDir: File
        private fun initialize() {
            System.setProperty("GODEBUG", "efence=1,stacktraceback=2");
            System.setProperty("GOGC", "off");
            if (initializeOnce) return
            val baseDir = Application.application.filesDir

            baseDir.mkdirs()
            workingDir = Application.application.getExternalFilesDir(null) ?: return
            workingDir.mkdirs()
            val tempDir = Application.application.cacheDir
            tempDir.mkdirs()
            Log.d(TAG, "base dir: ${baseDir.path}")
            Log.d(TAG, "working dir: ${workingDir.path}")
            Log.d(TAG, "temp dir: ${tempDir.path}")

//
            //Mobile.setup(baseDir.path, workingDir.path, tempDir.path,  2L ,"127.0.0.1:{Setting}","",false,this)
//            Libbox.setup(baseDir.path, workingDir.path, tempDir.path, false)

//            Libbox.setup(SetupOptions().also {
//                it.basePath = baseDir.path
//                it.workingPath = workingDir.path
//                it.tempPath = tempDir.path
//                it.fixAndroidStack = Bugs.fixAndroidStack
//
//            })
            Libbox.redirectStderr(File(Settings.workingDir, "stderr.log").path)
            initializeOnce = true
            return
        }

        /**
         * The start intent's extra: whether the service starts the core itself. A start says it
         * for itself: it was a persisted setting that every entry point had to set (the app
         * cleared it, the tile, the shortcut and always-on set it), and a start that forgot left
         * the service without a core, on "Connecting". A start without the extra is the system's
         * (always-on, a restart), with no app to start the core: the service starts it.
         */
        const val EXTRA_START_CORE = "com.hiddify.app.START_CORE"

        /** Starts the service; [startCore] when no app UI starts the core over gRPC. */
        fun start(startCore: Boolean) {
            val intent = runBlocking {
                withContext(Dispatchers.IO) {
                    Intent(Application.application, Settings.serviceClass())
                }
            }.putExtra(EXTRA_START_CORE, startCore)
            // Android 12+ refuses a foreground start from the background with an exception; the
            // callers (boot receiver, tile, shortcut) have nobody to report it to.
            try {
                ContextCompat.startForegroundService(Application.application, intent)
            } catch (e: Exception) {
                Log.e(TAG, "cannot start the service", e)
            }
        }

        fun stop() {
            Application.application.sendBroadcast(
                    Intent(Action.SERVICE_CLOSE).setPackage(
                            Application.application.packageName
                    )
            )
        }


    }

    var fileDescriptor: ParcelFileDescriptor? = null

    private val status = MutableLiveData(Status.Stopped)
    private val binder = ServiceBinder(status)
    private val notification = ServiceNotification(status, service)
//    private var boxService: BoxService? = null
    private var commandServer: CommandServer? = null
    private var receiverRegistered = false
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Action.SERVICE_CLOSE -> {
                    stopService()
                }

                PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        // a receiver runs on the main thread, and waking the core is a call into it
                        GlobalScope.launch(Dispatchers.IO) { serviceUpdateIdleMode() }
                    }
                }
            }
        }
    }
    


    private var activeProfileName = ""

    /// Mode last passed to Mobile.setup for the VPN gRPC server (2 mTLS / 4 insecure).
    private var grpcSetupMode: Long = 4L

    /** Why a start failed: the alert the app shows. */
    private class StartFailure(val alert: Alert, val message: String?)

    /**
     * Sets the core up and, when asked, starts it; null when it worked. It does not tear down on
     * failure: the caller does (teardown), so a stop and a failed start share one teardown. A stop
     * cancels it, and it checks for that after each call into the core, so a stop during Starting
     * no longer gets Started, a started core and a polling notification after it.
     */
    private suspend fun startService(startCore: Boolean): StartFailure? {
        try {
            // Starting is set by who started this (onStartCommand, a reload), on the main thread:
            // posted from here it could land after a stop's Stopping
            Log.d(TAG, "starting service")
            withContext(Dispatchers.Main) {
                notification.show(activeProfileName, R.string.status_starting)
            }

            val selectedConfigPath = Settings.activeConfigPath
            if (selectedConfigPath.isBlank()) {
                return StartFailure(Alert.EmptyConfiguration, null)
            }

            activeProfileName = Settings.activeProfileName

            withContext(Dispatchers.Main) {
                notification.show(activeProfileName, R.string.status_starting)
                binder.broadcast {
                    it.onServiceResetLogs(listOf())
                }
            }

            DefaultNetworkMonitor.start()
            activePlatformInterface = platformInterface
            // 2 = GRPC_BACKGROUND (mTLS), 4 = GRPC_BACKGROUND_INSECURE. Must match Mobile.close.
            grpcSetupMode = if (GrpcClientProvider.usesMutualTls) 2L else 4L
            try {
                Mobile.setup(
                    SetupOptions().also {
                        it.basePath = Settings.baseDir
                        it.workingDir = Settings.workingDir
                        it.tempDir = Settings.tempDir
                        it.fixAndroidStack = com.hiddify.hiddify.bg.Bugs.fixAndroidStack
                        it.mode = grpcSetupMode
                        it.listen = "127.0.0.1:${Settings.grpcServiceModePort}"
                        it.secret = ""
                        it.debug = Settings.debugMode
                        DeviceMemory.applyTo(it)
                    },
                    platformInterface,
                )
                // the core trusts the client certificate stored in the base folder by itself
                Mobile.setCoreStoppedListener(coreStoppedListener)
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                Log.e(TAG, "Mobile.setup failed", e)
                return StartFailure(Alert.CreateService, e.message ?: e.toString())
            }
            coroutineContext.ensureActive()

            if (startCore) {
                Mobile.start("","")
                coroutineContext.ensureActive()
            }
            withContext(Dispatchers.Main) {
                // on the main thread, where a stop sets Stopping and cancels this start: either
                // the stop came first and this start ends here, or Started comes before Stopping
                coroutineContext.ensureActive()
                status.value = Status.Started
                notification.show(activeProfileName, R.string.status_started)
            }
            notification.start(mutualTls = grpcSetupMode == 2L)
            return null
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            return StartFailure(Alert.StartService, e.message)
        }
    }

    fun serviceReload() {
        runBlocking {
            serviceReload0()
        }
    }

    /** Whether the running start started the core itself: a reload does the same. */
    private var startedCore = false

    suspend fun serviceReload0() {
        notification.close()
        status.postValue(Status.Starting)

        val pfd = fileDescriptor
        if (pfd != null) {
            pfd.close()
            fileDescriptor = null
        }
        
//        boxService?.apply {
//            runCatching {
//                close()
//            }.onFailure {
//                writeLog("service: error when closing: $it")
//            }
//            Seq.destroyRef(refnum)
//        }
        Mobile.stop()
//        boxService = null
        startService(startedCore)?.let { teardown(it) }
    }

    fun getSystemProxyStatus(): SystemProxyStatus {
        val status = SystemProxyStatus()
        if (service is VPNService) {
            status.available = service.systemProxyAvailable
            status.enabled = service.systemProxyEnabled
        }
        return status
    }

    fun setSystemProxyEnabled(isEnabled: Boolean) {
        serviceReload()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun serviceUpdateIdleMode() {
        if (Application.powerManager.isDeviceIdleMode) {
//            boxService?.pause()
            //Mobile.pause()
        } else {
            Mobile.wake()
//            boxService?.wake()
        }
    }

    /**
     * Told by the core when it stops by itself (a start, stop or reload that failed), on a thread
     * of the core's. Only the app saw that, on the core's status stream: with the app closed (a
     * start by always-on, the tile, the shortcut, or the app gone since), the service stayed up,
     * with its TUN and nothing behind it.
     */
    private val coreStoppedListener = object : CoreStoppedListener {
        override fun onCoreStopped(messageType: Int, message: String?) {
            GlobalScope.launch(Dispatchers.Main) { coreStopped(message) }
        }
    }

    /** The core stopped by itself: the service goes down with it, and tells why. Main thread. */
    private fun coreStopped(message: String?) {
        // a start still running reports its own failure; a stop under way is already going down
        if (status.value != Status.Started) return
        Log.w(TAG, "the core stopped by itself: $message")
        status.value = Status.Stopping
        notification.close()
        GlobalScope.launch(Dispatchers.IO) { teardown(StartFailure(Alert.StartService, message)) }
    }

    /** The start in progress; a stop cancels it and waits for it before it tears down. */
    private var startJob: Job? = null

    private fun stopService() {
        if (status.value == Status.Stopped || status.value == Status.Stopping) return
        status.value = Status.Stopping
        notification.close()
        val start = startJob
        GlobalScope.launch(Dispatchers.IO) {
            // a start still calling into the core finishes that call first: closing the core
            // under it raced its setup
            start?.cancelAndJoin()
            teardown(null)
        }
    }

    /**
     * Takes everything down: the receiver, the notification, the TUN, the core and its gRPC
     * servers, the network monitor, and the service. A stop and a failed start both end here; a
     * failed start used to only set Stopped, leaving the core, the TUN and the service up.
     * Running it twice is harmless.
     */
    private suspend fun teardown(failure: StartFailure?) = withContext(NonCancellable) {
        Settings.startedByUser = false
        withContext(Dispatchers.Main) {
            if (receiverRegistered) {
                service.unregisterReceiver(receiver)
                receiverRegistered = false
            }
            notification.close()
        }
        fileDescriptor?.let {
            it.close()
            fileDescriptor = null
        }
        if (activePlatformInterface === platformInterface) activePlatformInterface = null
        Mobile.setCoreStoppedListener(null) // its own close is not a stop to report
        // Close the mode we actually started. Old code always closed 4 (insecure), so
        // mTLS background (mode 2) left :17079 listening and reconnect failed with
        // "background service did not stop".
        // Closing stops the core, which can take seconds: never on the main thread, or the
        // app freezes while it disconnects.
        val closeStart = System.currentTimeMillis()
        for (mode in linkedSetOf(grpcSetupMode, 2L, 4L)) {
            runCatching { Mobile.close(mode) }.onFailure { Log.e(TAG, "closing the core ($mode)", it) }
        }
        Log.i(TAG, "core closed in ${System.currentTimeMillis() - closeStart}ms")
        // after the core: until it is closed it may still ask for the default network
        DefaultNetworkMonitor.stop()
        withContext(Dispatchers.Main) {
            if (failure != null) {
                binder.broadcast { callback ->
                    callback.onServiceAlert(failure.alert.ordinal, failure.message)
                }
            }
            status.value = Status.Stopped
            notification.close()
            service.stopSelf()
        }
    }

    @OptIn(DelicateCoroutinesApi::class)
    @Suppress("SameReturnValue")
    internal fun onStartCommand(intent: Intent?): Int {
        val startCore = intent?.getBooleanExtra(EXTRA_START_CORE, true) ?: true
        // Already up, and in the foreground: ignore duplicate start intents.
        if (status.value == Status.Started) {
            return Service.START_NOT_STICKY
        }
        // Every start comes through startForegroundService, and Android kills the app ("did not
        // then call Service.startForeground()") when the service stops, or 10 seconds pass,
        // before startForeground is called. So go to the foreground here, on the main thread,
        // before anything slow (loading the core at boot) and before the returns below: a start
        // that arrives while a stop is still closing the core used to return without it, and
        // the stop's stopSelf() then crashed the app.
        try {
            notification.show(activeProfileName, R.string.status_starting)
        } catch (e: Exception) {
            Log.e(TAG, "cannot go to the foreground", e)
        }
        if (status.value == Status.Starting) {
            return Service.START_NOT_STICKY
        }
        // A stop is still tearing down Mobile/VPN; wait then start so reconnect
        // after disconnect does not hit CreateService from a raced Mobile.setup.
        if (status.value == Status.Stopping) {
            GlobalScope.launch(Dispatchers.IO) {
                var i = 0
                while (status.value == Status.Stopping && i < 50) {
                    delay(200)
                    i++
                }
                if (status.value == Status.Stopped) start(startCore)
            }
            return Service.START_NOT_STICKY
        }
        status.value = Status.Starting

        if (!receiverRegistered) {
            ContextCompat.registerReceiver(service, receiver, IntentFilter().apply {
                addAction(Action.SERVICE_CLOSE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
                }
            }, ContextCompat.RECEIVER_NOT_EXPORTED)
            receiverRegistered = true
        }

        startJob = GlobalScope.launch(Dispatchers.IO) {
            Settings.startedByUser = true
            initialize()
            startedCore = startCore
            startService(startCore)?.let { teardown(it) }
        }
        return Service.START_NOT_STICKY
    }

    fun onBind(intent: Intent): IBinder {
        return binder
    }

    fun onDestroy() {
        if (activePlatformInterface === platformInterface) activePlatformInterface = null
        binder.close()
    }

    fun onRevoke() {
        stopService()
    }

    internal fun sendNotification(notification: Notification) {
        return
        val builder =
            NotificationCompat.Builder(service, notification.identifier).setShowWhen(false)
                .setContentTitle(notification.title).setContentText(notification.body)
                .setOnlyAlertOnce(true).setSmallIcon(R.drawable.ic_launcher_foreground)
                .setCategory(NotificationCompat.CATEGORY_EVENT)
                .setPriority(NotificationCompat.PRIORITY_HIGH).setAutoCancel(true)
        if (!notification.subtitle.isNullOrBlank()) {
            builder.setContentInfo(notification.subtitle)
        }
        if (!notification.openURL.isNullOrBlank()) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    service,
                    0,
                    Intent(
                        service,
                        MainActivity::class.java,
                    ).apply {
                        setAction(Action.SERVICE).setData(Uri.parse(notification.openURL))
                        setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                    },
                    ServiceNotification.flags,
                ),
            )
        }
        GlobalScope.launch(Dispatchers.Main) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Application.notification.createNotificationChannel(
                    NotificationChannel(
                        notification.identifier,
                        notification.typeName,
                        NotificationManager.IMPORTANCE_HIGH,
                    ),
                )
            }
            Application.notification.notify(notification.identifier, notification.typeID, builder.build())
        }
    }

    internal fun cancelNotification(identifier: String, typeID: Int) {
        GlobalScope.launch(Dispatchers.Main) {
            Application.notification.cancel(identifier, typeID)
        }
    }

     fun writeDebugMessage(message: String?) {
        Log.d("BoxService", message!!)
        binder.broadcast {
            it.onServiceWriteLog(message)
        }
    }

}