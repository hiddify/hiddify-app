package com.hiddify.hiddify.core.channel

import android.util.Log
import com.google.gson.Gson
import com.hiddify.hiddify.core.utils.CommandClient
import com.hiddify.hiddify.core.utils.ParsedOutboundGroup
import com.hiddify.hiddify.ui.MainActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMethodCodec
import com.hiddify.hiddify.core.model.OutboundGroup
import kotlinx.coroutines.*

class GroupsChannel : FlutterPlugin, CommandClient.Handler {
    companion object {
        const val TAG = "A/GroupsChannel"
        const val GROUPS_CHANNEL = "com.hiddify.app/groups"
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val commandClient by lazy {
        CommandClient(scope, CommandClient.ConnectionType.Groups, this)
    }

    private var groupsChannel: EventChannel? = null
    private var groupsEvent: EventChannel.EventSink? = null
    private val groupsScope = CoroutineScope(Dispatchers.Default)

    override fun updateGroups(groups: List<OutboundGroup>) {
        groupsScope.launch {
            val parsedGroups = groups.map { group -> ParsedOutboundGroup.fromOutbound(group) }
            withContext(Dispatchers.Main) {
                groupsEvent?.success(parsedGroups)
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        groupsChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            GROUPS_CHANNEL,
            JSONMethodCodec.INSTANCE
        )

        groupsChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                groupsEvent = events
                Log.d(TAG, "connecting groups command client")
                commandClient.connect()
            }

            override fun onCancel(arguments: Any?) {
                groupsEvent = null
                Log.d(TAG, "disconnecting groups command client")
                commandClient.disconnect()
                groupsScope.cancel()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        groupsEvent = null
        commandClient.disconnect()
        groupsChannel?.setStreamHandler(null)
        groupsScope.cancel()
    }
}