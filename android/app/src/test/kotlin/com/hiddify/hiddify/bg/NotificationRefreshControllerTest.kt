package com.hiddify.hiddify.bg

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import org.junit.Assert.assertEquals
import org.junit.Test

@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
class NotificationRefreshControllerTest {
    @Test fun staticRefreshReadsOnceAndDoesNotPoll() = runTest {
        val published = mutableListOf<String>()
        val controller = NotificationRefreshController(this, { "profile B" },
            { _, current -> published.add(current) }, { throw it })
        controller.start()
        controller.refresh(periodic = false)
        runCurrent()
        advanceTimeBy(10_000)
        assertEquals(listOf("profile B"), published)
        controller.close()
    }

    @Test fun failedStaticFetchDoesNotPublishOrRetry() = runTest {
        var attempts = 0
        var errors = 0
        val published = mutableListOf<String>()
        val controller = NotificationRefreshController<String>(this,
            { attempts++; error("core unavailable") },
            { _, current -> published.add(current) }, { errors++ })
        controller.start()
        controller.refresh(false)
        runCurrent()
        advanceTimeBy(10_000)
        assertEquals(1, attempts)
        assertEquals(1, errors)
        assertEquals(emptyList<String>(), published)
        controller.close()
    }

    @Test fun lateOldResponseCannotOverwriteNewerRefresh() = runTest {
        val oldResponse = CompletableDeferred<String>()
        val published = mutableListOf<String>()
        var calls = 0
        val controller = NotificationRefreshController(this,
            { if (++calls == 1) withContext(NonCancellable) { oldResponse.await() } else "B" },
            { _, current -> published.add(current) }, { throw it })
        controller.start()
        controller.refresh(true)
        runCurrent()
        controller.refresh(false)
        controller.refresh(false)
        runCurrent()
        assertEquals(1, calls)
        oldResponse.complete("A")
        runCurrent()
        assertEquals(listOf("B"), published)
        controller.close()
    }

    @Test fun closeRejectsInFlightResponseAndRefreshWhileClosed() = runTest {
        val response = CompletableDeferred<String>()
        val published = mutableListOf<String>()
        val controller = NotificationRefreshController(this,
            { withContext(NonCancellable) { response.await() } },
            { _, current -> published.add(current) }, { throw it })
        controller.start()
        controller.refresh(false)
        runCurrent()
        controller.close()
        response.complete("A")
        controller.refresh(false)
        runCurrent()
        assertEquals(emptyList<String>(), published)
    }

    @Test fun dynamicPollingRetriesAndPauseKeepsLastPublication() = runTest {
        var calls = 0
        val published = mutableListOf<String>()
        val controller = NotificationRefreshController(this,
            { if (++calls == 1) error("not ready") else "B" },
            { _, current -> published.add(current) }, {})
        controller.start()
        controller.refresh(true)
        runCurrent()
        advanceTimeBy(1_000)
        runCurrent()
        controller.pause()
        advanceTimeBy(10_000)
        assertEquals(2, calls)
        assertEquals(listOf("B"), published)
        controller.close()
    }
}
