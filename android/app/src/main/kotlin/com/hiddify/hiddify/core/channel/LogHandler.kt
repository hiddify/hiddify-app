package com.hiddify.hiddify.core.channel

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel


import com.hiddify.hiddify.core.service.BoxService

class LogHandler : FlutterPlugin {

    companion object {
        const val TAG = "A/LogHandler"
        const val SERVICE_LOGS = "com.hiddify.app/service.logs"
    }

    private lateinit var logsChannel: EventChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        logsChannel = EventChannel(flutterPluginBinding.binaryMessenger, SERVICE_LOGS)

        logsChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                events?.success(BoxService.logList)
                BoxService.logCallback = { message ->
                    events?.success(message)
                }
            }

            override fun onCancel(arguments: Any?) {
                BoxService.logCallback = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
}