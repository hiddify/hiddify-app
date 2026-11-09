package com.hiddify.hiddify.utils

import android.app.ActivityManager
import android.content.Context
import com.hiddify.hiddify.Application
import com.hiddify.core.mobile.SetupOptions

/**
 * The device's memory, passed to the core when it is set up (both the app's core and the VPN
 * service's, which share the process).
 *
 * One core serves phones and low-RAM TVs. The core is given what an app may use on this device, so
 * the "Memory limit" setting has a limit to hold the Go runtime to, and on a device short of memory
 * it relays in its low-memory way.
 */
object DeviceMemory {
    /** Below this a device is short of memory: 2 GB boxes report a little less than 2 GiB. */
    private const val LOW_MEMORY_TOTAL = 2560L shl 20

    private val activityManager: ActivityManager?
        get() = Application.application.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager

    /** What an app may use here, in bytes (the platform's per-app heap class); 0 if unknown. */
    val limit: Long
        get() = (activityManager?.memoryClass ?: 0).toLong() shl 20

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
