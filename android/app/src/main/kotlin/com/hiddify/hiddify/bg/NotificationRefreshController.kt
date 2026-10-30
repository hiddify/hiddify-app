package com.hiddify.hiddify.bg

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** A single replaceable reader; publication is serialized with close and newer requests. */
internal class NotificationRefreshController<T>(
    private val scope: CoroutineScope,
    private val fetch: suspend () -> T,
    private val publish: (T?, T) -> Unit,
    private val onError: (Exception) -> Unit,
) {
    private val lock = Any()
    private val readLock = Mutex()
    private var generation = 0L
    private var active = false
    private var job: Job? = null

    fun start() = synchronized(lock) { active = true }

    fun refresh(periodic: Boolean) = synchronized(lock) {
        if (!active) return@synchronized
        job?.cancel()
        val request = ++generation
        job = scope.launch {
            var previous: T? = null
            do {
                try {
                    // A blocking gRPC read can finish after cancellation. Keep the next read
                    // queued rather than accumulating concurrent calls during rapid switches.
                    val current = readLock.withLock { fetch() }
                    synchronized(lock) {
                        if (!active || generation != request) return@launch
                        publish(previous, current)
                    }
                    previous = current
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    onError(e)
                    previous = null
                    if (!periodic) return@launch
                }
                if (periodic) delay(1_000)
            } while (periodic)
        }
    }

    fun pause() = synchronized(lock) {
        generation++
        job?.cancel()
        job = null
    }

    fun close() = synchronized(lock) {
        active = false
        pause()
    }
}
