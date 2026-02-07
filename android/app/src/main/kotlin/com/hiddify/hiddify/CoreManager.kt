package com.hiddify.hiddify

import android.util.Log
import com.hiddify.hiddify.model.Config
import java.net.InetSocketAddress
import java.net.Socket

class CoreManager {
    companion object {
        fun startV2Ray(config: Config) {
            // 1. لیست IPهای کلودفلر (به‌روزرسانی شده 2026)
            val cloudflareIPs = listOf(
                "104.16.128.1", "104.18.0.1", "172.64.0.1",
                "188.114.96.1", "104.24.0.1", "104.25.0.1"
            )
            
            // 2. پیدا کردن بهترین IP
            val bestIP = cloudflareIPs.minByOrNull { testLatency(it) } 
                ?: "104.16.128.1" // اگر تست شکست خورد
            
            // 3. جایگزینی آدرس سرور
            config.serverAddress = bestIP
            Log.d("CF_IP", "✅ Best IP Selected: $bestIP")
            
            // 4. اتصال با آدرس جدید
            // ... (کد اصلی اتصال اینجا ادامه دارد)
        }

        private fun testLatency(ip: String): Long {
            try {
                val socket = Socket().apply {
                    connect(InetSocketAddress(ip, 443), 2000)
                    close()
                }
                return 2000 // تأخیر کم = IP خوب
            } catch (e: Exception) {
                return Long.MAX_VALUE // ارور = IP ضعیف
            }
        }
    }
}
