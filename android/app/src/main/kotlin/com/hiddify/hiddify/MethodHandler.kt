package com.hiddify.hiddify

import android.util.Log
import com.hiddify.hiddify.bg.BoxService
//import com.hiddify.hiddify.bg.BoxService.Companion.workingDir
import com.hiddify.hiddify.constant.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import com.hiddify.core.libbox.Libbox
import com.hiddify.core.mobile.Mobile
import com.hiddify.core.mobile.SetupOptions
import com.hiddify.hiddify.bg.Bugs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

class MethodHandler(private val scope: CoroutineScope) : FlutterPlugin,
    MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    companion object {
        const val TAG = "A/MethodHandler"
        const val channelName = "com.hiddify.app/method"

        enum class Trigger(val method: String) {
            Setup("setup"),
            Start("start"),
            Stop("stop"),
            Restart("restart"),
            AddGrpcClientPublicKey("add_grpc_client_public_key"),
            GetGrpcServerPublicKey("get_grpc_server_public_key"),

        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            channelName,
        )
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Trigger.AddGrpcClientPublicKey.method -> {
                GlobalScope.launch {
                    result.runCatching {
                        val args = call.arguments as Map<*, *>
                        val clientPub = args["clientPublicKey"] as ByteArray
                        Settings.grpcFlutterPublicKey = clientPub
                        Mobile.addGrpcClientPublicKey(clientPub)
                        success("")
                    }
                }
            }

            Trigger.GetGrpcServerPublicKey.method -> {
                GlobalScope.launch {
                    result.runCatching {
                        result.success(Mobile.getServerPublicKey())
                    }
                }
            }

            Trigger.Setup.method -> {
                GlobalScope.launch {
                    result.runCatching {
                        val args = call.arguments as Map<*, *>
                        Settings.baseDir = args["baseDir"] as String
                        Settings.workingDir = args["workingDir"] as String
                        Settings.tempDir = args["tempDir"] as String
                        Settings.debugMode = args["debug"] as Boolean? ?: false
                        val mode = args["mode"] as Int
                        val grpcPort = args["grpcPort"] as Int
                        Log.d("debugmode","${Settings.debugMode}")
                        runCatching {
                            Mobile.setup(
                                SetupOptions().also {
                                    it.basePath = Settings.baseDir
                                    it.workingDir = Settings.workingDir
                                    it.tempDir = Settings.tempDir
                                    it.fixAndroidStack = Bugs.fixAndroidStack
                                    it.mode=mode.toLong()
                                    it.listen= "127.0.0.1:" + grpcPort
                                    it.secret=""
                                    it.debug = Settings.debugMode
                                }, BoxService.activePlatformInterface)

//                            Libbox.setup(Settings.baseDir, Settings.workingDir, Settings.tempDir, false)
                            Libbox.redirectStderr(File(Settings.workingDir, "stderr2.log").path)

                            success("")
                        }.onFailure {
                            error(it)
                        }

                    }
                }
            }


            Trigger.Start.method -> {
                scope.launch {
                    result.runCatching {
                        val args = call.arguments as Map<*, *>
                        Settings.activeConfigPath = args["path"] as String? ?: ""
                        Settings.activeProfileName = args["name"] as String? ?: ""
                        Settings.debugMode = args["debug"] as Boolean? ?: false
                        Settings.grpcServiceModePort = args["grpcPort"] as Int

                        val mainActivity = MainActivity.instance
                        // Quick disconnect→connect used to call start while status was still
                        // Stopping; onStartCommand then no-ops and Mobile.setup races close.
                        suspend fun awaitStatus(target: Status, maxTries: Int = 50): Boolean {
                            var i = 0
                            while (mainActivity.serviceStatus.value != target && i < maxTries) {
                                delay(200)
                                i++
                            }
                            return mainActivity.serviceStatus.value == target
                        }
                        when (val current = mainActivity.serviceStatus.value) {
                            Status.Stopping, Status.Starting -> {
                                Log.i(TAG, "waiting for service to settle before start: $current")
                                awaitStatus(Status.Stopped)
                            }
                            Status.Started -> {
                                Log.i(TAG, "stopping running service before start")
                                BoxService.stop()
                                awaitStatus(Status.Stopped)
                            }
                            Status.Stopped, null -> {}
                        }
                        Settings.startCoreAfterStartingService = false

                        mainActivity.startService()
                        success(true)
                    }
                }
            }

            Trigger.Stop.method -> {
                scope.launch {
                    result.runCatching {
                        val mainActivity = MainActivity.instance
                        when (mainActivity.serviceStatus.value) {
                            Status.Stopped, null -> Log.w(TAG, "service is not running")
                            Status.Stopping -> {
                                Log.i(TAG, "stop already in progress, waiting")
                                var i = 0
                                while (mainActivity.serviceStatus.value == Status.Stopping && i < 50) {
                                    delay(200)
                                    i++
                                }
                            }
                            else -> {
                                BoxService.stop()
                                var i = 0
                                while (mainActivity.serviceStatus.value != Status.Stopped && i < 50) {
                                    delay(200)
                                    i++
                                }
                            }
                        }
                        success(true)
                    }
                }
            }

//            Trigger.Restart.method -> {
//                scope.launch(Dispatchers.IO) {
//                    result.runCatching {
//                        val args = call.arguments as Map<*, *>
//                        Settings.activeConfigPath = args["path"] as String? ?: ""
//                        Settings.activeProfileName = args["name"] as String? ?: ""
//                        val mainActivity = MainActivity.instance
//                        val started = mainActivity.serviceStatus.value == Status.Started
//                        if (!started) return@launch success(true)
//                        val restart = Settings.rebuildServiceMode()
//                        if (restart) {
//                            mainActivity.reconnect()
//                            BoxService.stop()
//                            delay(1000L)
//                            mainActivity.startService()
//                            return@launch success(true)
//                        }
//                        runCatching {
//                            Libbox.newStandaloneCommandClient().serviceReload()
//                            success(true)
//                        }.onFailure {
//                            error(it)
//                        }
//                    }
//                }
//            }

            else -> result.notImplemented()
        }
    }
}