package com.hiddify.hiddify.bg

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import android.os.Build
import android.util.Log
import androidx.annotation.StringRes
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.app.ServiceCompat
import androidx.lifecycle.MutableLiveData
import com.hiddify.core.api.v2.hcommon.Empty
import com.hiddify.core.api.v2.hcore.CoreClient
import com.hiddify.core.api.v2.hcore.SystemInfo
import com.hiddify.hiddify.Application
import com.hiddify.hiddify.MainActivity
import com.hiddify.hiddify.R
import com.hiddify.hiddify.Settings
import com.hiddify.hiddify.constant.Action
import com.hiddify.hiddify.constant.Status
import com.hiddify.core.libbox.Libbox
import com.hiddify.hiddify.utils.GrpcClientProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.withContext
class ServiceNotification(private val status: MutableLiveData<Status>, private val service: Service) : BroadcastReceiver() {
    companion object {
        private const val notificationId = 1
        private const val notificationChannel = "service"
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        fun checkPermission(): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                return true
            }
            return Application.notification.areNotificationsEnabled()
        }
    }
    private val scope = CoroutineScope(Dispatchers.Main.immediate + SupervisorJob())
    private var receiverRegistered = false
    private val lifecycleVersion = AtomicLong()
    private var staticContentTextId = R.string.status_started
    private var screenOn = true
    private var coreClient: CoreClient? = null
    private val clientLock = Any()
    private val refreshController = NotificationRefreshController(
        scope = scope,
        fetch = {
            withContext(Dispatchers.IO) {
                val client = synchronized(clientLock) {
                    coreClient ?: GrpcClientProvider.grpcClient.create(CoreClient::class).also { coreClient = it }
                }
                client.GetSystemInfo().executeBlocking(Empty())
            }
        },
        publish = { previous: SystemInfo?, current: SystemInfo -> updateStatus(previous, current) },
        onError = { error ->
            synchronized(clientLock) { coreClient = null }
            Log.d("notification", "SystemInfo not available: ${error.message}")
        },
    )

    private val notificationBuilder by lazy {
        NotificationCompat.Builder(service, notificationChannel)
                .setShowWhen(false)
                .setOngoing(true)
                .setContentTitle("Hiddify")
                .setOnlyAlertOnce(true)
                .setSmallIcon(R.drawable.ic_stat_logo)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setContentIntent(
                        PendingIntent.getActivity(
                                service,
                                0,
                                Intent(
                                        service,
                                        MainActivity::class.java
                                ).setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
                                flags
                        )
                )
                .setPriority(NotificationCompat.PRIORITY_LOW).apply {
                    addAction(
                            NotificationCompat.Action.Builder(
                                    0, service.getText(R.string.stop), PendingIntent.getBroadcast(
                                    service,
                                    0,
                                    Intent(Action.SERVICE_CLOSE).setPackage(
                                        Application.application.packageName
                                    ),
                                    flags
                            )
                            ).build()
                    )
                }
    }

    fun show(profileName: String, @StringRes contentTextId: Int) {
        lifecycleVersion.incrementAndGet()
        staticContentTextId = contentTextId
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Application.notification.createNotificationChannel(
                NotificationChannel(
                    notificationChannel, "hiddify service", NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        service.startForeground(
            notificationId, notificationBuilder
                .setContentTitle(profileName.takeIf { it.isNotBlank() } ?: "Hiddify")
                .setContentText(service.getString(contentTextId)).build()
        )
    }


    suspend fun start() = withContext(Dispatchers.Main.immediate) {
        refreshController.start()
        screenOn = (service.getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
        if (!receiverRegistered) {
            ContextCompat.registerReceiver(service, this@ServiceNotification, IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Action.SERVICE_REFRESH_NOTIFICATION)
            }, ContextCompat.RECEIVER_NOT_EXPORTED)
            receiverRegistered = true
        }
        if (Settings.dynamicNotification && checkPermission() && screenOn) {
            refreshController.refresh(periodic = true)
        }
    }

    private fun updateStatus(previous: SystemInfo?, current: SystemInfo) {
        val content = if (Settings.dynamicNotification) {
            val uplink = previous?.let { (current.uplink_total - it.uplink_total).coerceAtLeast(0) } ?: 0L
            val downlink = previous?.let { (current.downlink_total - it.downlink_total).coerceAtLeast(0) } ?: 0L
            "${Libbox.formatBytes(uplink)}/s ↑\t${Libbox.formatBytes(downlink)}/s ↓ \n${current.current_outbound}"
        } else {
            service.getString(staticContentTextId)
        }
        Application.notificationManager.notify(
            notificationId,
            notificationBuilder
                .setContentTitle(current.current_profile.takeIf { it.isNotBlank() } ?: "Hiddify")
                .setContentText(content).build()
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                screenOn = true
                if (checkPermission()) refreshController.refresh(periodic = Settings.dynamicNotification)
            }
            Intent.ACTION_SCREEN_OFF -> {
                screenOn = false
                refreshController.pause()
            }
            Action.SERVICE_REFRESH_NOTIFICATION -> {
                if (checkPermission()) {
                    refreshController.refresh(periodic = Settings.dynamicNotification && screenOn)
                }
            }
        }
    }

    fun close() {
        // Invalidate work immediately, even when BoxService closes from its IO dispatcher.
        val closingVersion = lifecycleVersion.incrementAndGet()
        refreshController.close()
        synchronized(clientLock) { coreClient = null }
        scope.launch {
            if (lifecycleVersion.get() != closingVersion) return@launch
            ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
            if (receiverRegistered) {
                service.unregisterReceiver(this@ServiceNotification)
                receiverRegistered = false
            }
        }
    }
}
