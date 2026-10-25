//
//  MethodHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/23/23.
//

import Flutter
import Combine
import HiddifyCore

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
        case "get_grpc_server_public_key":
            let key = MobileGetServerPublicKey()
            result(FlutterStandardTypedData(bytes: key ?? Data()))
        case "add_grpc_client_public_key":
            guard
                let args = call.arguments as? [String: Any?],
                let clientKey = args["clientPublicKey"] as? FlutterStandardTypedData
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            VPNConfig.shared.grpcFlutterPublicKey = clientKey.data
            let toExtension = (args["toExtension"] as? Bool) ?? false
            if toExtension {
                // Running packet tunnel has its own process; register via IPC.
                Task {
                    do {
                        try await VPNManager.shared.addGrpcClientPublicKeyToExtension(clientKey.data)
                        await mainResult("")
                    } catch {
                        await mainResult(FlutterError(code: "EXTENSION_MTLS", message: error.localizedDescription, details: nil))
                    }
                }
                return
            }
            var addError: NSError?
            MobileAddGrpcClientPublicKey(clientKey.data, &addError)
            if let addError {
                result(FlutterError(code: String(addError.code), message: addError.localizedDescription, details: nil))
                return
            }
            result("")
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
            //MobileParse(path, tempPath, debug, &error)
            if let error {
                result(FlutterError(code: String(error.code), message: error.description, details: nil))
                return
            }
            result("")
        case "change_hiddify_options":
            guard let options = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            VPNConfig.shared.configOptions = options
            result(true)
        case "setup":
                Task {
                    guard
                        let args = call.arguments as? [String: Any?],
                        let baseDir = args["baseDir"] as? String,
                        let workingDir = args["workingDir"] as? String,
                        let tempDir = args["tempDir"] as? String,
                        let mode = args["mode"] as? Int,
                        let grpcPort = args["grpcPort"] as? Int
                    else {
                        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                        return
                    }
                    VPNConfig.shared.baseDir=baseDir
                    VPNConfig.shared.workingDir=workingDir
                    VPNConfig.shared.tempDir=tempDir
                    var error: NSError?
                    let opts = MobileSetupOptions()
                    opts.basePath = baseDir
                    opts.workingDir = workingDir
                    opts.tempDir = tempDir
                    opts.listen = "127.0.0.1:\(grpcPort)"
                    opts.secret = ""
                    opts.debug = false
                    opts.mode = mode // 1 = mTLS, 3/4 = insecure
                    opts.fixAndroidStack = false
                    MobileSetup(opts,
                        nil,
                        &error
                    )
                    
                    if let error {
                        result(FlutterError(code: String(error.code), message: error.localizedDescription, details: nil))
                        return
                    }
                    do {
                        try await VPNManager.shared.setup()
                    } catch {
                        result(FlutterError(code: "SETUP", message: error.localizedDescription, details: nil))
                        return
                    }
                    await mainResult(VPNManager.shared.statusPayload())
                }
        case "setup_vpn":
            // Reload NE preferences and publish the live tunnel status (app relaunch / resume).
            Task {
                do {
                    try await VPNManager.shared.setup()
                    await mainResult(VPNManager.shared.statusPayload())
                } catch {
                    await mainResult(FlutterError(code: "SETUP", message: error.localizedDescription, details: nil))
                }
            }
        case "start":
            Task {
                guard
                    let args = call.arguments as? [String:Any?],
                    let path = args["path"] as? String,
                    let name = args["name"] as? String,
                    let grpcPort=args["grpcPort"] as? Int
                else {
                    await mainResult(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                VPNConfig.shared.activeConfigPath = path
                VPNConfig.shared.activeProfileName = name
                VPNConfig.shared.grpcServiceModePort=grpcPort
                if let clientKey = args["clientPublicKey"] as? FlutterStandardTypedData {
                    VPNConfig.shared.grpcFlutterPublicKey = clientKey.data
                }
                
                var error: NSError?
                //let configstr=MobileBuildConfig(path,&error) as String
                if let error {
                    await mainResult(FlutterError(code: String(error.code), message: error.description, details: nil))
                    return
                }
                do {
                    try await VPNManager.shared.setup()
                    try await VPNManager.shared.connect(
                        with: path,
                        grpcServiceModePort: grpcPort,
                        clientPublicKey: VPNConfig.shared.grpcFlutterPublicKey,
                        disableMemoryLimit: VPNConfig.shared.disableMemoryLimit
                    )
                } catch {
                    await mainResult(FlutterError(code: "SETUP_CONNECTION", message: error.localizedDescription, details: nil))
                    return
                }
                await mainResult(true)
            }
//        case "restart":
//            Task { [unowned self] in
//                guard
//                    let args = call.arguments as? [String:Any?],
//                    let path = args["path"] as? String,
//                    let name = args["name"] as? String,
//                    let grpcPort=args["grpcPort"] as? Int
//                else {
//                    await mainResult(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
//                    return
//                }
//                VPNConfig.shared.activeConfigPath = path
//                VPNConfig.shared.activeProfileName = name
//                VPNConfig.shared.grpcServiceModePort=grpcPort
//                
//                
//                VPNManager.shared.disconnect()
//                await waitForStop().value
//                var error: NSError?
//                do {
//                    try await VPNManager.shared.setup()
//                    try await VPNManager.shared.connect(with: path, disableMemoryLimit: VPNConfig.shared.disableMemoryLimit)
//                } catch {
//                    await mainResult(FlutterError(code: "SETUP_CONNECTION", message: error.localizedDescription, details: nil))
//                    return
//                }
//                await mainResult(true)
//            }
        case "stop":
            VPNManager.shared.disconnect()
            result(true)
        case "set_always_on":
            guard let on = call.arguments as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            Task {
                await VPNManager.shared.setAlwaysOn(on)
                await mainResult(true)
            }
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
//            let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
//            if let error {
//                result(FlutterError(code: "BUILD_CONFIG", message: error.localizedDescription, details: nil))
//                return
//            }
//            result(config)
        case "generate_warp_config":
            guard let args = call.arguments as? [String: Any],
                  let licenseKey = args["license-key"] as? String,
                  let accountId = args["previous-account-id"] as? String,
                  let accessToken = args["previous-access-token"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
//            let warpConfig = MobileGenerateWarpConfig(licenseKey, accountId, accessToken, nil)
//            result(warpConfig)
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
