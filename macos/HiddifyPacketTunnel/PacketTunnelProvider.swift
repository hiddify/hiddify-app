//
//  PacketTunnelProvider.swift
//  HiddifyPacketTunnel
//

import NetworkExtension

/// Entry point registered in Info.plist for the macOS packet tunnel.
/// Records startup results while ExtensionProvider manages the engine lifecycle.
/// Traffic statistics are delivered to the app through the core's gRPC stream.
final class PacketTunnelProvider: ExtensionProvider, @unchecked Sendable {
    override func startTunnel(options: [String: NSObject]?) async throws {
        writeMessage("(packet-tunnel) starting")
        do {
            try await super.startTunnel(options: options)
            writeMessage("(packet-tunnel) started")
        } catch {
            writeError("(packet-tunnel) startup failed: \(error.localizedDescription)")
            throw error
        }
    }
}
