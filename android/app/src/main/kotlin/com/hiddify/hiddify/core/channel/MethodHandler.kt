package com.hiddify.hiddify.core.channel

import android.util.Log
import com.hiddify.hiddify.core.HiddifyApp
import com.hiddify.hiddify.ui.MainActivity
import com.hiddify.hiddify.core.service.BoxService
import com.hiddify.hiddify.core.constant.Status
import com.hiddify.hiddify.core.utils.NetworkUtils
import com.hiddify.hiddify.core.utils.StatsTracker
import com.hiddify.hiddify.core.settings.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.hiddify.libcore.mobile.Mobile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
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
            ParseConfig("parse_config"),
            changeHiddifyOptions("change_hiddify_options"),
            GenerateConfig("generate_config"),
            Start("start"),
            Stop("stop"),
            Restart("restart"),
            SelectOutbound("select_outbound"),
            UrlTest("url_test"),
            ClearLogs("clear_logs"),
            GenerateWarpConfig("generate_warp_config"),
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
            Trigger.Setup.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val baseDir = HiddifyApp.instance.filesDir
                        baseDir.mkdirs()
                        val workingDir = File(HiddifyApp.instance.filesDir, "working")
                        workingDir.mkdirs()
                        val tempDir = HiddifyApp.instance.cacheDir
                        tempDir.mkdirs()
                        Log.d(TAG, "base dir: ${baseDir.path}")
                        Log.d(TAG, "working dir: ${workingDir.path}")
                        Log.d(TAG, "temp dir: ${tempDir.path}")

                        Mobile.setup(baseDir.path, workingDir.path, tempDir.path, false)
                        // Libbox.redirectStderr(File(workingDir, "stderr2.log").path) // Not supported yet

                        success("")
                    }
                }
            }

            Trigger.ParseConfig.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val path = call.argument<String>("path") ?: ""
                        val tempPath = call.argument<String>("tempPath") ?: ""
                        val debug = call.argument<Boolean>("debug") ?: false
                        Mobile.parseConfig(path, tempPath, debug)
                        success("")
                    }
                }
            }

            Trigger.changeHiddifyOptions.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val args = call.arguments as? String ?: ""
                        Settings.configOptions = args
                        success(true)
                    }
                }
            }

            Trigger.GenerateConfig.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val path = call.argument<String>("path") ?: ""
                        val options = Settings.configOptions
                        if (options.isBlank() || path.isBlank()) {
                            if (path.isBlank()) error("blank path")
                        }
                        val config = Mobile.buildConfig(path, options)
                        success(config)
                    }
                }
            }

            Trigger.Start.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val path = call.argument<String>("path") ?: ""
                        val name = call.argument<String>("name") ?: ""
                        Settings.activeConfigPath = path
                        Settings.activeProfileName = name
                        val mainActivity = MainActivity.instance
                        val started = mainActivity.serviceStatus.value == Status.Started
                        if (started) {
                            Log.w(TAG, "service is already running")
                            return@runCatching success(true)
                        }
                        mainActivity.startService()
                        success(true)
                    }
                }
            }

            Trigger.Stop.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val mainActivity = MainActivity.instance
                        val started = mainActivity.serviceStatus.value == Status.Started
                        if (!started) {
                            Log.w(TAG, "service is not running")
                            return@runCatching success(true)
                        }
                        BoxService.stop()
                        success(true)
                    }
                }
            }

            Trigger.Restart.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        // For Xray, reload usually means stop and start
                        val mainActivity = MainActivity.instance
                        BoxService.stop()
                        // Wait a bit?
                        mainActivity.startService()
                        success(true)
                    }
                }
            }

            Trigger.SelectOutbound.method -> {
                // Not supported in simple mode yet
                result.notImplemented()
            }

            Trigger.UrlTest.method -> {
                // Not supported in simple mode yet
                result.notImplemented()
            }

            Trigger.ClearLogs.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        BoxService.logList.clear()
                        success(true)
                    }
                }
            }

            Trigger.GenerateWarpConfig.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val licenseKey = call.argument<String>("license-key") ?: ""
                        val previousAccountId = call.argument<String>("previous-account-id") ?: ""
                        val previousAccessToken = call.argument<String>("previous-access-token") ?: ""
                        val warpConfig = Mobile.generateWarpConfig(
                            licenseKey,
                            previousAccountId,
                            previousAccessToken,
                        )
                        success(warpConfig)
                    }
                }
            }
            "getUplink" -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val uplink = Mobile.getUplink()
                        success(uplink)
                    }
                }
            }

            "getDownlink" -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val downlink = Mobile.getDownlink()
                        success(downlink)
                    }
                }
            }

            "proxyPing" -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val socksAddr = call.argument<String>("socksAddr") ?: "127.0.0.1:2334"
                        val testUrl = call.argument<String>("testUrl") ?: "https://connectivitycheck.gstatic.com/generate_204"
                        val timeout = call.argument<Int>("timeout") ?: 5000
                        
                        val latency = Mobile.proxyPing(socksAddr, testUrl, timeout.toLong())
                        success(latency)
                    }
                }
            }

            "ping" -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val address = call.argument<String>("address") ?: ""
                        val timeout = call.argument<Int>("timeout") ?: 5000
                        
                        val latency = Mobile.ping(address, timeout.toLong())
                        success(latency)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }
}