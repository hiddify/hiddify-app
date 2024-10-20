package com.hiddify.hiddify

import android.util.Log
import com.hiddify.hiddify.utils.CommandClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMethodCodec
import com.hiddify.core.libbox.StatusMessage
import kotlinx.coroutines.CoroutineScope

class StatsChannel(private val scope: CoroutineScope) : FlutterPlugin, CommandClient.Handler{
    companion object {
        const val TAG = "A/StatsChannel"
        const val STATS_CHANNEL = "com.hiddify.app/stats"
    }

    private val commandClient =
            CommandClient(scope, CommandClient.ConnectionType.Status, this)

    private var statsChannel: EventChannel? = null
    private var statsEvent: EventChannel.EventSink? = null

    override fun updateStatus(status: StatusMessage) {
        MainActivity.instance.runOnUiThread {
            val map = listOf(
                    Pair("connections-in", status.connectionsIn),
                    Pair("connections-out", status.connectionsOut),
                    Pair("uplink", status.uplink),
                    Pair("downlink", status.downlink),
                    Pair("uplink-total", status.uplinkTotal),
                    Pair("downlink-total", status.downlinkTotal)
            ).associate { it.first to it.second }
            statsEvent?.success(map)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        statsChannel = EventChannel(
                flutterPluginBinding.binaryMessenger,
                STATS_CHANNEL,
                JSONMethodCodec.INSTANCE
        )

        statsChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statsEvent = events
                Log.d(TAG, "connecting stats command client")
                commandClient.connect()
            }

            override fun onCancel(arguments: Any?) {
                statsEvent = null
                Log.d(TAG, "disconnecting stats command client")
                commandClient.disconnect()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        statsEvent = null
        commandClient.disconnect()
        statsChannel?.setStreamHandler(null)
    }
}