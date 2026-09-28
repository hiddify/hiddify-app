import Foundation
import HiddifyTunnelCore
import NetworkExtension
import os.log

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let engineQueue = DispatchQueue(label: "app.hiddify.packet-tunnel.engine")
    private var platform: ExtensionPlatformInterface?
    private var started = false

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let configuration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
              let content = configuration["configContent"] as? String, !content.isEmpty,
              let settings = configuration["settingsJSON"] as? String,
              let secret = configuration["secret"] as? String, secret.count >= 32,
              let port = configuration["port"] as? NSNumber else {
            completionHandler(tunnelError("The saved VPN configuration is incomplete. Connect from Hiddify first."))
            return
        }
        engineQueue.async { [self] in
            do {
                let root = try FileManager.default.url(
                    for: .applicationSupportDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true
                ).appendingPathComponent("HiddifyPacketTunnel", isDirectory: true)
                let work = root.appendingPathComponent("work", isDirectory: true)
                let temp = root.appendingPathComponent("temp", isDirectory: true)
                for directory in [root, work, temp, work.appendingPathComponent("data")] {
                    try FileManager.default.createDirectory(
                        at: directory, withIntermediateDirectories: true,
                        attributes: [.posixPermissions: 0o700]
                    )
                }
                let resourceDirectory = work.appendingPathComponent("resources", isDirectory: true)
                try FileManager.default.createDirectory(at: resourceDirectory, withIntermediateDirectories: true,
                                                        attributes: [.posixPermissions: 0o700])
                let resources = configuration["resources"] as? [String: Data] ?? [:]
                guard resources.values.reduce(0, { $0 + $1.count }) <= 32 * 1024 * 1024 else {
                    throw tunnelError("Saved VPN resources exceed the 32 MB limit.")
                }
                for (name, bytes) in resources {
                    guard name.range(of: "^[A-Za-z0-9][A-Za-z0-9._-]*$", options: .regularExpression) != nil else {
                        throw tunnelError("Invalid saved VPN resource name.")
                    }
                    let file = resourceDirectory.appendingPathComponent(name)
                    try bytes.write(to: file, options: .atomic)
                    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
                }
                let engineOptions = TunnelOptions()
                engineOptions.basePath = root.path
                engineOptions.workingPath = work.path
                engineOptions.tempPath = temp.path
                engineOptions.configContent = content
                engineOptions.configName = configuration["configName"] as? String ?? "Hiddify"
                engineOptions.settingsJSON = settings
                engineOptions.secret = secret
                engineOptions.port = port.int32Value
                engineOptions.disableMemoryLimit = configuration["disableMemoryLimit"] as? Bool ?? false
                let adapter = ExtensionPlatformInterface(self)
                platform = adapter
                var error: NSError?
                guard TunnelStart(engineOptions, adapter, &error) else {
                    throw error ?? tunnelError("The VPN engine failed to start.")
                }
                started = true
                completionHandler(nil)
            } catch {
                platform?.closeMonitor()
                platform = nil
                os_log("VPN startup failed: %{public}@", log: .default, type: .error, error.localizedDescription)
                // Roll back routes/DNS even when the engine failed after openTun.
                setTunnelNetworkSettings(nil) { _ in completionHandler(error) }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        engineQueue.async { [self] in
            if started {
                var error: NSError?
                if !TunnelStop(&error), let error = error {
                    os_log("VPN shutdown failed: %{public}@", log: .default, type: .error, error.localizedDescription)
                }
            }
            started = false
            platform?.closeMonitor()
            platform = nil
            setTunnelNetworkSettings(nil) { _ in completionHandler() }
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        engineQueue.async { TunnelPause(); completionHandler() }
    }

    override func wake() {
        engineQueue.async { TunnelWake() }
    }
}

func tunnelError(_ message: String) -> NSError {
    NSError(domain: "app.hiddify.packet-tunnel", code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
}
