package com.hiddify.hiddify.bg

import android.net.Network
import android.os.Build
import android.util.Log
import com.hiddify.hiddify.Application
import io.nekohasekai.libbox.InterfaceUpdateListener

import java.net.NetworkInterface
import kotlin.math.min

object DefaultNetworkMonitor {

    private const val TAG = "DefaultNetworkMonitor"
    var defaultNetwork: Network? = null
    private var listener: InterfaceUpdateListener? = null

    suspend fun start() {
        DefaultNetworkListener.start(this) {
            defaultNetwork = it
            checkDefaultInterfaceUpdate(it)
        }
        defaultNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Application.connectivity.activeNetwork
        } else {
            DefaultNetworkListener.get()
        }
    }

    suspend fun stop() {
        DefaultNetworkListener.stop(this)
    }

    suspend fun require(): Network {
        val network = defaultNetwork
        if (network != null) {
            return network
        }
        return DefaultNetworkListener.get()
    }

    fun setListener(listener: InterfaceUpdateListener?) {
        this.listener = listener
        checkDefaultInterfaceUpdate(defaultNetwork)
    }

    private fun checkDefaultInterfaceUpdate(
        newNetwork: Network?
    ) {
        val listener = listener ?: return
        if (newNetwork != null) {
            val interfaceName =
                (Application.connectivity.getLinkProperties(newNetwork) ?: return).interfaceName
            
            // بهبود: افزایش تلاش‌ها به 20 بار با exponential backoff
            var interfaceIndex = -1
            for (attempt in 0 until 20) {
                try {
                    interfaceIndex = NetworkInterface.getByName(interfaceName).index
                    listener.updateDefaultInterface(interfaceName, interfaceIndex)
                    Log.d(TAG, "Successfully updated interface: $interfaceName (index: $interfaceIndex)")
                    return
                } catch (e: Exception) {
                    // Exponential backoff with maximum 5 seconds delay
                    val delay = min(100L * (1 shl attempt), 5000L)
                    Log.w(TAG, "Attempt ${attempt + 1}/20 failed for interface $interfaceName, retrying in ${delay}ms: ${e.message}")
                    Thread.sleep(delay)
                }
            }
            
            // اگر همه تلاش‌ها شکست خوردند، interface را clear می‌کنیم و error log می‌کنیم
            Log.e(TAG, "Failed to get interface index after 20 attempts for $interfaceName. Clearing interface.")
            listener.updateDefaultInterface("", -1)
        } else {
            Log.d(TAG, "Network is null, clearing interface")
            listener.updateDefaultInterface("", -1)
        }
    }


}