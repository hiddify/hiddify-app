//
//  MethodHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/23/23.
//

import Flutter
import Combine
import Libcore

public class MethodHandler: NSObject, FlutterPlugin {
    
    private var cancelBag: Set<AnyCancellable> = []
    
    public static let name = "\(Bundle.main.serviceIdentifier)/method"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Self.name, binaryMessenger: registrar.messenger())
        let instance = MethodHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
    }
    
    private var channel: FlutterMethodChannel?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        @Sendable func mainResult(_ res: Any?) async -> Void {
            await MainActor.run {
                result(res)
            }
        }
        
        switch call.method {
        case "parse_config":
            guard
                let args = call.arguments as? [String:Any?],
                let path = args["path"] as? String,
                let tempPath = args["tempPath"] as? String,
                let debug = (args["debug"] as? NSNumber)?.boolValue
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            var error: NSError?
            MobileParse(path, tempPath, debug, &error)
            if let error {
                result(FlutterError(code: String(error.code), message: error.description, details: nil))
                return
            }
            result("")
        case "change_config_options":
            guard let options = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            VPNConfig.shared.configOptions = options
            result(true)
        case "setup":
            Task {
                do {
                    try await VPNManager.shared.setup()
                } catch {
                    await mainResult(FlutterError(code: "SETUP", message: error.localizedDescription, details: nil))
                    return
                }
                await mainResult(true)
            }
        case "start":
            Task {
                guard
                    let args = call.arguments as? [String:Any?],
                    let path = args["path"] as? String
                else {
                    await mainResult(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                VPNConfig.shared.activeConfigPath = path
                var error: NSError?
                let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
                if let error {
                    await mainResult(FlutterError(code: String(error.code), message: error.description, details: nil))
                    return
                }
                do {
                    try await VPNManager.shared.setup()
                    try await VPNManager.shared.connect(with: config, disableMemoryLimit: VPNConfig.shared.disableMemoryLimit)
                } catch {
                    await mainResult(FlutterError(code: "SETUP_CONNECTION", message: error.localizedDescription, details: nil))
                    return
                }
                await mainResult(true)
            }
        case "restart":
            Task { [unowned self] in
                guard
                    let args = call.arguments as? [String:Any?],
                    let path = args["path"] as? String
                else {
                    await mainResult(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                VPNConfig.shared.activeConfigPath = path
                VPNManager.shared.disconnect()
                await waitForStop().value
                var error: NSError?
                let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
                if let error {
                    await mainResult(FlutterError(code: "BUILD_CONFIG", message: error.localizedDescription, details: nil))
                    return
                }
                do {
                    try await VPNManager.shared.setup()
                    try await VPNManager.shared.connect(with: config, disableMemoryLimit: VPNConfig.shared.disableMemoryLimit)
                } catch {
                    await mainResult(FlutterError(code: "SETUP_CONNECTION", message: error.localizedDescription, details: nil))
                    return
                }
                await mainResult(true)
            }
        case "stop":
            VPNManager.shared.disconnect()
            result(true)
        case "reset":
            VPNManager.shared.reset()
            result(true)
        case "url_test":
            guard
                let args = call.arguments as? [String:Any?]
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            let group = args["groupTag"] as? String
            FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
            do {
                try LibboxNewStandaloneCommandClient()?.urlTest(group)
            } catch {
                result(FlutterError(code: "URL_TEST", message: error.localizedDescription, details: nil))
                return
            }
            result(true)
        case "select_outbound":
            guard
                let args = call.arguments as? [String:Any?],
                let group = args["groupTag"] as? String,
                let outbound = args["outboundTag"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
            do {
                try LibboxNewStandaloneCommandClient()?.selectOutbound(group, outboundTag: outbound)
            } catch {
                result(FlutterError(code: "SELECT_OUTBOUND", message: error.localizedDescription, details: nil))
                return
            }
            result(true)
        case "generate_config":
            guard
                let args = call.arguments as? [String:Any?],
                let path = args["path"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            var error: NSError?
            let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
            if let error {
                result(FlutterError(code: "BUILD_CONFIG", message: error.localizedDescription, details: nil))
                return
            }
            result(config)
        case "generate_warp_config":
            guard let args = call.arguments as? [String: Any],
                  let licenseKey = args["license-key"] as? String,
                  let accountId = args["previous-account-id"] as? String,
                  let accessToken = args["previous-access-token"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            let warpConfig = MobileGenerateWarpConfig(licenseKey, accountId, accessToken, nil)
            result(warpConfig)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func waitForStop() -> Future<Void, Never> {
        return Future { promise in
            var cancellable: AnyCancellable? = nil
            cancellable = VPNManager.shared.$state
                .filter { $0 == .disconnected }
                .first()
                .delay(for: 0.5, scheduler: RunLoop.current)
                .sink(receiveValue: { _ in
                    promise(.success(()))
                    cancellable?.cancel()
                })
        }
    }
}
