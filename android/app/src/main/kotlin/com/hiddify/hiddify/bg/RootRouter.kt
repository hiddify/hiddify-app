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
 * routing for the remaining UID space, and redirect only those UIDs' own DNS queries to the VPN
 * resolver. Queries made through the platform resolver are owned by netd, not by the app, so they
 * keep using the underlying resolver: routing them is not possible from here.
 *
 * Best-effort by design: no root, no default route, no ip6tables nat, a missing iptables, etc.
 * leave the VPN fully working for the main user and only log why the extra routing is missing.
 * Rules are idempotent and removed on teardown; a stale set from a killed process is replaced on
 * the next TUN up (and disappears on reboot).
 *
 * The rules and the preferences they use are process-global, while a router is created per
 * service object. All of that state therefore lives in the companion, under one lock: a stale
 * instance's teardown can no longer delete a newer instance's rules.
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

        val mutex = Mutex()
        val generation = AtomicLong(0L)

        @Volatile
        var owner: RootRouter? = null
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var applyJob: Job? = null

    @Volatile
    private var listening = false

    private var iface: String? = null
    private var hasV4 = false
    private var hasV6 = false
    private var dns4: List<String> = emptyList()
    private var dns6: List<String> = emptyList()

    private var lastApplyGen = -1L
    private var lastApplyAt = 0L

    /**
     * Called when the toggle changes while connected: apply or remove the rules now instead of
     * waiting for the next TUN. No-op while the VPN is down; the next onTunUp does it then.
     */
    fun onSettingChanged() {
        scope.launch {
            try {
                if (iface == null) {
                    Log.i(TAG, "setting changed with no TUN; waiting for the next one")
                    return@launch
                }
                apply(generation.get(), force = true)
            } catch (e: Exception) {
                Log.w(TAG, "root routing setting change failed", e)
            }
        }
    }

    /**
     * Called when the VPN service starts, before any TUN exists. If a previous process died
     * while rules were installed, this is the first chance to remove them even when the next
     * connection fails before opening a TUN.
     */
    fun onServiceStarting() {
        if (!Settings.rootRouteApplied) return
        // This service is the newest one; the rules of a dead session are ours to remove.
        owner = this
        val gen = generation.incrementAndGet()
        scope.launch {
            try {
                mutex.withLock {
                    if (owner !== this@RootRouter || gen != generation.get()) return@withLock
                    cleanupLocked()
                }
            } catch (e: Exception) {
                Log.w(TAG, "stale root routing cleanup failed", e)
            }
        }
    }

    /** Called by VPNService.openTun once the TUN fd exists. */
    fun onTunUp(addresses: List<String>, dnsServers: List<String>) {
        Log.i(TAG, "onTunUp: feature=${Settings.rootRouteAllUsers} applied=${Settings.rootRouteApplied} " +
            "addresses=$addresses dns=$dnsServers")
        if (!Settings.rootRouteAllUsers) {
            // Never ask for root when the feature is off. Only a previous run's rules need root.
            if (!Settings.rootRouteApplied) return
            val gen = generation.get()
            scope.launch {
                try {
                    mutex.withLock {
                        if (owner !== this@RootRouter || gen != generation.get()) return@withLock
                        stopListeningLocked()
                        cleanupLocked()
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "root routing cleanup failed", e)
                }
            }
            return
        }
        // The router that opened the live TUN owns the process-global rules from here on.
        owner = this
        val gen = generation.incrementAndGet()
        scope.launch {
            try {
                val tun = findInterface(addresses)
                if (gen != generation.get()) return@launch
                if (tun == null || !tun.matches(Regex(NAME))) {
                    Log.w(TAG, "TUN interface not found for $addresses; root routing skipped")
                    mutex.withLock {
                        if (owner === this@RootRouter && gen == generation.get()) cleanupLocked()
                    }
                    return@launch
                }
                iface = tun
                hasV4 = addresses.any { !it.contains(':') }
                hasV6 = addresses.any { it.contains(':') }
                dns4 = dnsServers.mapNotNull { canonicalIp(it, v6 = false) }.distinct()
                dns6 = dnsServers.mapNotNull { canonicalIp(it, v6 = true) }.distinct()
                Log.i(TAG, "TUN $tun v4=$hasV4 v6=$hasV6 dns4=$dns4 dns6=$dns6")
                startListener()
                apply(gen)
            } catch (e: Exception) {
                // NetworkInterface / bridge lookup must not abort the whole setup silently.
                Log.w(TAG, "root routing setup failed", e)
            }
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

    private suspend fun stopListeningLocked() {
        if (!listening) return
        listening = false
        try {
            DefaultNetworkListener.stop(this)
        } catch (_: Exception) {
        }
    }

    private fun scheduleApply() {
        val gen = generation.get()
        applyJob?.cancel()
        applyJob = scope.launch {
            try {
                delay(800)
                apply(gen)
            } catch (e: Exception) {
                Log.w(TAG, "root routing re-apply failed", e)
            }
        }
    }

    private suspend fun apply(gen: Long, force: Boolean = false) = mutex.withLock {
        if (owner !== this@RootRouter) {
            Log.i(TAG, "apply skipped: another router owns the process rules")
            return@withLock
        }
        if (gen != generation.get()) {
            Log.i(TAG, "apply skipped: TUN generation changed ($gen != ${generation.get()})")
            return@withLock
        }
        if (!Settings.rootRouteAllUsers) {
            stopListeningLocked()
            if (Settings.rootRouteApplied) cleanupLocked()
            return@withLock
        }
        val tun = iface ?: return@withLock
        if (!tun.matches(Regex(NAME))) {
            Log.w(TAG, "refusing unsafe interface name: $tun")
            return@withLock
        }
        // DefaultNetworkListener.start calls back immediately when a default network is known, and
        // onTunUp then applies as well. Skip the duplicate for the same TUN.
        val now = System.currentTimeMillis()
        if (!force && gen == lastApplyGen && now - lastApplyAt < 2_000) return@withLock
        lastApplyGen = gen
        lastApplyAt = now

        if (!RootShell.available()) {
            Log.w(TAG, "root denied or unavailable; root routing stays off")
            return@withLock
        }

        // Clean before adding: a reconnect or a network change must not leave old DNS rules behind.
        cleanupLocked()

        val ranges = otherUserRanges()
        val commands = installCommands(tun, ranges)
        // Remember that a partial add may exist: if the command times out or the process dies,
        // teardown/next start still cleans.
        Settings.rootRouteApplied = true
        val output = RootShell.exec(commands.joinToString("\n"))
        val failed = output?.lineSequence()?.firstOrNull { it.startsWith("HIDDIFY_FAILED:") }
        when {
            output == null -> Log.w(TAG, "installing root routes failed (su unavailable)")
            failed != null -> Log.w(TAG, "some root routes were not installed:${failed.removePrefix("HIDDIFY_FAILED:")}")
            else -> Log.i(TAG, "root routing installed for ${ranges.joinToString()}")
        }
    }

    /**
     * The installer. Only other users' UIDs are redirected; the platform resolver's queries are
     * owned by netd, so they stay direct, as documented on the class.
     */
    private fun installCommands(tun: String, ranges: List<String>): List<String> {
        val commands = mutableListOf<String>()
        commands += "failed=\"\""
        fun checked(name: String, line: String) {
            commands += "$line 2>/dev/null || failed=\"\$failed,$name\""
        }
        ranges.forEach { range ->
            // -m owner --uid-owner only matches locally generated packets, which is exactly the
            // DNS half of this feature. A device-wide DNAT would break excluded apps and the
            // platform resolver instead.
            if (hasV4) checked("ip4-uid-$range", "ip rule add pref $UID_PREF uidrange $range lookup $tun")
            if (hasV6) checked("ip6-uid-$range", "ip -6 rule add pref $UID_PREF uidrange $range lookup $tun")
        }
        if (hasV4) dns4.forEach { dns ->
            checked("ip4-dns-$dns", "ip rule add pref $DNS_PREF to $dns/32 lookup $tun")
        }
        if (hasV6) dns6.forEach { dns ->
            checked("ip6-dns-$dns", "ip -6 rule add pref $DNS_PREF to $dns/128 lookup $tun")
        }

        if (hasV4 && dns4.isNotEmpty()) {
            val dns = dns4.first()
            commands += "iptables -w -t nat -N $OUT_CHAIN 2>/dev/null || true"
            commands += "iptables -w -t nat -F $OUT_CHAIN 2>/dev/null || failed=\"\$failed,nat4-flush\""
            ranges.forEach { range ->
                checked(
                    "nat4-udp-$range",
                    "iptables -w -t nat -A $OUT_CHAIN -p udp --dport 53 -m owner --uid-owner $range -j DNAT --to-destination $dns",
                )
                checked(
                    "nat4-tcp-$range",
                    "iptables -w -t nat -A $OUT_CHAIN -p tcp --dport 53 -m owner --uid-owner $range -j DNAT --to-destination $dns",
                )
            }
            commands += "if ! iptables -w -t nat -C OUTPUT -j $OUT_CHAIN 2>/dev/null; then " +
                "iptables -w -t nat -I OUTPUT 1 -j $OUT_CHAIN 2>/dev/null || failed=\"\$failed,nat4-jump\"; fi"
            // Some resolvers keep the underlying source address after the DNAT; make the packet
            // look like it came from the TUN so the core accepts the reply path.
            commands += "iptables -w -t nat -N $POST_CHAIN 2>/dev/null || true"
            commands += "iptables -w -t nat -F $POST_CHAIN 2>/dev/null || failed=\"\$failed,nat4-post-flush\""
            checked("nat4-post-udp", "iptables -w -t nat -A $POST_CHAIN -o $tun -p udp --dport 53 -j MASQUERADE")
            checked("nat4-post-tcp", "iptables -w -t nat -A $POST_CHAIN -o $tun -p tcp --dport 53 -j MASQUERADE")
            commands += "if ! iptables -w -t nat -C POSTROUTING -j $POST_CHAIN 2>/dev/null; then " +
                "iptables -w -t nat -A POSTROUTING -j $POST_CHAIN 2>/dev/null || failed=\"\$failed,nat4-post-jump\"; fi"
        }
        if (hasV6 && dns6.isNotEmpty()) {
            val dns = dns6.first()
            // IPv6 NAT is absent on many Android kernels; skip it instead of reporting a failure.
            commands += "if ip6tables -w -t nat -L -n >/dev/null 2>&1; then"
            commands += "ip6tables -w -t nat -N $OUT_CHAIN 2>/dev/null || true"
            commands += "ip6tables -w -t nat -F $OUT_CHAIN 2>/dev/null || failed=\"\$failed,nat6-flush\""
            ranges.forEach { range ->
                checked(
                    "nat6-udp-$range",
                    "ip6tables -w -t nat -A $OUT_CHAIN -p udp --dport 53 -m owner --uid-owner $range -j DNAT --to-destination $dns",
                )
                checked(
                    "nat6-tcp-$range",
                    "ip6tables -w -t nat -A $OUT_CHAIN -p tcp --dport 53 -m owner --uid-owner $range -j DNAT --to-destination $dns",
                )
            }
            commands += "if ! ip6tables -w -t nat -C OUTPUT -j $OUT_CHAIN 2>/dev/null; then " +
                "ip6tables -w -t nat -I OUTPUT 1 -j $OUT_CHAIN 2>/dev/null || failed=\"\$failed,nat6-jump\"; fi"
            commands += "ip6tables -w -t nat -N $POST_CHAIN 2>/dev/null || true"
            commands += "ip6tables -w -t nat -F $POST_CHAIN 2>/dev/null || failed=\"\$failed,nat6-post-flush\""
            checked("nat6-post-udp", "ip6tables -w -t nat -A $POST_CHAIN -o $tun -p udp --dport 53 -j MASQUERADE")
            checked("nat6-post-tcp", "ip6tables -w -t nat -A $POST_CHAIN -o $tun -p tcp --dport 53 -j MASQUERADE")
            commands += "if ! ip6tables -w -t nat -C POSTROUTING -j $POST_CHAIN 2>/dev/null; then " +
                "ip6tables -w -t nat -A POSTROUTING -j $POST_CHAIN 2>/dev/null || failed=\"\$failed,nat6-post-jump\"; fi"
            commands += "fi"
        }
        commands += "[ -z \"\$failed\" ] || echo \"HIDDIFY_FAILED:\$failed\""
        return commands
    }

    /** Removes our rules. Safe when nothing was installed and when root is gone. */
    suspend fun stop() {
        applyJob?.cancel()
        mutex.withLock {
            // A newer service already owns the process-global rules; its cleanup is not ours.
            if (owner !== this@RootRouter) {
                Log.i(TAG, "stop skipped: another router owns the process rules")
                return@withLock
            }
            generation.incrementAndGet()
            stopListeningLocked()
            cleanupLocked()
            iface = null
            hasV4 = false
            hasV6 = false
            dns4 = emptyList()
            dns6 = emptyList()
            owner = null
        }
    }

    /**
     * Deletes the jumps and chains first, then the rules. Only the rules this app created are
     * targeted when the TUN is known; a leftover at our preference is logged (a foreign rule would
     * be removed too) and removed so a dead TUN cannot blackhole other users.
     */
    private fun cleanupLocked(): Boolean {
        if (!Settings.rootRouteApplied) return true
        val tun = iface
        val ranges = otherUserRanges()
        val commands = mutableListOf<String>()

        for (binary in listOf("iptables", "ip6tables")) {
            repeat(3) {
                commands += "$binary -w -t nat -D OUTPUT -j $OUT_CHAIN 2>/dev/null || true"
                commands += "$binary -w -t nat -D POSTROUTING -j $POST_CHAIN 2>/dev/null || true"
            }
            commands += "$binary -w -t nat -F $OUT_CHAIN 2>/dev/null || true"
            commands += "$binary -w -t nat -X $OUT_CHAIN 2>/dev/null || true"
            commands += "$binary -w -t nat -F $POST_CHAIN 2>/dev/null || true"
            commands += "$binary -w -t nat -X $POST_CHAIN 2>/dev/null || true"
        }

        if (tun != null) {
            repeat(3) {
                if (hasV4) {
                    ranges.forEach { commands += "ip rule del pref $UID_PREF uidrange $it lookup $tun 2>/dev/null || true" }
                    dns4.forEach { commands += "ip rule del pref $DNS_PREF to $it/32 lookup $tun 2>/dev/null || true" }
                }
                if (hasV6) {
                    ranges.forEach { commands += "ip -6 rule del pref $UID_PREF uidrange $it lookup $tun 2>/dev/null || true" }
                    dns6.forEach { commands += "ip -6 rule del pref $DNS_PREF to $it/128 lookup $tun 2>/dev/null || true" }
                }
            }
            commands += "left=\$(ip rule list | grep -E '^(8000|8001):' | head -1)"
            commands += "[ -z \"\$left\" ] || { echo \"HIDDIFY_FOREIGN:\$left\"; " +
                "ip rule del pref $UID_PREF 2>/dev/null || true; ip -6 rule del pref $UID_PREF 2>/dev/null || true; " +
                "ip rule del pref $DNS_PREF 2>/dev/null || true; ip -6 rule del pref $DNS_PREF 2>/dev/null || true; }"
        } else {
            // The process that installed the rules is gone, so the table and DNS addresses are
            // unknown; the preference is the only handle. Say so: a foreign rule at these
            // preferences would be removed too.
            commands += "echo HIDDIFY_STALE:removing-rules-by-preference"
            repeat(3) {
                commands += "ip rule del pref $UID_PREF 2>/dev/null || true"
                commands += "ip -6 rule del pref $UID_PREF 2>/dev/null || true"
                commands += "ip rule del pref $DNS_PREF 2>/dev/null || true"
                commands += "ip -6 rule del pref $DNS_PREF 2>/dev/null || true"
            }
        }

        commands += "left=\$(ip rule list | grep -E '^(8000|8001):' | head -1)"
        commands += "[ -z \"\$left\" ] || echo \"HIDDIFY_LEFT:\$left\""
        commands += "iptables -w -t nat -S $OUT_CHAIN >/dev/null 2>&1 && echo HIDDIFY_LEFT:chain-v4"
        commands += "ip6tables -w -t nat -S $OUT_CHAIN >/dev/null 2>&1 && echo HIDDIFY_LEFT:chain-v6"
        // The probes above fail when nothing is left; the script itself must still exit 0 so the
        // markers (not the exit code) decide success.
        commands += "true"

        val output = RootShell.exec(commands.joinToString("\n"))
        output?.lineSequence()?.firstOrNull { it.startsWith("HIDDIFY_STALE:") }?.let {
            Log.w(TAG, "no TUN to scope cleanup to; removing rules by preference")
        }
        output?.lineSequence()?.firstOrNull { it.startsWith("HIDDIFY_FOREIGN:") }?.let {
            Log.w(TAG, "removed a rule at our preference that this run did not create: ${it.removePrefix("HIDDIFY_FOREIGN:")}")
        }
        val leftover = output?.lineSequence()?.firstOrNull { it.startsWith("HIDDIFY_LEFT:") }
        val ok = output != null && leftover == null
        if (ok) Settings.rootRouteApplied = false
        Log.i(TAG, "root routing cleanup ${if (ok) "done" else "failed or incomplete"}")
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
        // first application UID so root/system UIDs of user 0 stay direct.
        if (own > 0) ranges += "$FIRST_APP_UID-${ownStart - 1}"
        if (ownEnd < LAST_UID) ranges += "${ownEnd + 1}-$LAST_UID"
        return ranges
    }

    private fun findInterface(addresses: List<String>): String? {
        if (addresses.isEmpty()) return null
        val wanted = addresses.toSet()
        repeat(10) {
            try {
                val interfaces = NetworkInterface.getNetworkInterfaces() ?: return null
                for (nif in Collections.list(interfaces)) {
                    val match = Collections.list(nif.inetAddresses).any { addr ->
                        val host = addr.hostAddress
                        host != null && host in wanted
                    }
                    if (match) return nif.name
                }
            } catch (e: Exception) {
                Log.w(TAG, "cannot enumerate network interfaces", e)
                return null
            }
            try {
                Thread.sleep(200)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                return null
            }
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
