//
//  Extension+RunBlocking.swift
//  HiddifyPacketTunnel
//

import Foundation

/// Bridges synchronous Go callbacks to asynchronous Swift operations.
///
/// Call from a worker thread, never the provider's main queue. The timeout bounds
/// the caller's wait; cancellation does not guarantee that Apple's operation stops.
func runBlocking<T>(timeout: TimeInterval = 30, timeoutMessage: String,
                    _ block: @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = BlockingResult<T>()
    // A detached task can progress independently while the calling thread waits.
    let task = Task.detached {
        do {
            box.result = .success(try await block())
        } catch {
            box.result = .failure(error)
        }
        semaphore.signal()
    }
    guard semaphore.wait(timeout: .now() + timeout) == .success else {
        task.cancel()
        throw tunnelError(timeoutMessage)
    }
    guard let result = box.result else {
        throw tunnelError("The network settings operation completed without a result.")
    }
    return try result.get()
}

/// Carries the detached task's result back to the waiting thread.
/// The result is written before signaling and read only after a successful wait.
private final class BlockingResult<T> {
    var result: Result<T, Error>?
}
