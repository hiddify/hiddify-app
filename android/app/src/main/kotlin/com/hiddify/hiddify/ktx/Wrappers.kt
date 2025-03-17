package com.hiddify.hiddify.ktx

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import com.hiddify.core.libbox.RoutePrefix
import com.hiddify.core.libbox.StringIterator
import com.hiddify.core.libbox.StringBox
import java.net.InetAddress

val StringBox?.unwrap: String
get() {
    if (this == null) return ""
    return value
}

fun StringIterator.toList(): List<String> {
    return mutableListOf<String>().apply {
        while (hasNext()) {
            add(next())
        }
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())