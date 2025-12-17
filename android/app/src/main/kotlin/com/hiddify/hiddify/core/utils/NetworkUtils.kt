package com.hiddify.hiddify.core.utils

import android.util.Log
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.Socket
import java.net.URL
import javax.net.ssl.HttpsURLConnection

/**
 * Network utility functions for ping and connectivity tests
 */
object NetworkUtils {
    private const val TAG = "NetworkUtils"

    /**
     * Perform a TCP ping to measure latency to a server
     * @param address Server address in format "host:port"
     * @param timeout Timeout in milliseconds
     * @return Latency in milliseconds, or -1 on error
     */
    fun tcpPing(address: String, timeout: Int): Int {
        return try {
            val parts = address.split(":")
            if (parts.size != 2) return -1
            
            val host = parts[0]
            val port = parts[1].toIntOrNull() ?: return -1
            
            val startTime = System.currentTimeMillis()
            Socket().use { socket ->
                socket.connect(InetSocketAddress(host, port), timeout)
            }
            val endTime = System.currentTimeMillis()
            
            (endTime - startTime).toInt()
        } catch (e: Exception) {
            Log.w(TAG, "TCP ping failed to $address: ${e.message}")
            -1
        }
    }

    /**
     * Perform an HTTP request through a SOCKS proxy to measure latency
     * @param socksAddr SOCKS proxy address in format "host:port"
     * @param testUrl URL to test connectivity
     * @param timeout Timeout in milliseconds
     * @return Latency in milliseconds, or -1 on error
     */
    fun proxyPing(socksAddr: String, testUrl: String, timeout: Int): Int {
        return try {
            val parts = socksAddr.split(":")
            if (parts.size != 2) return -1
            
            val proxyHost = parts[0]
            val proxyPort = parts[1].toIntOrNull() ?: return -1
            
            val proxy = Proxy(Proxy.Type.SOCKS, InetSocketAddress(proxyHost, proxyPort))
            val url = URL(testUrl)
            
            val startTime = System.currentTimeMillis()
            
            val connection = url.openConnection(proxy) as HttpsURLConnection
            connection.connectTimeout = timeout
            connection.readTimeout = timeout
            connection.requestMethod = "HEAD"
            connection.instanceFollowRedirects = false
            
            try {
                connection.connect()
                val responseCode = connection.responseCode
                val endTime = System.currentTimeMillis()
                if (responseCode in 200..399) {
                    (endTime - startTime).toInt()
                } else {
                    Log.w(TAG, "Proxy ping got response code: $responseCode")
                    -1
                }
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Proxy ping failed: ${e.message}")
            -1
        }
    }

    /**
     * Simple HTTP connectivity test (no proxy)
     * @param testUrl URL to test
     * @param timeout Timeout in milliseconds
     * @return Latency in milliseconds, or -1 on error
     */
    fun httpPing(testUrl: String, timeout: Int): Int {
        return try {
            val url = URL(testUrl)
            val startTime = System.currentTimeMillis()
            
            val connection = url.openConnection() as HttpsURLConnection
            connection.connectTimeout = timeout
            connection.readTimeout = timeout
            connection.requestMethod = "HEAD"
            connection.instanceFollowRedirects = false
            
            try {
                connection.connect()
                val responseCode = connection.responseCode
                val endTime = System.currentTimeMillis()
                
                if (responseCode in 200..399) {
                    (endTime - startTime).toInt()
                } else {
                    -1
                }
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "HTTP ping failed: ${e.message}")
            -1
        }
    }
}
