package com.hiddify.hiddify

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

object MitUpdateInstaller {
    private const val MAX_BYTES = 350L * 1024 * 1024
    private fun directory(): File = File(Application.application.cacheDir, "updates").also {
        check(it.isDirectory || it.mkdirs())
    }
    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it.toInt() and 255) }
    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): List<String> {
        val signatures = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        return signatures?.map { hex(MessageDigest.getInstance("SHA-256").digest(it.toByteArray())) }?.sorted() ?: emptyList()
    }
    @Suppress("DEPRECATION")
    private fun verify(call: MethodCall): File {
        val hash = call.argument<String>("sha256") ?: error("hash missing")
        val expectedVersion = call.argument<Number>("version")?.toLong() ?: error("version missing")
        val size = call.argument<Number>("size")?.toLong() ?: error("size missing")
        check(hash.matches(Regex("[a-fA-F0-9]{64}")) && size in 1..MAX_BYTES && expectedVersion in 1..2147483647L)
        val dir = directory().canonicalFile
        val file = File(dir, "mits-vpn-update.apk")
        check(file.canonicalPath == file.absolutePath && file.isFile && file.length() == size)
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(65536)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        check(hex(digest.digest()).equals(hash, ignoreCase = true))
        val ctx = Application.application
        val pm = ctx.packageManager
        val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        val archive = pm.getPackageArchiveInfo(file.absolutePath, flags) ?: error("invalid apk")
        val installed = pm.getPackageInfo(ctx.packageName, flags)
        check(archive.packageName == ctx.packageName && version(archive) == expectedVersion && version(archive) > version(installed))
        val expectedSigners = signers(installed)
        check(expectedSigners.isNotEmpty() && signers(archive) == expectedSigners)
        return file
    }
    fun handle(call: MethodCall, result: MethodChannel.Result, activity: Activity?) {
        try {
            when (call.method) {
                "mit_update_directory" -> result.success(directory().absolutePath)
                "mit_verify_update" -> { verify(call); result.success(true) }
                "mit_install_update" -> {
                    val file = verify(call)
                    val ctx = Application.application
                    if (Build.VERSION.SDK_INT >= 26 && !ctx.packageManager.canRequestPackageInstalls()) {
                        result.success("permission_required")
                        return
                    }
                    val host = activity ?: error("activity missing")
                    val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.updates", file)
                    host.runOnUiThread {
                        try {
                            host.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                            result.success("launched")
                        } catch (_: Exception) { result.error("MIT_UPDATE_INSTALL", "Update installation unavailable", null) }
                    }
                }
                "mit_update_permission" -> {
                    val host = activity ?: error("activity missing")
                    host.runOnUiThread {
                        try {
                            if (Build.VERSION.SDK_INT >= 26) host.startActivity(Intent(
                                android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:${Application.application.packageName}")))
                            result.success(null)
                        } catch (_: Exception) { result.error("MIT_UPDATE_PERMISSION", "Update permission unavailable", null) }
                    }
                }
            }
        } catch (_: Exception) {
            // Exception strings can include private cache paths. Never return them to Flutter.
            result.error("MIT_UPDATE_VERIFY", "Update verification failed", null)
        }
    }
}
