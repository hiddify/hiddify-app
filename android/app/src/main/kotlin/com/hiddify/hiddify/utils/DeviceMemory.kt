package com.hiddify.hiddify.utils

import android.app.ActivityManager
import android.content.Context
import com.hiddify.hiddify.Application
import com.hiddify.core.mobile.SetupOptions

/**
 * The device's memory, passed to the core when it is set up (both the app's core and the VPN
 * service's, which share the process).
 *
 * One core serves phones and low-RAM TVs. The core is given what it may use on this device, so the
 * "Memory limit" setting has a limit to hold the Go runtime to, and on a device short of memory it
 * relays in its low-memory way.
 */
object DeviceMemory {
    /** Below this a device is short of memory: 2 GB boxes report a little less than 2 GiB. */
    private const val LOW_MEMORY_TOTAL = 2560L shl 20

    private val activityManager: ActivityManager?
        get() = Application.application.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager

    /**
     * What the core may use here, in bytes: a quarter of the device's RAM; 0 if unknown.
     *
     * Not the per-app heap class (memoryClass): that bounds the Java heap, not native memory, and
     * the core is native. A Go limit at three quarters of it (about 190 MB on most phones) made
     * the GC run all the time and the connection lag (#2521).
     */
    val limit: Long
        get() {
            val manager = activityManager ?: return 0
            val info = ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
            return info.totalMem / 4
        }

    val isLow: Boolean
        get() {
            val manager = activityManager ?: return false
            if (manager.isLowRamDevice) return true
            val info = ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
            return info.totalMem in 1 until LOW_MEMORY_TOTAL
        }

    fun applyTo(options: SetupOptions) {
        options.memoryLimit = limit
        options.lowMemory = isLow
    }
}
