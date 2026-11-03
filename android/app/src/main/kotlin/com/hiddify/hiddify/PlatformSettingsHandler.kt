package com.hiddify.hiddify

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.util.Base64
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.hiddify.hiddify.Application.Companion.packageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream


class PlatformSettingsHandler : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private lateinit var ignoreRequestResult: MethodChannel.Result

    companion object {
        const val channelName = "com.hiddify.app/platform"

        const val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = 44
        val gson = Gson()

        enum class Trigger(val method: String) {
            IsIgnoringBatteryOptimizations("is_ignoring_battery_optimizations"),
            RequestIgnoreBatteryOptimizations("request_ignore_battery_optimizations"),
            GetInstalledPackages("get_installed_packages"),
            GetPackagesIcon("get_package_icon"),
            IsTelevision("is_television"),
            SupportedAbis("supported_abis"),
            InstallApk("install_apk"),
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val taskQueue = flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            channelName,
            StandardMethodCodec.INSTANCE,
            taskQueue
        )
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
            ignoreRequestResult.success(resultCode == Activity.RESULT_OK)
            return true
        }
        return false
    }

    data class AppItem(
        @SerializedName("package-name") val packageName: String,
        @SerializedName("name") val name: String,
        @SerializedName("is-system-app") val isSystemApp: Boolean
    )

    @SuppressLint("BatteryLife")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Trigger.IsIgnoringBatteryOptimizations.method -> {
                result.runCatching {
                    success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Application.powerManager.isIgnoringBatteryOptimizations(Application.application.packageName)
                        } else {
                            true
                        }
                    )
                }
            }

            Trigger.RequestIgnoreBatteryOptimizations.method -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    return result.success(true)
                }
                val intent = Intent(
                    android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${Application.application.packageName}")
                )
                ignoreRequestResult = result
                activity?.startActivityForResult(intent, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            }

            Trigger.GetInstalledPackages.method -> {
                GlobalScope.launch {
                    result.runCatching {
                        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            PackageManager.GET_PERMISSIONS or PackageManager.MATCH_UNINSTALLED_PACKAGES
                        } else {
                            @Suppress("DEPRECATION")
                            PackageManager.GET_PERMISSIONS or PackageManager.GET_UNINSTALLED_PACKAGES
                        }
                        val installedPackages =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getInstalledPackages(
                                    PackageManager.PackageInfoFlags.of(
                                        flag.toLong()
                                    )
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getInstalledPackages(flag)
                            }
                        val list = mutableListOf<AppItem>()
                        installedPackages.forEach {
                            if (it.packageName != Application.application.packageName &&
                                (it.requestedPermissions?.contains(Manifest.permission.INTERNET) == true
                                        || it.packageName == "android")
                            ) {
                                list.add(
                                    AppItem(
                                        it.packageName,
                                        it.applicationInfo?.loadLabel(packageManager).toString(),
                                        (it.applicationInfo?.flags?.and(ApplicationInfo.FLAG_SYSTEM) == 1)
                                    )
                                )
                            }
                        }
                        list.sortBy { it.name }
                        success(gson.toJson(list))
                    }
                }
            }

            Trigger.GetPackagesIcon.method -> {
                result.runCatching {
                    val args = call.arguments as Map<*, *>
                    val packageName =
                        args["packageName"] as String
                    val drawable = packageManager.getApplicationIcon(packageName)
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth,
                        drawable.intrinsicHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
                    val base64: String =
                        Base64.encodeToString(byteArrayOutputStream.toByteArray(), Base64.NO_WRAP)
                    success(base64)
                }
            }

            Trigger.IsTelevision.method -> {
                result.runCatching {
                    val uiMode = Application.application.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
                    success(
                        packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                            uiMode?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                    )
                }
            }

            Trigger.SupportedAbis.method -> {
                result.runCatching { success(Build.SUPPORTED_ABIS.toList()) }
            }

            // An update the app downloaded: the system installer asks the user to confirm it. Until
            // the user allows this app to install apps, its settings page opens instead, and the
            // answer is "permission" so the app can say why and offer to try again.
            Trigger.InstallApk.method -> {
                result.runCatching {
                    val context = activity ?: Application.application
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        !context.packageManager.canRequestPackageInstalls()
                    ) {
                        context.startActivity(
                            Intent(
                                android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:${context.packageName}")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        success("permission")
                        return@runCatching
                    }
                    val file = java.io.File(call.arguments as String)
                    val uri = androidx.core.content.FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.updates",
                        file
                    )
                    context.startActivity(
                        Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    success("started")
                }
            }

            else -> result.notImplemented()
        }
    }
}