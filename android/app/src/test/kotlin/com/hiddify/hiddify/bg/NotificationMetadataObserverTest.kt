package com.hiddify.hiddify.bg

import com.hiddify.core.api.v2.hcore.OutboundGroup
import com.hiddify.core.api.v2.hcore.OutboundGroupList
import com.hiddify.core.api.v2.hcore.OutboundInfo
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
class NotificationMetadataObserverTest {
    private fun group(mode: String, detail: String = "") = OutboundGroupList(items = listOf(
        OutboundGroup(tag = "select", selected = mode, items = listOf(OutboundInfo(
            tag = mode, tag_display = mode, is_selected = true, group_selected_tag_display = detail,
        )))
    ))

    @Test fun formatsManualLowestAndBalanceWithoutDuplicatingCoreLabels() {
        assertEquals("server A", notificationOutboundText(group("server A")))
        assertEquals("lowest → server A", notificationOutboundText(group("lowest", "server A")))
        assertEquals("balance → round-robin", notificationOutboundText(group("balance", "round-robin")))
        assertEquals("lowest → server B", notificationOutboundText(group("lowest → server B", "server B")))
        assertNull(notificationOutboundText(OutboundGroupList()))
    }

    @Test fun automaticSelectionChangesArriveWithoutARefreshHookOrSpeedPolling() = runTest {
        val events = MutableSharedFlow<OutboundGroupList>()
        val labels = mutableListOf<String?>()
        val observer = NotificationMetadataObserver(this,
            { events.map(::notificationOutboundText).distinctUntilChanged() }, labels::add, { throw it })
        observer.start()
        runCurrent()
        events.emit(group("lowest", "server A"))
        events.emit(group("lowest", "server A")) // traffic-only update
        events.emit(group("lowest", "server B")) // core selected a new node
        events.emit(group("balance", "round-robin"))
        runCurrent()
        assertEquals(listOf("lowest → server A", "lowest → server B", "balance → round-robin"), labels)
        observer.close()
    }

    @Test fun reconnectsAfterFailureAndNormalCoreRestart() = runTest {
        var attempts = 0
        var errors = 0
        val values = mutableListOf<String>()
        val observer = NotificationMetadataObserver(this, { flow {
            when (++attempts) {
                1 -> error("core not ready")
                2 -> emit("first core") // stream ends on core restart
                else -> { emit("restarted core"); awaitCancellation() }
            }
        } }, values::add, { errors++ })
        observer.start()
        runCurrent()
        advanceTimeBy(1_000); runCurrent()
        advanceTimeBy(1_000); runCurrent()
        assertEquals(1, errors)
        assertEquals(listOf("first core", "restarted core"), values)
        observer.close()
    }

    @Test fun closeAndNewSessionDiscardLateEventsAndCancelTheSource() = runTest {
        val release = CompletableDeferred<Unit>()
        val values = mutableListOf<String>()
        var opens = 0
        var closes = 0
        val observer = NotificationMetadataObserver(this, { flow {
            val session = ++opens
            try {
                if (session == 1) withContext(NonCancellable) { release.await() }
                emit("session $session")
                awaitCancellation()
            } finally { closes++ }
        } }, values::add, {})
        observer.start(); runCurrent()
        observer.start(); runCurrent()
        release.complete(Unit); runCurrent()
        observer.close(); runCurrent()
        advanceTimeBy(60_000)
        assertEquals(listOf("session 2"), values)
        assertEquals(2, opens)
        assertEquals(2, closes)
    }
}
