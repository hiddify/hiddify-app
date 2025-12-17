package com.hiddify.hiddify.core.utils

import java.util.concurrent.atomic.AtomicLong

/**
 * Singleton object to track traffic statistics
 * This tracks bytes uploaded and downloaded since last query
 */
object StatsTracker {
    private val uplinkBytes = AtomicLong(0)
    private val downlinkBytes = AtomicLong(0)
    private val totalUplink = AtomicLong(0)
    private val totalDownlink = AtomicLong(0)

    /**
     * Add bytes to uplink counter (called from VPN service or proxy)
     */
    fun addUplink(bytes: Long) {
        uplinkBytes.addAndGet(bytes)
        totalUplink.addAndGet(bytes)
    }

    /**
     * Add bytes to downlink counter (called from VPN service or proxy)
     */
    fun addDownlink(bytes: Long) {
        downlinkBytes.addAndGet(bytes)
        totalDownlink.addAndGet(bytes)
    }

    /**
     * Get uplink bytes since last call and reset counter
     */
    fun getAndResetUplink(): Long {
        return uplinkBytes.getAndSet(0)
    }

    /**
     * Get downlink bytes since last call and reset counter
     */
    fun getAndResetDownlink(): Long {
        return downlinkBytes.getAndSet(0)
    }

    /**
     * Get total uplink bytes (cumulative, not reset)
     */
    fun getTotalUplink(): Long = totalUplink.get()

    /**
     * Get total downlink bytes (cumulative, not reset)
     */
    fun getTotalDownlink(): Long = totalDownlink.get()

    /**
     * Reset all counters (call when VPN disconnects)
     */
    fun resetAll() {
        uplinkBytes.set(0)
        downlinkBytes.set(0)
        totalUplink.set(0)
        totalDownlink.set(0)
    }
}
