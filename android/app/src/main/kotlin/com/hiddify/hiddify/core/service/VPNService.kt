package com.hiddify.hiddify.core.service

import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import com.hiddify.hiddify.ui.MainActivity
import com.hiddify.hiddify.core.settings.Settings
import org.json.JSONArray
import org.json.JSONObject
import java.net.InetAddress

class VPNService : VpnService() {

    companion object {
        private const val TAG = "A/VPNService"
        
        fun prepare(activity: MainActivity): Intent? {
            return VpnService.prepare(activity)
        }
    }

    // Local definition of TunOptions to replace libbox dependency
    data class TunOptions(
        var mtu: Int = 9000,
        val inet4Addresses: MutableList<IPPrefix> = mutableListOf(),
        val inet6Addresses: MutableList<IPPrefix> = mutableListOf(),
        val inet4RouteAddresses: MutableList<IPPrefix> = mutableListOf(),
        val inet6RouteAddresses: MutableList<IPPrefix> = mutableListOf(),
        val inet4ExcludeRouteAddresses: MutableList<IPPrefix> = mutableListOf(),
        val inet6ExcludeRouteAddresses: MutableList<IPPrefix> = mutableListOf(),
        val dnsServerAddresses: MutableList<String> = mutableListOf()
    ) {
        data class IPPrefix(val address: String, val prefix: Int)
    }

    private var boxService: BoxServiceWrapper? = null
    private var tunFd: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "VPNService onCreate")
        boxService = BoxServiceWrapper(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "VPNService onStartCommand: ${intent?.action}")
        boxService?.handleStartCommand(intent, flags, startId)
        return Service.START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "VPNService onDestroy")
        closeTunInterface()
        boxService?.handleDestroy()
        boxService = null
        super.onDestroy()
    }

    override fun onRevoke() {
        Log.d(TAG, "VPNService onRevoke")
        BoxService.stop()
        super.onRevoke()
    }

    fun openTun(options: TunOptions): Int {
        Log.d(TAG, "Opening TUN interface")
        
        val builder = Builder()
            .setSession("Hiddify")
            .setMtu(options.mtu)
        
        for (address in options.inet4Addresses) {
            try {
                builder.addAddress(address.address, address.prefix)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add IPv4 address: ${address.address}/${address.prefix}", e)
            }
        }
        
        for (address in options.inet6Addresses) {
            try {
                builder.addAddress(address.address, address.prefix)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add IPv6 address: ${address.address}/${address.prefix}", e)
            }
        }

        for (route in options.inet4RouteAddresses) {
            try {
                builder.addRoute(route.address, route.prefix)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add IPv4 route: ${route.address}/${route.prefix}", e)
            }
        }
        
        for (route in options.inet6RouteAddresses) {
            try {
                builder.addRoute(route.address, route.prefix)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add IPv6 route: ${route.address}/${route.prefix}", e)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            for (route in options.inet4ExcludeRouteAddresses) {
                try {
                    builder.excludeRoute(android.net.IpPrefix(java.net.InetAddress.getByName(route.address), route.prefix))
                } catch (e: Exception) {
                     Log.w(TAG, "Failed to exclude IPv4 route", e)
                }
            }
            
            for (route in options.inet6ExcludeRouteAddresses) {
                try {
                    builder.excludeRoute(android.net.IpPrefix(java.net.InetAddress.getByName(route.address), route.prefix))
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to exclude IPv6 route", e)
                }
            }
        }

        for (dns in options.dnsServerAddresses) {
            try {
                builder.addDnsServer(dns)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add DNS server: $dns", e)
            }
        }

        if (Settings.perAppProxyEnabled) {
            val appList = Settings.perAppProxyList
            val mode = Settings.perAppProxyMode
            
            if (mode == "include") {
                for (packageName in appList) {
                    try {
                        builder.addAllowedApplication(packageName)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to add allowed app: $packageName", e)
                    }
                }
            } else {
                for (packageName in appList) {
                    try {
                        builder.addDisallowedApplication(packageName)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to add disallowed app: $packageName", e)
                    }
                }
            }
        }
        try {
            builder.addDisallowedApplication(packageName)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to exclude ourselves", e)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }
        try {
            tunFd = builder.establish()
            if (tunFd == null) {
                Log.e(TAG, "Failed to establish VPN - returned null")
                return -1
            }
            Log.d(TAG, "TUN interface established, fd: ${tunFd!!.fd}")
            return tunFd!!.fd
        } catch (e: Exception) {
            Log.e(TAG, "Failed to establish VPN", e)
            return -1
        }
    }

    fun closeTunInterface() {
        try {
            tunFd?.close()
            tunFd = null
            Log.d(TAG, "TUN interface closed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close TUN interface", e)
        }
    }

    override fun protect(fd: Int): Boolean {
        return super.protect(fd)
    }

    inner class BoxServiceWrapper(private val vpnService: VPNService) : BoxService() {
        
        override fun createService(): Int {
            val notification = this.notification
            vpnService.startForeground(
                ServiceNotification.NOTIFICATION_ID,
                notification.build(Settings.activeProfileName)
            )
            return Service.START_STICKY
        }

        override fun destroyService() {
            vpnService.stopForeground(Service.STOP_FOREGROUND_REMOVE)
            vpnService.stopSelf()
        }

        override fun openTun(options: String): Int {
            val tunOptions = TunOptions()
            try {
                val json = JSONObject(options)
                tunOptions.mtu = json.optInt("mtu", 9000)
                
                val inet4Addresses = json.optJSONArray("inet4_address") ?: JSONArray()
                for (i in 0 until inet4Addresses.length()) {
                    val addr = inet4Addresses.getJSONObject(i)
                    tunOptions.inet4Addresses.add(TunOptions.IPPrefix(addr.getString("address"), addr.getInt("prefix")))
                }
                
                val inet6Addresses = json.optJSONArray("inet6_address") ?: JSONArray()
                for (i in 0 until inet6Addresses.length()) {
                    val addr = inet6Addresses.getJSONObject(i)
                    tunOptions.inet6Addresses.add(TunOptions.IPPrefix(addr.getString("address"), addr.getInt("prefix")))
                }
                
                val inet4Routes = json.optJSONArray("inet4_route_address") ?: JSONArray()
                for (i in 0 until inet4Routes.length()) {
                    val route = inet4Routes.getJSONObject(i)
                    tunOptions.inet4RouteAddresses.add(TunOptions.IPPrefix(route.getString("address"), route.getInt("prefix")))
                }
                
                val inet6Routes = json.optJSONArray("inet6_route_address") ?: JSONArray()
                for (i in 0 until inet6Routes.length()) {
                    val route = inet6Routes.getJSONObject(i)
                    tunOptions.inet6RouteAddresses.add(TunOptions.IPPrefix(route.getString("address"), route.getInt("prefix")))
                }
                
                val dnsServers = json.optJSONArray("dns_server_address") ?: JSONArray()
                for (i in 0 until dnsServers.length()) {
                    tunOptions.dnsServerAddresses.add(dnsServers.getString(i))
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse TUN options", e)
            }
            
            return vpnService.openTun(tunOptions)
        }

        override fun closeTun(fd: Int) {
            vpnService.closeTunInterface()
        }

        // override fun autoDetectInterfaceControl(fd: Int) {
        //     vpnService.protect(fd)
        // }
        
        fun handleStartCommand(intent: Intent?, flags: Int, startId: Int) {
            // BoxService handles lifecycle internally
        }
        
        fun handleDestroy() {
            // BoxService handles lifecycle internally
        }
    }
}
