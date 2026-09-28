import Foundation
import FlutterMacOS
import NetworkExtension
import Security
import SystemExtensions

#if HIDDIFY_LOCAL_NETWORK_EXTENSION && !DEBUG
#error("Local Network Extension signing is only available in Debug builds.")
#endif

enum ExtensionActivationState {
    case idle
    case activating
    case waitingForApproval
    case activated
    case requiresReboot
    case failed(String)
}

private enum VPNErrorCode: Int {
    case failure = 1
    case approvalRequired = 2
}

final class SystemExtensionController:
    NSObject,
    OSSystemExtensionRequestDelegate {
    let extensionIdentifier = Bundle.main.object(forInfoDictionaryKey: "HiddifyTunnelBundleIdentifier") as? String
        ?? "app.hiddify.com.HiddifyPacketTunnel"
    private(set) var activationState: ExtensionActivationState = .idle
    var onStateChanged: (() -> Void)?
    private var completion: ((Error?) -> Void)?

    func makeActivationRequest() -> OSSystemExtensionRequest {
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: DispatchQueue.main
        )
        
        request.delegate = self
        return request
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        activationState = .waitingForApproval
        onStateChanged?()
        let callback = completion
        completion = nil
        callback?(vpnError("Allow the Hiddify VPN extension in System Settings, then return to Hiddify and connect again.", code: .approvalRequired))
    }
    
    func request(
        _ request: OSSystemExtensionRequest,
        didFailWithError error: Error
    ) {
        finish(.failed(error.localizedDescription), error: error)
    }
    
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
            case .completed:
                finish(.activated, error: nil)
            case .willCompleteAfterReboot:
                finish(.requiresReboot, error: vpnError("Restart your Mac to finish installing the Hiddify VPN extension."))
            @unknown default:
                finish(.failed("Unknown activation result"), error: vpnError("macOS returned an unknown extension activation result."))
        }
    }
    
    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension replacement: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    
    func activate(completion: @escaping (Error?) -> Void) {
        if case .activated = activationState { completion(nil); return }
        if case .activating = activationState {
            completion(vpnError("macOS is still installing the Hiddify system extension. Try connecting again when it finishes."))
            return
        }
        if case .waitingForApproval = activationState {
            completion(vpnError("Allow the Hiddify VPN extension in System Settings, then return to Hiddify and connect again.", code: .approvalRequired))
            return
        }
        guard self.completion == nil else {
            completion(vpnError("An extension activation request is already in progress."))
            return
        }
        self.completion = completion
        activationState = .activating
        onStateChanged?()
        let request = makeActivationRequest()
        OSSystemExtensionManager.shared.submitRequest(request)
    }

    private func finish(_ state: ExtensionActivationState, error: Error?) {
        activationState = state
        onStateChanged?()
        let callback = completion
        completion = nil
        callback?(error)
    }

    func cancelPendingActivation() {
        let callback = completion
        completion = nil
        callback?(vpnError("VPN connection cancelled."))
    }
}

