package com.hiddify.hiddify

import android.util.Log
import androidx.lifecycle.Observer
import com.hiddify.hiddify.constant.Alert
import com.hiddify.hiddify.constant.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMethodCodec

class EventHandler : FlutterPlugin {

    companion object {
        const val TAG = "A/EventHandler"
        const val SERVICE_STATUS = "com.hiddify.app/service.status"
        const val SERVICE_ALERTS = "com.hiddify.app/service.alerts"
    }

    private var statusChannel: EventChannel? = null
    private var alertsChannel: EventChannel? = null

    private var statusObserver: Observer<Status>? = null
    private var alertsObserver: Observer<ServiceEvent?>? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        statusChannel = EventChannel(flutterPluginBinding.binaryMessenger, SERVICE_STATUS, JSONMethodCodec.INSTANCE)
        alertsChannel = EventChannel(flutterPluginBinding.binaryMessenger, SERVICE_ALERTS, JSONMethodCodec.INSTANCE)

        statusChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statusObserver = Observer {
                    Log.d(TAG, "new status: $it")
                    val map = listOf(
                        Pair("status", it.name)
                    )
                        .toMap()
                    events?.success(map)
                }
                MainActivity.instance.serviceStatus.observeForever(statusObserver!!)
            }

            override fun onCancel(arguments: Any?) {
                if (statusObserver != null)
                    MainActivity.instance.serviceStatus.removeObserver(statusObserver!!)
            }
        })

        alertsChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                alertsObserver = Observer {
                    if (it == null) return@Observer
                    Log.d(TAG, "new alert: $it")
                    val map = listOf(
                        Pair("status", it.status.name),
                        Pair("alert", it.alert?.name),
                        Pair("message", it.message)
                    )
                        .mapNotNull { p -> p.second?.let { Pair(p.first, p.second) } }
                        .toMap()
                    events?.success(map)
                }
                MainActivity.instance.serviceAlerts.observeForever(alertsObserver!!)
            }

            override fun onCancel(arguments: Any?) {
                if (alertsObserver != null)
                    MainActivity.instance.serviceAlerts.removeObserver(alertsObserver!!)
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (statusObserver != null)
            MainActivity.instance.serviceStatus.removeObserver(statusObserver!!)
        statusChannel?.setStreamHandler(null)
        if (alertsObserver != null)
            MainActivity.instance.serviceAlerts.removeObserver(alertsObserver!!)
        alertsChannel?.setStreamHandler(null)
    }
}

data class ServiceEvent(val status: Status, val alert: Alert? = null, val message: String? = null)