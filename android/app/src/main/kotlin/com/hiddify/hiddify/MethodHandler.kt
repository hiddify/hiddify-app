package com.hiddify.hiddify

import android.util.Log
import com.hiddify.hiddify.bg.BoxService
import com.hiddify.hiddify.constant.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.mobile.Mobile
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
                        val baseDir = Application.application.filesDir
                        baseDir.mkdirs()
                        val workingDir = File(Application.application.filesDir, "working")
                        workingDir.mkdirs()
                        val tempDir = Application.application.cacheDir
                        tempDir.mkdirs()
                        Log.d(TAG, "base dir: ${baseDir.path}")
                        Log.d(TAG, "working dir: ${workingDir.path}")
                        Log.d(TAG, "temp dir: ${tempDir.path}")

                        Mobile.setup(baseDir.path, workingDir.path, tempDir.path, false)
                        Libbox.redirectStderr(File(workingDir, "stderr2.log").path)

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
                        val msg = BoxService.parseConfig(path, tempPath, debug)
                        success(msg)
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
                        val config = BoxService.buildConfig(path, options)
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
                        val path = call.argument<String>("path") ?: ""
                        val name = call.argument<String>("name") ?: ""
                        Settings.activeConfigPath = path
                        Settings.activeProfileName = name
                        val mainActivity = MainActivity.instance
                        val started = mainActivity.serviceStatus.value == Status.Started
                        if (!started) return@runCatching success(true)
                        val restart = Settings.rebuildServiceMode()
                        if (restart) {
                            mainActivity.reconnect()
                            BoxService.stop()
                            delay(1000L)
                            mainActivity.startService()
                            return@runCatching success(true)
                        }
                        runCatching {
                            Libbox.newStandaloneCommandClient().serviceReload()
                            success(true)
                        }.onFailure {
                            error(it)
                        }
                    }
                }
            }

            Trigger.SelectOutbound.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val groupTag = call.argument<String>("groupTag") ?: ""
                        val outboundTag = call.argument<String>("outboundTag") ?: ""
                        Libbox.newStandaloneCommandClient()
                            .selectOutbound(
                                groupTag,
                                outboundTag
                            )
                        success(true)
                    }
                }
            }

            Trigger.UrlTest.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        val groupTag = call.argument<String>("groupTag") ?: ""
                        Libbox.newStandaloneCommandClient()
                            .urlTest(
                                groupTag
                            )
                        success(true)
                    }
                }
            }

            Trigger.ClearLogs.method -> {
                scope.launch(Dispatchers.IO) {
                    result.runCatching {
                        MainActivity.instance.onServiceResetLogs(mutableListOf())
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

            else -> result.notImplemented()
        }
    }
}