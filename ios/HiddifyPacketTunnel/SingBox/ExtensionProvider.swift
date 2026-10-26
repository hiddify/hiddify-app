import Foundation
import HiddifyCore
import NetworkExtension
import os.log

// Packet tunnel provider, following sing-box-for-apple's Library/Network/ExtensionProvider.swift,
// adapted to Hiddify's model: the extension only sets up hiddify-core with its gRPC server
// (MobileSetup); the app then starts the core through gRPC. Only when the system starts the
// tunnel (Always-on, or the switch in the iOS Settings) does the extension start the core itself.
open class ExtensionProvider: NEPacketTunnelProvider {
    public static let errorFile = FilePath.workingDirectory.appendingPathComponent("network_extension_error.log")
    private let logger = Logger(subsystem: "apple.hiddify.com.HiddifyPacketTunnel", category: "PacketTunnel")

    private var platformInterface: ExtensionPlatformInterface!
    public var tunnelOptions: [String: NSObject]?

    // as sing-box-for-apple, with Hiddify's defaults; the app may override them in the start options
    public struct OverridePreferences {
        public var includeAllNetworks: Bool = false
        public var systemProxyEnabled: Bool = false
        public var excludeDefaultRoute: Bool = false
        public var autoRouteUseSubRangesByDefault: Bool = true
        public var excludeAPNsRoute: Bool = false
    }

    public var overridePreferences: OverridePreferences?

    override public init() {
        LibboxPrepareCrashSignalHandlers()
        LibboxReinstallCrashSignalHandlers()
        super.init()
    }

    private func applyStartOptions(_ options: [String: NSObject]?) {
        tunnelOptions = options
        let defaults = OverridePreferences()
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            (options?[key] as? NSNumber)?.boolValue ?? fallback
        }
        overridePreferences = OverridePreferences(
            includeAllNetworks: flag("includeAllNetworks", defaults.includeAllNetworks),
            systemProxyEnabled: flag("systemProxyEnabled", defaults.systemProxyEnabled),
            excludeDefaultRoute: flag("excludeDefaultRoute", defaults.excludeDefaultRoute),
            autoRouteUseSubRangesByDefault: flag("autoRouteUseSubRangesByDefault", defaults.autoRouteUseSubRangesByDefault),
            excludeAPNsRoute: flag("excludeAPNsRoute", defaults.excludeAPNsRoute)
        )
    }

    override open func startTunnel(options: [String: NSObject]?) async throws {
        try? FileManager.default.removeItem(at: ExtensionProvider.errorFile)
        writeMessage("(packet-tunnel) starting")
        applyStartOptions(options)

        let disableMemoryLimit = (options?["DisableMemoryLimit"] as? NSString as? String ?? "NO") == "YES"
        let grpcServiceModePort = (options?["GrpcServiceModePort"] as? NSNumber)?.intValue ?? 17079

        do {
            try createRequiredDirectories()
        } catch {
            throw startupError("(packet-tunnel) error: create directories: \(error.localizedDescription)")
        }

        if platformInterface == nil {
            platformInterface = ExtensionPlatformInterface(self)
        }

        // hiddify-core with its gRPC server: the app starts the core through it
        // The app keeps its client identity in the shared folder exactly while it runs the core with
        // mTLS, and the core reads the certificate from there itself: nothing is passed in.
        let useMtls = FileManager.default.fileExists(
            atPath: FilePath.sharedDirectory.appendingPathComponent("grpc/client.crt").path
        )
        let setupOptions = MobileSetupOptions()
        setupOptions.basePath = FilePath.sharedDirectory.relativePath
        setupOptions.workingDir = FilePath.workingDirectory.relativePath
        setupOptions.tempDir = FilePath.cacheDirectory.relativePath
        setupOptions.listen = "127.0.0.1:\(grpcServiceModePort)"
        setupOptions.secret = ""
        setupOptions.debug = false
        setupOptions.mode = useMtls ? 2 : 4 // GRPC_BACKGROUND or GRPC_BACKGROUND_INSECURE
        setupOptions.fixAndroidStack = false
        var setupError: NSError?
        MobileSetup(setupOptions, platformInterface, &setupError)
        if let setupError {
            throw startupError("(packet-tunnel) error: setup service: \(setupError.localizedDescription)")
        }
        LibboxSetMemoryLimit(!disableMemoryLimit)

        // The app passes options; the system passes none, and no app is there to start the core.
        // An empty request makes the core start from the last one the app made, as on Android.
        if options == nil {
            writeMessage("(packet-tunnel) started by the system, starting the core from the last request")
            var startError: NSError?
            MobileStart("", "", &startError)
            if let startError {
                throw startupError("(packet-tunnel) error: start core: \(startError.localizedDescription)")
            }
            return
        }
        writeMessage("(packet-tunnel) gRPC server ready on port \(grpcServiceModePort), waiting for the app to start the core")
    }

    private func createRequiredDirectories() throws {
        for directory in [FilePath.sharedDirectory, FilePath.workingDirectory, FilePath.cacheDirectory] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func startupError(_ message: String) -> NSError {
        writeMessage(message)
        logger.fault("\(message, privacy: .public)")
        return NSError(domain: "ExtensionProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }

    func writeMessage(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        let line = "[\(Date())] \(message)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }
        if let fileHandle = try? FileHandle(forWritingTo: ExtensionProvider.errorFile) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try? data.write(to: ExtensionProvider.errorFile, options: .atomic)
        }
    }

    public func writeFatalError(_ message: String) {
        writeMessage("FATAL: \(message)")
        cancelTunnelWithError(NSError(domain: "ExtensionProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
    }

    func stopService() {
        MobileClose(2) // GRPC_BACKGROUND (mTLS)
        MobileClose(4) // GRPC_BACKGROUND_INSECURE
        platformInterface?.reset()
    }

    // called by the core (platform interface serviceReload); the app restarts the core through gRPC
    func reloadService() async throws {
        writeMessage("(packet-tunnel) reloading service")
        reasserting = true
        defer {
            reasserting = false
        }
    }

    override open func stopTunnel(with reason: NEProviderStopReason) async {
        writeMessage("(packet-tunnel) stopping, reason: \(reason.rawValue)")
        stopService()
        // as sing-box-for-apple: let the core finish closing before the extension goes away
        try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
    }

    override open func handleAppMessage(_ messageData: Data) async -> Data? {
        // Legacy echo (e.g. stats probes that the app still sends).
        return messageData
    }

    override open func sleep() async {
        // the core is not paused on sleep (pausing broke reconnecting after wake)
    }

    override open func wake() {
        MobileWake()
    }
}
