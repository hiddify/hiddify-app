package com.hiddify.hiddify.core.channel

import android.util.Log
import com.google.gson.Gson
import com.hiddify.hiddify.core.utils.CommandClient
import com.hiddify.hiddify.core.utils.ParsedOutboundGroup
import com.hiddify.hiddify.ui.MainActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import com.hiddify.hiddify.core.model.OutboundGroup
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob


class ActiveGroupsChannel : FlutterPlugin, CommandClient.Handler {
    companion object {
        const val TAG = "A/ActiveGroupsChannel"
        const val CHANNEL = "com.hiddify.app/active-groups"
        val gson = Gson()
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val client by lazy {
        CommandClient(scope, CommandClient.ConnectionType.GroupOnly, this)
    }

    private var channel: EventChannel? = null
    private var event: EventChannel.EventSink? = null

    override fun updateGroups(groups: List<OutboundGroup>) {
        MainActivity.instance.runOnUiThread {
            val parsedGroups = groups.map { group -> ParsedOutboundGroup.fromOutbound(group) }
            event?.success(gson.toJson(parsedGroups))
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            CHANNEL
        )

        channel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                event = events
                Log.d(TAG, "connecting active groups command client")
                client.connect()
            }

            override fun onCancel(arguments: Any?) {
                event = null
                Log.d(TAG, "disconnecting active groups command client")
                client.disconnect()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        event = null
        client.disconnect()
        channel?.setStreamHandler(null)
    }
}