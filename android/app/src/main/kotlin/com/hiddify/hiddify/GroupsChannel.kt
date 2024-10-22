package com.hiddify.hiddify

import android.util.Log
import com.google.gson.Gson
import com.hiddify.hiddify.utils.CommandClient
import com.hiddify.hiddify.utils.ParsedOutboundGroup
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import com.hiddify.core.libbox.OutboundGroup
import kotlinx.coroutines.CoroutineScope

class GroupsChannel(private val scope: CoroutineScope) : FlutterPlugin, CommandClient.Handler {
    companion object {
        const val TAG = "A/GroupsChannel"
        const val CHANNEL = "com.hiddify.app/groups"
        val gson = Gson()
    }

    private val client =
        CommandClient(scope, CommandClient.ConnectionType.Groups, this)

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
                Log.d(TAG, "connecting groups command client")
                client.connect()
            }

            override fun onCancel(arguments: Any?) {
                event = null
                Log.d(TAG, "disconnecting groups command client")
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