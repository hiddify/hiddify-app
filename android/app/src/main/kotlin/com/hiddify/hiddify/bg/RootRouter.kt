package com.hiddify.hiddify.bg

import android.os.Process as AndroidProcess
import android.util.Log
import com.hiddify.hiddify.Settings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.Collections
import java.util.concurrent.atomic.AtomicLong

/**
 * Sends every other Android user's traffic through this VPN, with root.
 *
 * A VpnService owns only the UIDs of its own user (and that user's restricted profiles). Apps in
 * a clone/work/secondary profile keep using the underlying network. With root we add policy
 * routing for the remaining UID space and point the system resolver's DNS at the VPN DNS.
 *
 * Best-effort by design: no root, no default route, no ip6tables nat, a missing iptables, etc.
 * leave the VPN fully working for the main user and only log why the extra routing is missing.
 * Rules are idempotent and removed on teardown; a stale set from a killed process is replaced on
 * the next TUN up (and disappears on reboot).
 */
class RootRouter {
    private companion object {
        const val TAG = "A/RootRouter"
        const val UID_PREF = 8000
        const val DNS_PREF = 8001
        const val OUT_CHAIN = "HIDDIFY_ROOT_OUT"
        const val POST_CHAIN = "HIDDIFY_ROOT_POST"
        const val NAME = "[A-Za-z0-9_.-]{1,32}"
        const val FIRST_APP_UID = 10000L
        const val LAST_UID = 2147483647L
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mutex = Mutex()
    private var applyJob: Job? = null

    @Volatile private var listening = false

    // Incremented on every TUN up and on stop. An apply that started for an older TUN (or while
    // the service was stopping) sees the mismatch and does nothing.
    private val generation = AtomicLong(0L)

    private var iface: String? = null
    private var table: String? = null
    private var hasV4 = false
    private var hasV6 = false
    private var dns4: List<String> = emptyList()
    private var dns6: List<String> = emptyList()

    /**
     * Called when the toggle changes while connected: apply or remove the rules now instead of
     * waiting for the next TUN. No-op while the VPN is down; the next onTunUp does it then.
     */
    fun onSettingChanged() {
        scope.launch {
            if (iface == null) return@launch
            apply(generation.get())
        }
    }

    /**
     * Called when the VPN service starts, before any TUN exists. If a previous process died
     * while rules were installed, this is the first chance to remove them even when the next
     * connection fails before opening a TUN.
     */
    fun onServiceStarting() {
        if (!Settings.rootRouteApplied) return
        val gen = generation.get()
        scope.launch {
            mutex.withLock {
                // A TUN came up while this was queued: its apply owns the rules now.
                if (gen != generation.get()) return@withLock
                cleanupLocked()
            }
        }
    }

    /** Called by VPNService.openTun once the TUN fd exists. */
    fun onTunUp(addresses: List<String>, dnsServers: List<String>) {
        if (!Settings.rootRouteAllUsers) {
            // Never ask for root when the feature is off. Only a previous run's rules need root.
            if (Settings.rootRouteApplied) {
                val gen = generation.get()
                scope.launch {
                    mutex.withLock {
                        if (gen != generation.get()) return@withLock
                        cleanupLocked()
                    }
                }
            }
            return
        }
        val gen = generation.incrementAndGet()
        scope.launch {
            val iface = findInterface(addresses)
            if (gen != generation.get()) return@launch
            if (iface == null || !iface.matches(Regex(NAME))) {
                Log.w(TAG, "TUN interface not found for $addresses; root routing skipped")
                cleanupStale(gen)
                return@launch
            }
            this@RootRouter.iface = iface
            // Android names the VPN routing table after the interface (tun0).
            this@RootRouter.table = iface
            hasV4 = addresses.any { !it.contains(':') }
            hasV6 = addresses.any { it.contains(':') }
            dns4 = dnsServers.mapNotNull { canonicalIp(it, v6 = false) }.distinct()
            dns6 = dnsServers.mapNotNull { canonicalIp(it, v6 = true) }.distinct()
            Log.i(TAG, "TUN $iface table $table v4=$hasV4 v6=$hasV6 dns4=$dns4 dns6=$dns6")
            startListener()
            apply(gen)
        }
    }

    private suspend fun cleanupStale(gen: Long) {
        if (!Settings.rootRouteApplied) return
        if (gen != generation.get()) return
        mutex.withLock {
            if (gen != generation.get()) return@withLock
            cleanupLocked()
        }
    }

    private suspend fun startListener() {
        if (listening) return
        listening = true
        try {
            DefaultNetworkListener.start(this) {
                // The underlying network changed; netd may have replaced or flushed our rules.
                scheduleApply()
            }
        } catch (e: Exception) {
            listening = false
            Log.w(TAG, "cannot watch the default network", e)
        }
    }

    private fun scheduleApply() {
        val gen = generation.get()
        applyJob?.cancel()
        applyJob = scope.launch {
            delay(800)
            apply(gen)
        }
    }

    private suspend fun apply(gen: Long) = mutex.withLock {
        if (gen != generation.get()) return@withLock
        if (!Settings.rootRouteAllUsers) {
            if (Settings.rootRouteApplied) cleanupLocked()
            return@withLock
        }
        val iface = iface ?: return@withLock
        val table = table ?: return@withLock
        if (!iface.matches(Regex(NAME)) || !table.matches(Regex(NAME))) {
            Log.w(TAG, "refusing unsafe interface/table name: $iface/$table")
            return@withLock
        }
        val id = RootShell.exec("id")
        if (id == null || !id.contains("uid=0")) {
            Log.w(TAG, "root denied or unavailable; root routing stays off")
            return@withLock
        }

        // Clean before adding: a reconnect or a network change must not leave old DNS rules behind.
        cleanupLocked()

        val appUid = AndroidProcess.myUid()
        val ranges = otherUserRanges()
        val commands = mutableListOf<String>()
        ranges.forEach {
            if (hasV4) commands += "ip rule add pref $UID_PREF uidrange $it lookup $table"
            if (hasV6) commands += "ip -6 rule add pref $UID_PREF uidrange $it lookup $table"
        }
        if (hasV4) dns4.forEach { commands += "ip rule add pref $DNS_PREF to $it/32 lookup $table" }
        if (hasV6) dns6.forEach { commands += "ip -6 rule add pref $DNS_PREF to $it/128 lookup $table" }

        if (hasV4 && dns4.isNotEmpty()) {
            val dns = dns4.first()
            commands += "iptables -t nat -N $OUT_CHAIN 2>/dev/null || true"
            commands += "iptables -t nat -F $OUT_CHAIN 2>/dev/null || true"
            // The core resolves on its own; sending its DNS into its own listener would loop.
            commands += "iptables -t nat -A $OUT_CHAIN -p udp --dport 53 -m owner --uid-owner $appUid -j RETURN"
            commands += "iptables -t nat -A $OUT_CHAIN -p tcp --dport 53 -m owner --uid-owner $appUid -j RETURN"
            commands += "iptables -t nat -A $OUT_CHAIN -p udp --dport 53 -j DNAT --to-destination $dns"
            commands += "iptables -t nat -A $OUT_CHAIN -p tcp --dport 53 -j DNAT --to-destination $dns"
            commands += "iptables -t nat -C OUTPUT -j $OUT_CHAIN 2>/dev/null || iptables -t nat -I OUTPUT 1 -j $OUT_CHAIN"
            // Some resolvers keep the underlying source address after the DNAT; make the packet
            // look like it came from the TUN so the core accepts the reply path.
            commands += "iptables -t nat -N $POST_CHAIN 2>/dev/null || true"
            commands += "iptables -t nat -F $POST_CHAIN 2>/dev/null || true"
            commands += "iptables -t nat -A $POST_CHAIN -o $iface -p udp --dport 53 -j MASQUERADE"
            commands += "iptables -t nat -A $POST_CHAIN -o $iface -p tcp --dport 53 -j MASQUERADE"
            commands += "iptables -t nat -C POSTROUTING -j $POST_CHAIN 2>/dev/null || iptables -t nat -A POSTROUTING -j $POST_CHAIN"
        }
        if (hasV6 && dns6.isNotEmpty()) {
            val dns = dns6.first()
            commands += "ip6tables -t nat -N $OUT_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -F $OUT_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -A $OUT_CHAIN -p udp --dport 53 -m owner --uid-owner $appUid -j RETURN"
            commands += "ip6tables -t nat -A $OUT_CHAIN -p tcp --dport 53 -m owner --uid-owner $appUid -j RETURN"
            commands += "ip6tables -t nat -A $OUT_CHAIN -p udp --dport 53 -j DNAT --to-destination $dns"
            commands += "ip6tables -t nat -A $OUT_CHAIN -p tcp --dport 53 -j DNAT --to-destination $dns"
            commands += "ip6tables -t nat -C OUTPUT -j $OUT_CHAIN 2>/dev/null || ip6tables -t nat -I OUTPUT 1 -j $OUT_CHAIN"
            commands += "ip6tables -t nat -N $POST_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -F $POST_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -A $POST_CHAIN -o $iface -p udp --dport 53 -j MASQUERADE"
            commands += "ip6tables -t nat -A $POST_CHAIN -o $iface -p tcp --dport 53 -j MASQUERADE"
            commands += "ip6tables -t nat -C POSTROUTING -j $POST_CHAIN 2>/dev/null || ip6tables -t nat -A POSTROUTING -j $POST_CHAIN"
        }

        if (commands.isEmpty()) return@withLock
        // Remember that a partial add may exist: if the command times out or the process dies,
        // teardown/next start still cleans. The trailing `true` keeps old kernels' missing
        // ip6tables nat from failing the whole apply.
        Settings.rootRouteApplied = true
        commands += "true"
        if (RootShell.exec(commands.joinToString("\n")) == null) {
            Log.w(TAG, "installing root routes failed")
            return@withLock
        }
        Log.i(TAG, "root routing installed for ${ranges.joinToString()}")
    }

    /** Removes our rules. Safe when nothing was installed and when root is gone. */
    suspend fun stop() {
        generation.incrementAndGet()
        applyJob?.cancel()
        mutex.withLock {
            if (listening) {
                listening = false
                try {
                    DefaultNetworkListener.stop(this)
                } catch (_: Exception) {
                }
            }
            cleanupLocked()
        }
    }

    private fun cleanupLocked(): Boolean {
        if (!Settings.rootRouteApplied) return true
        val commands = mutableListOf<String>()
        // Delete duplicate jumps/prefixes a killed process or an older run may have left.
        repeat(3) {
            commands += "ip rule del pref $UID_PREF 2>/dev/null || true"
            commands += "ip -6 rule del pref $UID_PREF 2>/dev/null || true"
            commands += "ip rule del pref $DNS_PREF 2>/dev/null || true"
            commands += "ip -6 rule del pref $DNS_PREF 2>/dev/null || true"
            commands += "iptables -t nat -D OUTPUT -j $OUT_CHAIN 2>/dev/null || true"
            commands += "iptables -t nat -D POSTROUTING -j $POST_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -D OUTPUT -j $OUT_CHAIN 2>/dev/null || true"
            commands += "ip6tables -t nat -D POSTROUTING -j $POST_CHAIN 2>/dev/null || true"
        }
        for (binary in listOf("iptables", "ip6tables")) {
            commands += "$binary -t nat -F $OUT_CHAIN 2>/dev/null || true"
            commands += "$binary -t nat -X $OUT_CHAIN 2>/dev/null || true"
            commands += "$binary -t nat -F $POST_CHAIN 2>/dev/null || true"
            commands += "$binary -t nat -X $POST_CHAIN 2>/dev/null || true"
        }
        commands += "true"
        val ok = RootShell.exec(commands.joinToString("\n")) != null
        if (ok) Settings.rootRouteApplied = false
        Log.i(TAG, "root routing cleanup ${if (ok) "done" else "failed"}")
        return ok
    }

    /** UID ranges of every user except the one running this VPN. */
    private fun otherUserRanges(): List<String> {
        // UserHandle.getUserId is hidden from the public SDK; UID = userId * 100000 + appId.
        val uid = AndroidProcess.myUid()
        val own = if (uid < 100000) 0L else uid.toLong() / 100000L
        val ownStart = own * 100000L
        val ownEnd = ownStart + 99999L
        val ranges = mutableListOf<String>()
        // When the VPN runs outside user 0, user 0's apps are "other users" too. Start at the
        // first application UID so root/system UIDs of user 0 stay direct; their DNS still goes
        // through the resolver redirect.
        if (own > 0) ranges += "$FIRST_APP_UID-${ownStart - 1}"
        if (ownEnd < LAST_UID) ranges += "${ownEnd + 1}-$LAST_UID"
        return ranges
    }

    private fun findInterface(addresses: List<String>): String? {
        if (addresses.isEmpty()) return null
        val wanted = addresses.toSet()
        repeat(10) {
            val interfaces = NetworkInterface.getNetworkInterfaces() ?: return null
            for (nif in Collections.list(interfaces)) {
                val match = Collections.list(nif.inetAddresses).any { addr ->
                    val host = addr.hostAddress
                    host != null && host in wanted
                }
                if (match) return nif.name
            }
            Thread.sleep(200)
        }
        return null
    }

    private fun canonicalIp(value: String, v6: Boolean): String? {
        val candidate = value.substringBefore('/').substringBefore('%').trim()
        if (candidate.isEmpty()) return null
        if (v6 != candidate.contains(':')) return null
        if (!candidate.matches(Regex("[0-9a-fA-F:.]+"))) return null
        return try {
            val host = InetAddress.getByName(candidate).hostAddress ?: return null
            if (v6 != host.contains(':')) null else host
        } catch (_: Exception) {
            null
        }
    }
}


