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
import com.hiddify.core.api.v2.config.Protocol
import com.hiddify.core.api.v2.hcommon.Empty
import com.hiddify.core.api.v2.hcore.CoreClient
import com.hiddify.core.api.v2.hcore.SystemInfo
import com.hiddify.hiddify.Application
import com.hiddify.hiddify.MainActivity
import com.hiddify.hiddify.R
import com.hiddify.hiddify.Settings
import com.hiddify.hiddify.constant.Action
import com.hiddify.hiddify.constant.Status
//import com.hiddify.hiddify.utils.CommandClient
import com.hiddify.core.libbox.Libbox
import com.hiddify.hiddify.Application.Companion.notification
import com.hiddify.hiddify.utils.GrpcClientProvider
import com.squareup.wire.GrpcClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.channels.SendChannel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import java.io.IOException

class ServiceNotification(private val status: MutableLiveData<Status>, private val service: Service) : BroadcastReceiver(){
    companion object {
        private const val notificationId = 1
        private const val notificationChannel = "service"
        var coreClient: CoreClient?=null
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        fun checkPermission(): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                return true
            }
            return Application.notification.areNotificationsEnabled()
        }
    }
    val streamingCoroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())


//
//    private val commandClient =
//            CommandClient(GlobalScope, CommandClient.ConnectionType.Status, this)
    private var receiverRegistered = false


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
                                    Intent(Action.SERVICE_CLOSE).setPackage(service.packageName),
                                    flags
                            )
                            ).build()
                    )
                }
    }

    fun show(profileName: String, @StringRes contentTextId: Int) {
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


    suspend fun start() {
        if (Settings.dynamicNotification && checkPermission()) {
//            commandClient.connect()
            startListenSystemInfo()
            withContext(Dispatchers.Main) {
                registerReceiver()
            }
        }
    }

    private fun registerReceiver() {
        service.registerReceiver(this, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        })
        receiverRegistered = true
    }

    fun updateStatus(status: SystemInfo) {
        val content = "${Libbox.formatBytes(status.uplink)}/s ↑\t${Libbox.formatBytes(status.downlink)}/s ↓ \n${status.current_outbound}"
        val title = "${status.current_profile}"
        Application.notificationManager.notify(
                notificationId,
                notificationBuilder.setContentTitle(title).setContentText(content).build()
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                startListenSystemInfo()
            }

            Intent.ACTION_SCREEN_OFF -> {
                stopListenSystemInfo()
            }
        }
    }

    fun close() {
        stopListenSystemInfo()
        ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
        if (receiverRegistered) {
            service.unregisterReceiver(this)
            receiverRegistered = false
        }
    }

    private var streamingJob: Job? = null

    fun startListenSystemInfo() {
        // Cancel any previous stream if still running
        streamingJob?.cancel()

        streamingJob = streamingCoroutineScope.launch {
            try {
                val coreClient = GrpcClientProvider.grpcClient.create(CoreClient::class)

                val (sendCommandChannel, receiveUpdateChannel) = coreClient.GetSystemInfo().executeIn(this)

                // Send initial command
                sendCommandChannel.send(Empty())

                // Consume incoming updates
                for (update in receiveUpdateChannel) {
                    updateStatus(update)
                }

                // When the stream ends normally, cancel notification
                notification.cancel(notificationId)

            } catch (e: Exception) {
                Log.d("notification", "Exception: $e")
            }
        }
    }
    fun stopListenSystemInfo(){
        try {
            streamingJob?.cancel()
        }catch (e: Exception){
            Log.d("notification", "Exception ${e}")
        }
    }
}