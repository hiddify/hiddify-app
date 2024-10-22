package com.hiddify.hiddify.ktx

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import com.hiddify.core.libbox.RoutePrefix
import com.hiddify.core.libbox.StringIterator
import java.net.InetAddress

fun StringIterator.toList(): List<String> {
    return mutableListOf<String>().apply {
        while (hasNext()) {
            add(next())
        }
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())