//
//  SingBox.swift
//  HiddifyPacketTunnel
//

import Foundation
import HiddifyTunnelCore

/// Prepares saved configuration and local resources for the tunnel core.
final class SingBox {
    /// Typed snapshot of NETunnelProviderProtocol.providerConfiguration.
    struct Configuration {
        let configContent: String
        let configName: String
        let settingsJSON: String
        let secret: String
        let port: Int32
        let disableMemoryLimit: Bool
        let resources: [String: Data]

        init(_ values: [String: Any]) throws {
            guard let content = values["configContent"] as? String, !content.isEmpty,
                  let settings = values["settingsJSON"] as? String,
                  let secret = values["secret"] as? String, secret.count >= 32,
                  let port = values["port"] as? NSNumber else {
                throw tunnelError("The saved VPN configuration is incomplete. Connect from Hiddify first.")
            }
            self.configContent = content
            self.configName = values["configName"] as? String ?? "Hiddify"
            self.settingsJSON = settings
            self.secret = secret
            self.port = port.int32Value
            self.disableMemoryLimit = values["disableMemoryLimit"] as? Bool ?? false
            self.resources = values["resources"] as? [String: Data] ?? [:]
        }
    }

    /// Restores resources in the extension's working directory and builds core options.
    static func setupOptions(configuration: Configuration) throws -> TunnelOptions {
        // The app and system extension have separate working directories. Local
        // resources must remain available here when the app is no longer running.
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ).appendingPathComponent("HiddifyPacketTunnel", isDirectory: true)
        let work = root.appendingPathComponent("work", isDirectory: true)
        let temp = root.appendingPathComponent("temp", isDirectory: true)
        // These directories can contain profile data and private key material.
        for directory in [root, work, temp, work.appendingPathComponent("data")] {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
        let resourceDirectory = work.appendingPathComponent("resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resourceDirectory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let resources = configuration.resources
        // Match the app's snapshot limit before writing saved resources to disk.
        guard resources.values.reduce(0, { $0 + $1.count }) <= 32 * 1024 * 1024 else {
            throw tunnelError("Saved VPN resources exceed the 32 MB limit.")
        }
        for (name, bytes) in resources {
            // Accept only single file names so resources stay inside this directory.
            guard name.range(of: "^[A-Za-z0-9][A-Za-z0-9._-]*$", options: .regularExpression) != nil else {
                throw tunnelError("Invalid saved VPN resource name.")
            }
            let file = resourceDirectory.appendingPathComponent(name)
            try bytes.write(to: file, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        }
        // The app rewrites local file references as resources/<name>, relative
        // to the core's working directory.
        let options = TunnelOptions()
        options.basePath = root.path
        options.workingPath = work.path
        options.tempPath = temp.path
        options.configContent = configuration.configContent
        options.configName = configuration.configName
        options.settingsJSON = configuration.settingsJSON
        options.secret = configuration.secret
        options.port = configuration.port
        options.disableMemoryLimit = configuration.disableMemoryLimit
        return options
    }
}
