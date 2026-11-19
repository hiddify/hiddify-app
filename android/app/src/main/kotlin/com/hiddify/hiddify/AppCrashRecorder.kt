package com.hiddify.hiddify

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.os.Process
import android.util.Log
import androidx.core.content.getSystemService
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * The app's own crashes, written where the Dart side keeps its own (app_crash_store_io.dart):
 * `app_crashes/<UTC time>-<kind>.txt` in the working directory, so the next run offers them in a
 * report. The core's crashes are archived by the core.
 *
 * - `android`: an exception nobody caught on a Java or Kotlin thread, written before Android's
 *   own handler ends the process. The VPN service runs in this process, so its crashes are here.
 * - `native` and `anr`: what Android recorded about how earlier runs ended (Android 11 and
 *   later): a native crash, the Flutter engine's among them, or the app not responding.
 */
object AppCrashRecorder {
    private const val TAG = "AppCrashRecorder"
    private const val DIRECTORY = "app_crashes"
    private const val KEEP = 10
    private const val MAX_TRACE = 256 * 1024
    private const val SEEN_PREFERENCES = "app_crash_recorder"
    private const val SEEN_KEY = "last_exit_timestamp"

    @Volatile
    private var installed = false

    fun install(context: Context) {
        if (installed) return
        installed = true
        val directory = directory(context) ?: return
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                val stack = StringWriter().also { error.printStackTrace(PrintWriter(it)) }.toString()
                write(
                    directory,
                    "android",
                    System.currentTimeMillis(),
                    "Uncaught ${error.javaClass.name}: ${error.message}\n\n" +
                        "thread: ${thread.name}\n" +
                        "time: ${iso(System.currentTimeMillis())}\n\n" +
                        stack,
                )
            } catch (_: Throwable) {
                // recording a crash must never be what crashes
            }
            previous?.uncaughtException(thread, error)
        }
        try {
            recordExitReasons(context, directory)
        } catch (e: Throwable) {
            Log.w(TAG, "reading the exit reasons failed", e)
        }
    }

    /** Native crashes and ANRs of earlier runs, each once: the newest one written is remembered. */
    private fun recordExitReasons(context: Context, directory: File) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val activityManager = context.getSystemService<ActivityManager>() ?: return
        val preferences = context.getSharedPreferences(SEEN_PREFERENCES, Context.MODE_PRIVATE)
        val seen = preferences.getLong(SEEN_KEY, 0)
        val exits = activityManager.getHistoricalProcessExitReasons(context.packageName, 0, 10)
            .filter { it.timestamp > seen && it.pid != Process.myPid() }
        if (exits.isEmpty()) return
        for (exit in exits.sortedBy { it.timestamp }) {
            val kind = when (exit.reason) {
                ApplicationExitInfo.REASON_CRASH_NATIVE -> "native"
                ApplicationExitInfo.REASON_ANR -> "anr"
                else -> continue
            }
            write(directory, kind, exit.timestamp, describe(exit, kind))
        }
        preferences.edit().putLong(SEEN_KEY, exits.maxOf { it.timestamp }).apply()
    }

    private fun describe(exit: ApplicationExitInfo, kind: String): String {
        val headline = when (kind) {
            "native" -> "Native crash in ${exit.processName}: ${exit.description ?: "no description"}"
            else -> "App not responding (ANR) in ${exit.processName}: ${exit.description ?: "no description"}"
        }
        val text = StringBuilder()
            .append(headline).append("\n\n")
            .append("time: ").append(iso(exit.timestamp)).append('\n')
            .append("status: ").append(exit.status).append('\n')
            .append("importance: ").append(exit.importance).append('\n')
            .append("pss: ").append(exit.pss).append(" KB, rss: ").append(exit.rss).append(" KB\n")
        // an ANR's trace is the threads' stacks as text; a native crash's is a binary tombstone
        // from Android 12 on, which says nothing read as text, so only its description is kept
        if (kind == "anr") {
            try {
                exit.traceInputStream?.use { stream ->
                    val bytes = stream.readBytes()
                    text.append('\n').append(String(bytes, 0, minOf(bytes.size, MAX_TRACE)))
                }
            } catch (_: Throwable) {
            }
        }
        return text.toString()
    }

    private fun directory(context: Context): File? {
        // the working directory the Dart side uses on Android: getExternalStorageDirectory()
        val working = context.getExternalFilesDir(null) ?: return null
        return File(working, DIRECTORY).takeIf { it.isDirectory || it.mkdirs() }
    }

    private fun write(directory: File, kind: String, time: Long, text: String) {
        // the Dart side's names: UTC to the millisecond, a taken one moved on by a millisecond, so
        // files sort by when they were written
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss-SSS", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
        var at = time
        var file = File(directory, "${format.format(Date(at))}-$kind.txt")
        while (file.exists()) file = File(directory, "${format.format(Date(++at))}-$kind.txt")
        file.writeText(text)
        directory.listFiles()?.sortedBy { it.name }?.dropLast(KEEP)?.forEach { it.delete() }
    }

    private fun iso(time: Long): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(Date(time))
}