// Retained by MainFlutterWindow. All preference, connection and Flutter calls
// run on the main queue; the extension runs the actual VPN engine separately.
final class MacOSVPNController: NSObject, FlutterStreamHandler {
    private let activation = SystemExtensionController()
    private var manager: NETunnelProviderManager?
    private var eventSink: FlutterEventSink?
    private var observer: NSObjectProtocol?
    private var pendingConnection: ((Error?) -> Void)?
    private var waitingForConnection = false
    private var sawConnecting = false
    private var operationID = UUID()
    private var busy = false
    private var cancelRequested = false
    private var queuedStop: FlutterResult?
    private let enabled = Bundle.main.object(forInfoDictionaryKey: "HiddifyNetworkExtensionEnabled") as? String == "YES"

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        let methods = FlutterMethodChannel(name: "com.hiddify.app/macos-vpn", binaryMessenger: messenger)
        methods.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        FlutterEventChannel(name: "com.hiddify.app/macos-vpn-status", binaryMessenger: messenger).setStreamHandler(self)
        activation.onStateChanged = { [weak self] in self?.emitStatus() }
    }

    deinit { if let observer = observer { NotificationCenter.default.removeObserver(observer) } }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        emitStatus()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "initialize" || call.method == "status" {
            guard enabled else { result(status()); return }
            load { [weak self] error in
                if let error = error { result(Self.flutterError(error)) }
                else { result(self?.status()); self?.emitStatus() }
            }
            return
        }
        guard enabled else {
            result(Self.flutterError(vpnError("VPN is unavailable in the local Debug build. Build with an authorized Apple team and enable HIDDIFY_NETWORK_EXTENSION_ENABLED to use the system extension. Proxy modes are available.")))
            return
        }
        if busy && call.method == "stop" {
            guard queuedStop == nil else {
                result(Self.flutterError(vpnError("The VPN is already stopping."))); return
            }
            queuedStop = result
            cancelRequested = true
            if pendingConnection != nil && waitingForConnection {
                finishConnection(vpnError("VPN connection cancelled."))
            } else {
                activation.cancelPendingActivation()
            }
            return
        }
        guard !busy else {
            result(Self.flutterError(vpnError("A VPN operation is already in progress.")))
            return
        }
        busy = true
        let finish: (Error?) -> Void = { [weak self] error in
            self?.busy = false
            self?.emitStatus()
            if let error = error { result(Self.flutterError(error)) }
            else { result(self?.status()) }
            if let self = self, let queued = self.queuedStop {
                self.queuedStop = nil
                self.cancelRequested = false
                self.handle(FlutterMethodCall(methodName: "stop", arguments: nil), result: queued)
            }
        }
        switch call.method {
        case "start":
            guard let arguments = call.arguments as? [String: Any],
                  let content = arguments["configContent"] as? String, !content.isEmpty,
                  arguments["settingsJSON"] is String else {
                finish(vpnError("Missing VPN configuration.")); return
            }
            do { try checkSigning() } catch { finish(error); return }
            activation.activate { [weak self] error in
                guard let self = self else { return }
                if let error = error { finish(error); return }
                self.load { error in
                    if let error = error { finish(error); return }
                    self.start(arguments: arguments, completion: finish)
                }
            }
        case "stop":
            load { [weak self] error in
                if let error = error { finish(error); return }
                self?.stop(completion: finish)
            }
        case "reset":
            load { [weak self] error in
                guard let self = self else { return }
                if let error = error { finish(error); return }
                self.stop { error in
                    if let error = error { finish(error); return }
                    guard let manager = self.manager else { finish(nil); return }
                    manager.removeFromPreferences { error in
                        DispatchQueue.main.async {
                            if error == nil { self.manager = nil; self.observeConnection() }
                            finish(error)
                        }
                    }
                }
            }
        default:
            busy = false
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkSigning() throws {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var information: CFDictionary?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code = code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode = staticCode,
              SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let info = information as? [String: Any],
              let entitlements = info[kSecCodeInfoEntitlementsDict as String] as? [String: Any],
              entitlements["com.apple.developer.system-extension.install"] as? Bool == true,
              let providers = entitlements["com.apple.developer.networking.networkextension"] as? [String],
              providers.contains("packet-tunnel-provider") || providers.contains("packet-tunnel-provider-systemextension") else {
            throw vpnError("This build is not signed for Network Extension. Select an authorized Apple Developer team for Runner and HiddifyPacketTunnel.")
        }
        let hasTeam = info[kSecCodeInfoTeamIdentifier as String] as? String != nil
        #if DEBUG && HIDDIFY_LOCAL_NETWORK_EXTENSION
        // Only the explicit local build accepts ad hoc signing. macOS still
        // validates activation; this does not bypass SIP, AMFI or OS approval.
        let signatureFlags = (info[kSecCodeInfoFlags as String] as? NSNumber)?.uint32Value ?? 0
        let localAdHoc = Bundle.main.object(forInfoDictionaryKey: "HiddifyLocalNetworkExtensionBuild") as? String == "YES"
            && SecCodeSignatureFlags(rawValue: signatureFlags).contains(.adhoc)
        guard hasTeam || localAdHoc else {
            throw vpnError("Use the local VPN build script or an authorized Apple Developer team.")
        }
        #else
        guard hasTeam else {
            throw vpnError("This build is not signed for Network Extension. Select an authorized Apple Developer team for Runner and HiddifyPacketTunnel.")
        }
        #endif
        let extensionURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/SystemExtensions/\(activation.extensionIdentifier).systemextension")
        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            throw vpnError("The packet tunnel system extension is missing from this app bundle.")
        }
    }

    private func load(completion: @escaping (Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error { completion(error); return }
                self.manager = managers?.first {
                    ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.activation.extensionIdentifier
                }
                self.observeConnection()
                completion(nil)
            }
        }
    }

    private func observeConnection() {
        if let observer = observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        guard let manager = manager else { return }
        observer = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: manager.connection, queue: .main) { [weak self] _ in
            self?.connectionChanged()
        }
    }

    private func start(arguments: [String: Any], completion: @escaping (Error?) -> Void) {
        guard !cancelRequested else { completion(vpnError("VPN connection cancelled.")); return }
        let manager = self.manager ?? NETunnelProviderManager()
        self.manager = manager
        observeConnection()
        guard manager.connection.status != .connected && manager.connection.status != .connecting && manager.connection.status != .reasserting else {
            completion(vpnError("Disconnect the active VPN before changing its configuration.")); return
        }
        do {
            let old = (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = activation.extensionIdentifier
            proto.serverAddress = "Hiddify"
            proto.disconnectOnSleep = false
            let secret = try old?["secret"] as? String ?? randomSecret()
            proto.providerConfiguration = [
                "configContent": arguments["configContent"]!,
                "settingsJSON": arguments["settingsJSON"]!,
                "configName": arguments["configName"] as? String ?? "Hiddify",
                "disableMemoryLimit": arguments["disableMemoryLimit"] as? Bool ?? false,
                "port": old?["port"] as? Int ?? Int(arc4random_uniform(40000)) + 20000,
                "secret": secret,
            ]
            var resources: [String: Data] = [:]
            for (name, value) in arguments["resources"] as? [String: FlutterStandardTypedData] ?? [:] {
                resources[name] = value.data
            }
            proto.providerConfiguration?["resources"] = resources
            manager.protocolConfiguration = proto
            manager.localizedDescription = "Hiddify VPN"
            manager.isEnabled = true
            let rule = NEOnDemandRuleConnect()
            rule.interfaceTypeMatch = .any
            manager.onDemandRules = [rule]
            manager.isOnDemandEnabled = true
            saveAndReload(manager) { [weak self] error in
                guard let self = self else { return }
                if let error = error { completion(error); return }
                self.waitForConnection(connected: true, completion: completion)
                if self.cancelRequested { self.finishConnection(vpnError("VPN connection cancelled.")); return }
                do {
                    guard let session = manager.connection as? NETunnelProviderSession else {
                        throw vpnError("macOS did not create a packet tunnel session.")
                    }
                    if session.status != .connected && session.status != .connecting && session.status != .reasserting {
                        try session.startVPNTunnel()
                    }
                }
                catch { self.finishConnection(error) }
                self.connectionChanged()
            }
        } catch { completion(error) }
    }

    private func stop(completion: @escaping (Error?) -> Void) {
        guard let manager = manager else { completion(nil); return }
        // Disable on demand before stopping, or macOS may immediately reconnect.
        manager.isOnDemandEnabled = false
        saveAndReload(manager) { [weak self, manager] error in
            guard let self = self else { return }
            if let error = error { completion(error); return }
            if manager.connection.status == .disconnected || manager.connection.status == .invalid {
                completion(nil); return
            }
            self.waitForConnection(connected: false, completion: completion)
            manager.connection.stopVPNTunnel()
            self.connectionChanged()
        }
    }

    private func saveAndReload(_ manager: NETunnelProviderManager, completion: @escaping (Error?) -> Void) {
        manager.saveToPreferences { [weak self] error in
            if let error = error { DispatchQueue.main.async { completion(error) }; return }
            manager.loadFromPreferences { [weak self] error in
                DispatchQueue.main.async { self?.observeConnection(); completion(error) }
            }
        }
    }

    private func waitForConnection(connected: Bool, completion: @escaping (Error?) -> Void) {
        operationID = UUID()
        let currentID = operationID
        waitingForConnection = connected
        sawConnecting = false
        pendingConnection = completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let self = self, self.operationID == currentID, self.pendingConnection != nil else { return }
            if connected { self.manager?.connection.stopVPNTunnel() }
            self.finishConnection(vpnError("macOS timed out while \(connected ? "starting" : "stopping") the VPN."))
        }
    }

    private func connectionChanged() {
        emitStatus()
        guard pendingConnection != nil, let connection = manager?.connection else { return }
        if connection.status == .connecting || connection.status == .reasserting { sawConnecting = true }
        if waitingForConnection && connection.status == .connected { finishConnection(nil) }
        else if !waitingForConnection && (connection.status == .disconnected || connection.status == .invalid) { finishConnection(nil) }
        else if waitingForConnection && connection.status == .invalid {
            finishConnection(vpnError("macOS rejected the VPN configuration."))
        } else if waitingForConnection && sawConnecting && connection.status == .disconnected {
            if #available(macOS 13.0, *) {
                let currentID = operationID
                connection.fetchLastDisconnectError { [weak self] error in
                    DispatchQueue.main.async {
                        guard self?.operationID == currentID else { return }
                        self?.finishConnection(error ?? vpnError("The packet tunnel failed to start. See the HiddifyPacketTunnel logs in Console."))
                    }
                }
            } else {
                finishConnection(vpnError("The packet tunnel failed to start. See the HiddifyPacketTunnel logs in Console."))
            }
        }
    }

    private func finishConnection(_ error: Error?) {
        guard let callback = pendingConnection else { return }
        pendingConnection = nil
        operationID = UUID()
        if let error = error, waitingForConnection, let manager = manager {
            // A failed Connect must not leave an on-demand profile retrying in
            // the background after the UI has reported a failure.
            manager.isOnDemandEnabled = false
            saveAndReload(manager) { _ in
                manager.connection.stopVPNTunnel()
                callback(error)
            }
        } else {
            callback(error)
        }
    }

    private func status() -> [String: Any] {
        var result: [String: Any] = ["available": enabled, "status": "disconnected", "activation": "idle"]
        switch activation.activationState {
        case .idle: break
        case .activating: result["activation"] = "activating"
        case .waitingForApproval:
            result["activation"] = "waitingForApproval"
            result["message"] = "Allow the Hiddify VPN extension in System Settings, then return to Hiddify and connect again."
        case .activated: result["activation"] = "activated"
        case .requiresReboot: result["activation"] = "requiresReboot"
        case .failed(let message): result["activation"] = "failed"; result["message"] = message
        }
        if let manager = manager {
            switch manager.connection.status {
            case .connected: result["status"] = "connected"
            case .connecting: result["status"] = "connecting"
            case .reasserting: result["status"] = "reasserting"
            case .disconnecting: result["status"] = "disconnecting"
            default: break
            }
            let config = (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
            result["port"] = config?["port"]
            result["secret"] = config?["secret"]
        }
        return result
    }

    private func emitStatus() { eventSink?(status()) }
    private static func flutterError(_ error: Error) -> FlutterError {
        let nativeError = error as NSError
        let needsApproval = nativeError.domain == "app.hiddify.macos-vpn"
            && nativeError.code == VPNErrorCode.approvalRequired.rawValue
        return FlutterError(code: needsApproval ? "MACOS_VPN_APPROVAL_REQUIRED" : "MACOS_VPN",
                            message: error.localizedDescription, details: nil)
    }
    private func randomSecret() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw vpnError("Unable to create secure VPN credentials.")
        }
        return Data(bytes).base64EncodedString()
    }
}

private func vpnError(_ message: String, code: VPNErrorCode = .failure) -> NSError {
    NSError(domain: "app.hiddify.macos-vpn", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
}
