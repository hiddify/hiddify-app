package com.hiddify.hiddify.core.model

data class StatusMessage(
    val connectionsIn: Long = 0,
    val connectionsOut: Long = 0,
    val uplink: Long = 0,
    val downlink: Long = 0,
    val uplinkTotal: Long = 0,
    val downlinkTotal: Long = 0
)

data class OutboundGroup(
    val tag: String,
    val type: String,
    val selected: String,
    val items: List<OutboundGroupItem> = emptyList()
)

data class OutboundGroupItem(
    val tag: String,
    val type: String,
    val urlTestDelay: Int
)
