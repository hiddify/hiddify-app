//
//  ExtensionProvider.swift
//  HiddifyPacketTunnel
//

import Foundation
import HiddifyTunnelCore
import NetworkExtension
import os.log

/// Hosts the VPN engine and handles NetworkExtension lifecycle callbacks.
///
/// Engine state is confined to engineQueue, which supports the unchecked Sendable
/// conformance. ExtensionPlatformInterface locks shared network snapshots and settings.
class ExtensionProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private let logger = Logger(subsystem: "app.hiddify.com.HiddifyPacketTunnel", category: "PacketTunnel")
    // Go can synchronously wait for Apple's network settings callback. Keep its
    // lifecycle calls serialized on a worker queue so that callback can progress.
    private let engineQueue = DispatchQueue(label: "app.hiddify.packet-tunnel.engine")
    private var platformInterface: ExtensionPlatformInterface?
    private var started = false

    // MARK: - Tunnel startup

    override func startTunnel(options: [String: NSObject]?) async throws {
        // On-demand connections must also work when the app is closed, so use
        // the saved VPN configuration rather than transient start options.
        guard let savedConfiguration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration else {
            throw tunnelError("The saved VPN configuration is incomplete. Connect from Hiddify first.")
        }
        let configuration = try SingBox.Configuration(savedConfiguration)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            engineQueue.async { [self] in
                do {
                    try startService(configuration)
                    continuation.resume()
                } catch {
                    platformInterface?.reset()
                    platformInterface = nil
                    // Startup can fail after openTun installs routes and DNS.
                    // Remove those settings before reporting the original error.
                    setTunnelNetworkSettings(nil) { settingsError in
                        if let settingsError = settingsError {
                            self.writeError("(packet-tunnel) startup cleanup failed: \(settingsError.localizedDescription)")
                        }
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Starts the core on engineQueue and returns after its tunnel settings are applied.
    private func startService(_ configuration: SingBox.Configuration) throws {
        let options = try SingBox.setupOptions(configuration: configuration)
        let platformInterface = ExtensionPlatformInterface(self)
        // Retain the adapter for the core's Go-to-Swift callbacks.
        self.platformInterface = platformInterface
        var error: NSError?
        guard TunnelStart(options, platformInterface, &error) else {
            throw error ?? tunnelError("The VPN engine failed to start.")
        }
        started = true
    }

    // MARK: - Logging

    // Lifecycle diagnostics use macOS unified logging. The app receives core
    // logs separately through gRPC, including when it reconnects to a running VPN.
    func writeMessage(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func writeError(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    /// Stops an unusable tunnel and reports its failure through NetworkExtension.
    func writeFatalError(_ message: String) {
        logger.fault("\(message, privacy: .public)")
        cancelTunnelWithError(tunnelError(message))
    }

    // MARK: - Tunnel shutdown

    override func stopTunnel(with reason: NEProviderStopReason) async {
        writeMessage("(packet-tunnel) stopping, reason: \(reason.rawValue)")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            engineQueue.async { [self] in
                do {
                    try stopService()
                } catch {
                    writeError("(packet-tunnel) shutdown failed: \(error.localizedDescription)")
                }
                // Always release callback state and remove network settings,
                // even when the core reports a shutdown error.
                platformInterface?.reset()
                platformInterface = nil
                setTunnelNetworkSettings(nil) { settingsError in
                    if let settingsError = settingsError {
                        self.writeError("(packet-tunnel) shutdown cleanup failed: \(settingsError.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
        }
        writeMessage("(packet-tunnel) stopped")
    }

    private func stopService() throws {
        guard started else { return }
        defer { started = false }
        var error: NSError?
        if !TunnelStop(&error), let error = error {
            throw error
        }
    }

    // MARK: - Sleep and wake

    override func sleep() async {
        writeMessage("(packet-tunnel) entering sleep")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            engineQueue.async {
                TunnelPause()
                continuation.resume()
            }
        }
    }

    override func wake() {
        writeMessage("(packet-tunnel) waking")
        engineQueue.async { TunnelWake() }
    }
}

/// Creates an error that NetworkExtension can surface to the app.
func tunnelError(_ message: String) -> NSError {
    NSError(domain: "app.hiddify.packet-tunnel", code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
}
