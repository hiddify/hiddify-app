//
//  Logger.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation

enum NativeDiagnosticSeverity: String, CaseIterable {
    case info
    case error
    case fault
}

final class NativeDiagnosticLog {
    enum Code: String, CaseIterable {
        case tunnelStarting = "tunnel_starting"
        case tunnelStopping = "tunnel_stopping"
        case tunnelReloading = "tunnel_reloading"
        case setupCompleted = "setup_completed"
        case serviceStarting = "service_starting"
        case serviceStarted = "service_started"
        case authenticationFailure = "authentication_failure"
        case configurationFailure = "configuration_failure"
        case dnsFailure = "dns_failure"
        case networkFailure = "network_failure"
        case permissionFailure = "permission_failure"
        case timeout = "timeout"
        case ioFailure = "io_failure"
        case nativeFailure = "native_failure"
        case nativeEvent = "native_event"
        case logRollover = "log_rollover"
    }

    static let maxFileBytes = 64 * 1_024
    static let maxEntryBytes = 256
    private static let maxInputBytes = 4_096

    private let fileURL: URL
    private let fileManager: FileManager
    private let lock = NSLock()
    private let timestampFormatter: ISO8601DateFormatter

    init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        timestampFormatter = ISO8601DateFormatter()
        timestampFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        try? fileManager.removeItem(at: fileURL)
    }

    @discardableResult
    func write(message: String, severity: NativeDiagnosticSeverity) -> Code {
        let code = Self.classify(message)
        write(code: code, severity: severity)
        return code
    }

    private static func classify(_ message: String) -> Code {
        let normalized = String(decoding: message.utf8.prefix(maxInputBytes), as: UTF8.self).lowercased()

        if normalized.contains("(packet-tunnel) starting") { return .tunnelStarting }
        if normalized.contains("(packet-tunnel) stopping") { return .tunnelStopping }
        if normalized.contains("(packet-tunnel) reloading") { return .tunnelReloading }
        if normalized.contains("setup completed successfully") { return .setupCompleted }
        if normalized.contains("starting service") { return .serviceStarting }
        if normalized.contains("service started successfully") { return .serviceStarted }
        let credentialMarkers = ["credential", "password", "passwd", "token", "secret", "authorization", "auth"]
        if containsAny(normalized, credentialMarkers) { return .authenticationFailure }
        if containsAny(normalized, ["config", "json", "inbound", "outbound"]) { return .configurationFailure }
        if normalized.contains("dns") { return .dnsFailure }
        if containsAny(normalized, ["network", "socket", "connection", "route"]) { return .networkFailure }
        if containsAny(normalized, ["permission", "denied", "not allowed"]) { return .permissionFailure }
        if containsAny(normalized, ["timeout", "timed out", "deadline"]) { return .timeout }
        if containsAny(normalized, ["directory", "file", "read", "write"]) { return .ioFailure }
        if containsAny(normalized, ["error", "failed", "failure", "fatal"]) { return .nativeFailure }
        return .nativeEvent
    }

    private static func containsAny(_ value: String, _ needles: [String]) -> Bool {
        needles.contains(where: value.contains)
    }

    private func write(code: Code, severity: NativeDiagnosticSeverity) {
        lock.lock()
        defer { lock.unlock() }

        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            var data = entryData(code: code, severity: severity)
            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
            let currentSize = (attributes?[.size] as? NSNumber)?.intValue ?? 0
            if currentSize + data.count > Self.maxFileBytes {
                data = entryData(code: .logRollover, severity: .info) + data
                try data.write(to: fileURL, options: .atomic)
                return
            }

            if fileManager.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                try data.write(to: fileURL, options: .atomic)
            }
        } catch {
            // Diagnostics must never prevent or terminate the packet tunnel.
        }
    }

    private func entryData(code: Code, severity: NativeDiagnosticSeverity) -> Data {
        let timestamp = timestampFormatter.string(from: Date())
        let entry = "timestamp=\(timestamp) severity=\(severity.rawValue) code=\(code.rawValue)\n"
        let data = Data(entry.utf8)
        if data.count <= Self.maxEntryBytes { return data }
        return Data("timestamp=unavailable severity=error code=native_failure\n".utf8)
    }
}
