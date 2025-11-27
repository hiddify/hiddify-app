package com.hiddify.hiddify.bg

import android.annotation.TargetApi
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.hiddify.hiddify.Application
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.net.UnknownHostException

object DefaultNetworkListener {

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val mutex = Mutex()
    
    private val listeners = mutableMapOf<Any, (Network?) -> Unit>()
    private var currentNetwork: Network? = null
    private val pendingRequests = arrayListOf<CompletableDeferred<Network>>()

    suspend fun start(key: Any, listener: (Network?) -> Unit) {
        mutex.withLock {
            if (listeners.isEmpty()) register()
            listeners[key] = listener
            currentNetwork?.let { listener(it) }
        }
    }

    suspend fun get(): Network {
        if (fallback) {
            @TargetApi(23)
            return Application.connectivity.activeNetwork ?: throw UnknownHostException()
        }
        
        return mutex.withLock {
            currentNetwork?.let { return@withLock it }
            val deferred = CompletableDeferred<Network>()
            pendingRequests.add(deferred)
            deferred
        }.await()
    }

    suspend fun stop(key: Any) {
        mutex.withLock {
            if (listeners.isNotEmpty() && listeners.remove(key) != null && listeners.isEmpty()) {
                currentNetwork = null
                unregister()
            }
        }
    }

    private suspend fun handleNetworkUpdate(network: Network?, lost: Boolean = false) {
        mutex.withLock {
            if (lost) {
                if (currentNetwork == network) {
                    currentNetwork = null
                    listeners.values.forEach { it(null) }
                }
            } else if (network != null) {
                currentNetwork = network
                pendingRequests.forEach { it.complete(network) }
                pendingRequests.clear()
                listeners.values.forEach { it(network) }
            }
        }
    }

    // NB: this runs in ConnectivityThread, and this behavior cannot be changed until API 26
    private object Callback : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            scope.launch { handleNetworkUpdate(network) }
        }

        override fun onCapabilitiesChanged(
            network: Network,
            networkCapabilities: NetworkCapabilities
        ) {
            // it's a good idea to refresh capabilities
            scope.launch { handleNetworkUpdate(network) }
        }

        override fun onLost(network: Network) {
            scope.launch { handleNetworkUpdate(network, lost = true) }
        }
    }

    private var fallback = false
    private val request = NetworkRequest.Builder().apply {
        addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
        if (Build.VERSION.SDK_INT == 23) {  // workarounds for OEM bugs
            removeCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            removeCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL)
        }
    }.build()
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * Unfortunately registerDefaultNetworkCallback is going to return VPN interface since Android P DP1:
     * https://android.googlesource.com/platform/frameworks/base/+/dda156ab0c5d66ad82bdcf76cda07cbc0a9c8a2e
     *
     * This makes doing a requestNetwork with REQUEST necessary so that we don't get ALL possible networks that
     * satisfies default network capabilities but only THE default network. Unfortunately, we need to have
     * android.permission.CHANGE_NETWORK_STATE to be able to call requestNetwork.
     *
     * Source: https://android.googlesource.com/platform/frameworks/base/+/2df4c7d/services/core/java/com/android/server/ConnectivityService.java#887
     */
    private fun register() {
        when (Build.VERSION.SDK_INT) {
            in 31..Int.MAX_VALUE -> @TargetApi(31) {
                Application.connectivity.registerBestMatchingNetworkCallback(
                    request,
                    Callback,
                    mainHandler
                )
            }

            in 28 until 31 -> @TargetApi(28) {  // we want REQUEST here instead of LISTEN
                Application.connectivity.requestNetwork(request, Callback, mainHandler)
            }

            in 26 until 28 -> @TargetApi(26) {
                Application.connectivity.registerDefaultNetworkCallback(Callback, mainHandler)
            }

            in 24 until 26 -> @TargetApi(24) {
                Application.connectivity.registerDefaultNetworkCallback(Callback)
            }

            else -> try {
                fallback = false
                Application.connectivity.requestNetwork(request, Callback)
            } catch (e: RuntimeException) {
                fallback =
                    true     // known bug on API 23: https://stackoverflow.com/a/33509180/2245107
            }
        }
    }

    private fun unregister() {
        runCatching {
            Application.connectivity.unregisterNetworkCallback(Callback)
        }
    }
}