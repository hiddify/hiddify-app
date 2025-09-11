package com.hiddify.hiddify.utils

import com.google.gson.annotations.SerializedName
import io.nekohasekai.libbox.OutboundGroup
import io.nekohasekai.libbox.OutboundGroupItem

data class ParsedOutboundGroup(
    @SerializedName("tag") val tag: String,
    @SerializedName("type") val type: String,
    @SerializedName("selected") val selected: String,
    @SerializedName("items") val items: List<ParsedOutboundGroupItem>
) {
    companion object {
        fun fromOutbound(group: OutboundGroup): ParsedOutboundGroup {
            val outboundItems = group.items
            val items = mutableListOf<ParsedOutboundGroupItem>()
            while (outboundItems.hasNext()) {
                items.add(ParsedOutboundGroupItem(outboundItems.next()))
            }
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