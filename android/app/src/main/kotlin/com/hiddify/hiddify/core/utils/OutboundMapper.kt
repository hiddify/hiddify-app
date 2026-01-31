package com.hiddify.hiddify.core.utils

import com.google.gson.annotations.SerializedName
import com.hiddify.hiddify.core.model.OutboundGroup
import com.hiddify.hiddify.core.model.OutboundGroupItem

data class ParsedOutboundGroup(
    @SerializedName("tag") val tag: String,
    @SerializedName("type") val type: String,
    @SerializedName("selected") val selected: String,
    @SerializedName("items") val items: List<ParsedOutboundGroupItem>
) {
    companion object {
        fun fromOutbound(group: OutboundGroup): ParsedOutboundGroup {
            val items = group.items.map { ParsedOutboundGroupItem(it) }
            return ParsedOutboundGroup(group.tag, group.type, group.selected, items)
        }
    }
}

data class ParsedOutboundGroupItem(
    @SerializedName("tag") val tag: String,
    @SerializedName("type") val type: String,
    @SerializedName("url-test-delay") val urlTestDelay: Int,
) {
    constructor(item: OutboundGroupItem) : this(item.tag, item.type, item.urlTestDelay)
}