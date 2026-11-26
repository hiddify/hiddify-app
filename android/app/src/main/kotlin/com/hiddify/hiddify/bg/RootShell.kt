package com.hiddify.hiddify.bg

import android.util.Log

/**
 * Runs root commands and reports whether the app currently has root.
 *
 * One `su` at a time, and a recent answer is reused: a single toggle used to ask twice (the
 * re-apply and the check), and every settings visit or connect asked again.
 */
internal object RootShell {
    private const val TAG = "A/RootShell"
    private const val TIMEOUT_SECONDS = 20L
    private const val KILL_TIMEOUT_MS = 2_000L
    private const val CACHE_MS = 30_000L
    private const val MAX_OUTPUT = 64 * 1024

    private val lock = Any()
    private var cachedGranted: Boolean? = null
    private var cachedAt = 0L

    /** Cached: true only when `id` through su really reported uid 0. */
    fun available(): Boolean = synchronized(lock) {
        val now = System.currentTimeMillis()
        val cached = cachedGranted
        if (cached != null && now - cachedAt < CACHE_MS) return cached
        val granted = execLocked("id")?.contains("uid=0") == true
        cachedGranted = granted
        cachedAt = now
        granted
    }

    /** Drops the cached answer after root may have changed (a failed command, a revoked grant). */
    fun forget() = synchronized(lock) {
        cachedGranted = null
        cachedAt = 0L
    }

    /** Runs [script] with su and returns its output, or null when root was not granted / it timed out. */
    fun exec(script: String): String? = synchronized(lock) {
        val result = execLocked(script)
        // A failed command may mean the grant was revoked; do not keep answering "root" from cache.
        if (result == null) {
            cachedGranted = null
            cachedAt = 0L
        } else {
            cachedAt = System.currentTimeMillis()
        }
        result
    }

    private fun execLocked(script: String): String? {
        var process: Process? = null
        return try {
            process = ProcessBuilder("su", "-c", script)
                .redirectErrorStream(true)
                .start()
            val output = StringBuilder()
            val reader = Thread {
                try {
                    process.inputStream.bufferedReader().useLines { lines ->
                        lines.forEach { line ->
                            if (output.length < MAX_OUTPUT) output.append(line).append('\n')
                        }
                    }
                } catch (_: Exception) {
                }
            }
            reader.isDaemon = true
            reader.start()
            if (!waitForExit(process, TIMEOUT_SECONDS * 1000)) {
                // Kill the whole tree: killing su alone leaves the script running after we
                // reported failure, so the device state and the app's view disagree.
                process.destroy()
                if (!waitForExit(process, KILL_TIMEOUT_MS)) process.destroyForcibly()
                reader.join(KILL_TIMEOUT_MS)
                Log.w(TAG, "root command timed out")
                return null
            }
            // su exits after the script; the pipe closed, so the reader reaches EOF promptly.
            // Wait for it instead of reading a buffer it may still be appending to.
            reader.join(KILL_TIMEOUT_MS)
            if (reader.isAlive) Log.w(TAG, "output reader still draining; using partial output")
            val text = synchronized(output) { output.toString() }.trim()
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
            return null
        } finally {
            process?.let { runCatching { it.destroy() } }
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
