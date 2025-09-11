package com.hiddify.hiddify

import android.content.Context
import android.util.Base64
import com.hiddify.hiddify.bg.ProxyService
import com.hiddify.hiddify.bg.VPNService
import com.hiddify.hiddify.constant.PerAppProxyMode
import com.hiddify.hiddify.constant.ServiceMode
import com.hiddify.hiddify.constant.SettingsKey
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.File
import java.io.ObjectInputStream

object Settings {

    private val preferences by lazy {
        val context = Application.application.applicationContext
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private const val LIST_IDENTIFIER = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"

    var perAppProxyMode: String
        get() = preferences.getString(SettingsKey.PER_APP_PROXY_MODE, PerAppProxyMode.OFF)!!
        set(value) = preferences.edit().putString(SettingsKey.PER_APP_PROXY_MODE, value).apply()

    val perAppProxyEnabled: Boolean
        get() = perAppProxyMode != PerAppProxyMode.OFF

    val perAppProxyList: List<String>
        get() {
            val stringValue = if (perAppProxyMode == PerAppProxyMode.INCLUDE) {
                preferences.getString(SettingsKey.PER_APP_PROXY_INCLUDE_LIST, "")!!
            } else {
                preferences.getString(SettingsKey.PER_APP_PROXY_EXCLUDE_LIST, "")!!
            }
            if (!stringValue.startsWith(LIST_IDENTIFIER)) {
                return emptyList()
            }
            return decodeListString(stringValue.substring(LIST_IDENTIFIER.length))
        }

    private fun decodeListString(listString: String): List<String> {
        val stream = ObjectInputStream(ByteArrayInputStream(Base64.decode(listString, 0)))
        return stream.readObject() as List<String>
    }

    var activeConfigPath: String
        get() = preferences.getString(SettingsKey.ACTIVE_CONFIG_PATH, "")!!
        set(value) = preferences.edit().putString(SettingsKey.ACTIVE_CONFIG_PATH, value).apply()

    var activeProfileName: String
        get() = preferences.getString(SettingsKey.ACTIVE_PROFILE_NAME, "")!!
        set(value) = preferences.edit().putString(SettingsKey.ACTIVE_PROFILE_NAME, value).apply()

    var serviceMode: String
        get() = preferences.getString(SettingsKey.SERVICE_MODE, ServiceMode.VPN)!!
        set(value) = preferences.edit().putString(SettingsKey.SERVICE_MODE, value).apply()

    var configOptions: String
        get() = preferences.getString(SettingsKey.CONFIG_OPTIONS, "")!!
        set(value) = preferences.edit().putString(SettingsKey.CONFIG_OPTIONS, value).apply()

    var debugMode: Boolean
        get() = preferences.getBoolean(SettingsKey.DEBUG_MODE, false)
        set(value) = preferences.edit().putBoolean(SettingsKey.DEBUG_MODE, value).apply()

    var disableMemoryLimit: Boolean
        get() = preferences.getBoolean(SettingsKey.DISABLE_MEMORY_LIMIT, false)
        set(value) =
            preferences.edit().putBoolean(SettingsKey.DISABLE_MEMORY_LIMIT, value).apply()

    var dynamicNotification: Boolean
        get() = preferences.getBoolean(SettingsKey.DYNAMIC_NOTIFICATION, true)
        set(value) =
            preferences.edit().putBoolean(SettingsKey.DYNAMIC_NOTIFICATION, value).apply()

    var systemProxyEnabled: Boolean
        get() = preferences.getBoolean(SettingsKey.SYSTEM_PROXY_ENABLED, true)
        set(value) =
            preferences.edit().putBoolean(SettingsKey.SYSTEM_PROXY_ENABLED, value).apply()

    var startedByUser: Boolean
        get() = preferences.getBoolean(SettingsKey.STARTED_BY_USER, false)
        set(value) = preferences.edit().putBoolean(SettingsKey.STARTED_BY_USER, value).apply()

    fun serviceClass(): Class<*> {
        return when (serviceMode) {
            ServiceMode.VPN -> VPNService::class.java
            else -> ProxyService::class.java
        }
    }

    private var currentServiceMode : String? = null

    suspend fun rebuildServiceMode(): Boolean {
        var newMode = ServiceMode.NORMAL
        try {
            if (serviceMode == ServiceMode.VPN) {
                newMode = ServiceMode.VPN
            }
        } catch (_: Exception) {
        }
        if (currentServiceMode == newMode) {
            return false
        }
        currentServiceMode = newMode
        return true
    }

    private suspend fun needVPNService(): Boolean {
        val filePath = activeConfigPath
        if (filePath.isBlank()) return false
        val content = JSONObject(File(filePath).readText())
        val inbounds = content.getJSONArray("inbounds")
        for (index in 0 until inbounds.length()) {
            val inbound = inbounds.getJSONObject(index)
            if (inbound.getString("type") == "tun") {
                return true
            }
        }
        return false
    }
}

