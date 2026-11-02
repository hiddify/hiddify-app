package com.hiddify.hiddify

import java.util.concurrent.atomic.AtomicInteger

/** Distinguishes an explicit notification/tile/revoke stop from an internal restart. */
object MitVpnSession {
    val stopEpoch = AtomicInteger(0)
}
