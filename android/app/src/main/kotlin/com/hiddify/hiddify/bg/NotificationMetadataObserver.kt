package com.hiddify.hiddify.bg

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

/** Observes core metadata even with the screen/speed display off; no traffic polling. */
internal class NotificationMetadataObserver<T>(
    private val scope: CoroutineScope,
    private val source: () -> Flow<T>,
    private val publish: (T) -> Unit,
    private val onError: (Exception) -> Unit,
) {
    private val lock = Any()
    private var generation = 0L
    private var job: Job? = null

    fun start() = synchronized(lock) {
        job?.cancel()
        val session = ++generation
        job = scope.launch {
            var retryDelay = 1_000L
            while (true) {
                try {
                    source().collect { value ->
                        synchronized(lock) {
                            if (generation == session) publish(value)
                        }
                        retryDelay = 1_000L
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    onError(e)
                }
                // Streams also end normally when the core restarts. Reconnect in the service,
                // independently of whether a Flutter activity is alive to reopen the stream.
                delay(retryDelay)
                retryDelay = (retryDelay * 2).coerceAtMost(30_000L)
            }
        }
    }

    fun close() = synchronized(lock) {
        generation++
        job?.cancel()
        job = null
    }
}
