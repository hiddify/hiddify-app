//
//  Singbox.swift
//  Runner
//
//  Created by Aleksandr Strizhnev on 18.02.2025.
//

import Foundation

class Singbox: NSObject, SingboxProtocol {
    private var receiver: SingboxReceiverProtocol?
    private var singboxNative = try? SingboxDylib()

    init(receiver: SingboxReceiverProtocol? = nil) {
        self.receiver = receiver
    }

    private func portListener(_ port: Int64, _ ptr: UnsafeRawPointer?) {
        guard let ptr, let receiver = NativeReceiver(rawValue: port) else {
            return
        }
        let message = getString(from: ptr)

        self.receiver?.processMessage(
            receiver: receiver,
            message: message
        )
    }

    func setupOnce(
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            singboxNative.setPortListener(listener: self.portListener)
            completion(
                try singboxNative.setupOnce()
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func setup(
        baseDir: String,
        workingDir: String,
        tempDir: String,
        debug: Bool,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.setup(
                    baseDir: baseDir,
                    workingDir: workingDir,
                    tempDir: tempDir,
                    port: UInt64(NativeReceiver.serviceStatus.rawValue),
                    debug: debug
                )
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func parse(
        path: String,
        tempPath: String,
        debug: Bool,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.parse(path: path, tempPath: tempPath, debug: debug)
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func changeHiddifyOptions(
        options: String,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(try singboxNative.changeHiddifyOptions(options))
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func generateConfig(
        path: String,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.generateConfig(path: path)
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func start(
        path: String,
        disableMemoryLimit: Bool,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.start(path: path, disableMemoryLimit: disableMemoryLimit)
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func stop(
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.stop()
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func restart(
        path: String,
        disableMemoryLimit: Bool,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.restart(path: path, disableMemoryLimit: disableMemoryLimit)
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func stopCommandClient(
        id: Int32,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.stopCommandClient(id: id)
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func startCommandClient(
        id: Int32,
        receiver: NativeReceiver,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.startCommandClient(
                    id: id,
                    port: UInt64(receiver.rawValue)
                )
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func selectOutbound(
        groupTag: String,
        outboundTag: String,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.selectOutbound(
                    groupTag: groupTag,
                    outboundTag: outboundTag
                )
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func urlTest(
        groupTag: String,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.urlTest(
                    groupTag: groupTag
                )
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }

    func generateWarpConfig(
        licenseKey: String,
        previousAccountId: String,
        previousAccessToken: String,
        completion: (String?) -> Void
    ) {
        guard let singboxNative else {
            completion("error singbox.dylib not loaded")
            return
        }

        do {
            completion(
                try singboxNative.generateWarpConfig(
                    licenseKey: licenseKey,
                    previousAccountId: previousAccountId,
                    previousAccessToken: previousAccessToken
                )
            )
        } catch {
            completion(
                "error: \(error.localizedDescription)"
            )
        }
    }
}
