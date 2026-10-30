package com.hiddify.hiddify.bg

import com.hiddify.core.api.v2.hcore.OutboundGroupList

/** MainOutboundsInfo supplies the same display labels used by Flutter's active-proxy card. */
internal fun notificationOutboundText(groups: OutboundGroupList): String? {
    val main = groups.items.firstOrNull { it.tag == "select" } ?: return null
    val selected = main.items.firstOrNull { it.tag == main.selected || it.is_selected }
        ?: main.items.firstOrNull() ?: return null
    val name = selected.tag_display.ifBlank { selected.tag.substringBefore('§').trim() }
    val detail = selected.group_selected_tag_display.orEmpty().trim()
    // The core normally already appends the selected node/strategy to tag_display.
    // Retain that label verbatim, including lowest/balance and chain-hop descriptions.
    return when {
        name.isBlank() -> detail.ifBlank { null }
        detail.isBlank() || name == detail || name.endsWith(" → $detail") -> name
        else -> "$name → $detail"
    }
}
