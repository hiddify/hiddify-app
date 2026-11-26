package com.hiddify.hiddify.bg

import android.util.Log

/** Runs root commands and reports whether the app currently has root. */
internal object RootShell {
    private const val TAG = "A/RootShell"
    private const val TIMEOUT_SECONDS = 20L

    /** Runs `id` through su; true only when the shell really is uid 0. */
    fun available(): Boolean = exec("id")?.contains("uid=0") == true

    /** Runs [script] with su and returns its output, or null when root was not granted / it timed out. */
    fun exec(script: String): String? {
        return try {
            val process = ProcessBuilder("su", "-c", script)
                .redirectErrorStream(true)
                .start()
            val output = StringBuilder()
            val reader = Thread {
                try {
                    process.inputStream.bufferedReader().useLines { lines ->
                        lines.forEach { line ->
                            if (output.length < 64 * 1024) output.append(line).append('\n')
                        }
                    }
                } catch (_: Exception) {
                }
            }
            reader.isDaemon = true
            reader.start()
            if (!waitForExit(process, TIMEOUT_SECONDS * 1000)) {
                process.destroy()
                Log.w(TAG, "root command timed out")
                return null
            }
            reader.join(500)
            val text = output.toString().trim()
            if (text.isNotEmpty()) {
                Log.d(TAG, text.lineSequence().take(24).joinToString("\n"))
            }
            if (process.exitValue() != 0) {
                Log.w(TAG, "root command exited ${process.exitValue()}")
                return null
            }
            text
        } catch (e: Exception) {
            Log.w(TAG, "root command failed", e)
            null
        }
    }

    /** Process.waitFor(timeout) needs API 26; poll instead so minSdk 24 keeps working. */
    private fun waitForExit(process: java.lang.Process, timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            try {
                process.exitValue()
                return true
            } catch (_: IllegalThreadStateException) {
                Thread.sleep(50)
            }
        }
        return false
    }
}
