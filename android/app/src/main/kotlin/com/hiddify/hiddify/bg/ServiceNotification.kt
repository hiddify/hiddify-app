package com.hiddify.hiddify.bg

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import androidx.annotation.StringRes
import androidx.core.app.NotificationCompat
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
import com.hiddify.hiddify.constant.ServiceMode
import com.hiddify.hiddify.constant.Status
import com.hiddify.core.libbox.Libbox
import com.hiddify.hiddify.utils.GrpcClientProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive

import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.CancellationException
/**
 * The persistent notification of the running service.
 *
 * Title: the active profile. Text: the outbound in use, prefixed with the live speed when
 * "Display speed in notification" is on. Header: VPN or Proxy. Everything comes from the core
 * (SystemInfo), so a profile or outbound switched while connected shows up within one poll.
 * Polling stops while the screen is off and nothing is re-posted when nothing changed.
 */
class ServiceNotification(private val status: MutableLiveData<Status>, private val service: Service) : BroadcastReceiver() {
    companion object {
        private const val notificationId = 1
        private const val notificationChannel = "service"
        private const val speedInterval = 1_000L
        private const val idleInterval = 5_000L
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        fun checkPermission(): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                return true
            }
            return Application.notification.areNotificationsEnabled()
        }
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var pollJob: Job? = null
    private var receiverRegistered = false

    /** What is on screen right now (title, text, header); an unchanged refresh is skipped. */
    private var shown: Triple<String, String, String>? = null

    private val modeLabel: String
        get() = service.getString(
            if (Settings.serviceMode == ServiceMode.VPN) R.string.mode_vpn else R.string.mode_proxy
        )

    private val notificationBuilder by lazy {
        NotificationCompat.Builder(service, notificationChannel)
            .setShowWhen(false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSmallIcon(R.drawable.ic_stat_logo)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(
                PendingIntent.getActivity(
                    service,
                    0,
                    Intent(service, MainActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
                    flags
                )
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                NotificationCompat.Action.Builder(
                    0, service.getText(R.string.stop), PendingIntent.getBroadcast(
                        service,
                        0,
                        Intent(Action.SERVICE_CLOSE).setPackage(Application.application.packageName),
                        flags
                    )
                ).build()
            )
    }

    /** Puts the service in the foreground with a static status line (starting / connected). */
    fun show(profileName: String, @StringRes contentTextId: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Application.notification.createNotificationChannel(
                NotificationChannel(notificationChannel, "hiddify service", NotificationManager.IMPORTANCE_LOW)
            )
        }
        render(profileName, service.getString(contentTextId), modeLabel, foreground = true)
    }

    private fun render(profile: String, text: String, header: String, foreground: Boolean = false) {
        val next = Triple(profile.ifBlank { "Hiddify" }, text, header)
        if (!foreground && next == shown) return
        shown = next
        val built = notificationBuilder
            .setContentTitle(next.first)
            .setContentText(next.second)
            .setSubText(next.third)
            .build()
        if (foreground) service.startForeground(notificationId, built)
        else Application.notification.notify(notificationId, built)
    }

    suspend fun start() {
        if (!checkPermission()) return
        startPolling()
        withContext(Dispatchers.Main) { registerReceiver() }
    }

    private fun registerReceiver() {
        service.registerReceiver(this, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        })
        receiverRegistered = true
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> startPolling()
            Intent.ACTION_SCREEN_OFF -> stopPolling()
        }
    }

    fun close() {
        stopPolling()
        shown = null
        ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
        if (receiverRegistered) {
            service.unregisterReceiver(this)
            receiverRegistered = false
        }
    }

    private fun startPolling() {
        pollJob?.cancel()
        val showSpeed = Settings.dynamicNotification
        val interval = if (showSpeed) speedInterval else idleInterval
        pollJob = scope.launch {
            val coreClient = GrpcClientProvider.grpcClient.create(CoreClient::class)
            var previous: SystemInfo? = null
            while (isActive) {
                try {
                    val info = coreClient.GetSystemInfo().executeBlocking(Empty())
                    update(previous, info, showSpeed)
                    previous = info
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // The service reports Started before the core listens; keep trying.
                    Log.d("notification", "SystemInfo not available yet: ${e.message}")
                    previous = null
                }
                delay(interval)
            }
        }
    }

    private fun stopPolling() {
        pollJob?.cancel()
        pollJob = null
    }

    private fun update(previous: SystemInfo?, info: SystemInfo, showSpeed: Boolean) {
        val outbound = info.current_outbound.ifBlank { service.getString(R.string.status_started) }
        val text = if (showSpeed && previous != null) {
            val up = Libbox.formatBytes(info.uplink_total - previous.uplink_total)
            val down = Libbox.formatBytes(info.downlink_total - previous.downlink_total)
            "$outbound  ·  ↑ $up/s  ↓ $down/s"
        } else {
            outbound
        }
        render(info.current_profile, text, modeLabel)
    }
}
