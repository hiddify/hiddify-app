package com.hiddify.hiddify.utils

import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException

private const val TAG = "A/MethodResult"

/**
 * Answers the call with what [block] returns, or with an error when it throws: every call gets
 * exactly one answer. Handlers used to run in `result.runCatching { ... success(...) }`, which
 * swallowed a failure without answering, and the Dart side awaited the call for ever.
 */
suspend fun MethodChannel.Result.answer(method: String, block: suspend () -> Any?) {
    val value = try {
        block()
    } catch (e: CancellationException) {
        error(method, "cancelled", null)
        throw e
    } catch (e: Throwable) {
        Log.w(TAG, "$method failed", e)
        error(method, e.message ?: e.toString(), null)
        return
    }
    success(value)
}

/** [answer] for a handler that does not suspend. */
fun MethodChannel.Result.answerNow(method: String, block: () -> Any?) {
    val value = try {
        block()
    } catch (e: Throwable) {
        Log.w(TAG, "$method failed", e)
        error(method, e.message ?: e.toString(), null)
        return
    }
    success(value)
}
