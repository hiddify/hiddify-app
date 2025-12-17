package com.hiddify.hiddify.core.model

import com.hiddify.hiddify.core.constant.Alert
import com.hiddify.hiddify.core.constant.Status

data class ServiceEvent(
    val status: Status,
    val alert: Alert? = null,
    val message: String? = null,
)
