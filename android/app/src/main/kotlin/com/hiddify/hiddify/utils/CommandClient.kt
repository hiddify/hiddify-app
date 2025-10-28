package com.hiddify.hiddify.utils

import android.util.Log
import go.Seq
import io.nekohasekai.libbox.CommandClient
import io.nekohasekai.libbox.CommandClientHandler
import io.nekohasekai.libbox.CommandClientOptions
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.OutboundGroup
import io.nekohasekai.libbox.OutboundGroupIterator
import io.nekohasekai.libbox.StatusMessage
import io.nekohasekai.libbox.StringIterator
import com.hiddify.hiddify.ktx.toList
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

open class CommandClient(
    private val scope: CoroutineScope,
    private val connectionType: ConnectionType,
    private val handler: Handler
) {

    companion object {
        private const val TAG = "CommandClient"
    }

    enum class ConnectionType {
        Status, Groups, Log, ClashMode, GroupOnly
    }

    interface Handler {

        fun onConnected() {}
        fun onDisconnected() {}
        fun updateStatus(status: StatusMessage) {}
        fun updateGroups(groups: List<OutboundGroup>) {}
        fun clearLog() {}
        fun appendLog(message: String) {}
        fun initializeClashMode(modeList: List<String>, currentMode: String) {}
        fun updateClashMode(newMode: String) {}

    }


    private var commandClient: CommandClient? = null
    private val clientHandler = ClientHandler()
    fun connect() {
        disconnect()
        val options = CommandClientOptions()
        options.command = when (connectionType) {
            ConnectionType.Status -> Libbox.CommandStatus
            ConnectionType.Groups -> Libbox.CommandGroup
            ConnectionType.Log -> Libbox.CommandLog
            ConnectionType.ClashMode -> Libbox.CommandClashMode
            ConnectionType.GroupOnly -> Libbox.CommandGroupInfoOnly
        }
        options.statusInterval = 2 * 1000 * 1000 * 1000
        val commandClient = CommandClient(clientHandler, options)
        scope.launch(Dispatchers.IO) {
            var lastException: Exception? = null
            for (i in 1..10) {
                delay(100 + i.toLong() * 50)
                try {
                    commandClient.connect()
                    Log.d(TAG, "CommandClient connected successfully for $connectionType")
                } catch (e: Exception) {
                    lastException = e
                    Log.w(TAG, "CommandClient connection attempt $i/10 failed for $connectionType: ${e.message}", e)
                    continue
                }
                if (!isActive) {
                    runCatching {
                        commandClient.disconnect()
                    }
                    return@launch
                }
                this@CommandClient.commandClient = commandClient
                return@launch
            }
            
            // اگر همه تلاش‌ها شکست خوردند
            Log.e(TAG, "All 10 connection attempts failed for $connectionType. Last error: ${lastException?.message}", lastException)
            handler.onDisconnected()
            runCatching {
                commandClient.disconnect()
            }
        }
    }

    fun disconnect() {
        commandClient?.apply {
            runCatching {
                disconnect()
            }
            Seq.destroyRef(refnum)
        }
        commandClient = null
    }

    private inner class ClientHandler : CommandClientHandler {

        override fun connected() {
            handler.onConnected()
        }

        override fun disconnected(message: String?) {
            handler.onDisconnected()
        }

        override fun writeGroups(message: OutboundGroupIterator?) {
            if (message == null) {
                return
            }
            val groups = mutableListOf<OutboundGroup>()
            while (message.hasNext()) {
                groups.add(message.next())
            }
            handler.updateGroups(groups)
        }

        override fun clearLog() {
            handler.clearLog()
        }

        override fun writeLog(message: String?) {
            if (message == null) {
                return
            }
            handler.appendLog(message)
        }

        override fun writeStatus(message: StatusMessage?) {
            if (message == null) {
                return
            }
            handler.updateStatus(message)
        }

        override fun initializeClashMode(modeList: StringIterator, currentMode: String) {
            handler.initializeClashMode(modeList.toList(), currentMode)
        }

        override fun updateClashMode(newMode: String) {
            handler.updateClashMode(newMode)
        }

    }

}