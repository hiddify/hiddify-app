import Cocoa
import FlutterMacOS
import XPC
import window_manager

extension NativeReceiver {
    var channelName: String {
        switch self {
        case .activeGroups:
            return "app.hiddify.com.macos/activeGroups"
        case .groups:
            return "app.hiddify.com.macos/groups"
        case .serviceStatus:
            return "app.hiddify.com.macos/serviceStatus"
        case .stats:
            return "app.hiddify.com.macos/stats"
        }
    }
}

class MainFlutterWindow: NSWindow, SingboxReceiverProtocol {
    private var flutterViewController: FlutterViewController!
    private var singboxConnection: NSXPCConnection!
    private var receiverChannels: [NativeReceiver: FlutterMethodChannel] = [:]

    override func awakeFromNib() {
        flutterViewController = FlutterViewController()
        let windowFrame = frame
        contentViewController = flutterViewController
        setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()

        if #available(macOS 13.0, *) {
            setupChannel()
        }
    }

    @available(macOS 13.0, *)
    func setupChannel() {
        let singboxChannel = FlutterMethodChannel(
            name: "app.hiddify.com.macos",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )

        singboxChannel.setMethodCallHandler(singboxHandler)
    }

    @available(macOS 13.0, *)
    private func getOrCreateReceiverChannel(for receiver: NativeReceiver) -> FlutterMethodChannel {
        if let existingChannel = receiverChannels[receiver] {
            return existingChannel
        }

        let channel = FlutterMethodChannel(
            name: receiver.channelName,
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        receiverChannels[receiver] = channel

        return channel
    }

    @available(macOS 13.0, *)
    private func setupConnection() {
        singboxConnection = NSXPCConnection(machServiceName: "app.hiddify.com.daemon.xpc")
        singboxConnection?.remoteObjectInterface = NSXPCInterface(
            with: SingboxProtocol.self
        )
        singboxConnection?.exportedInterface = NSXPCInterface(
            with: SingboxReceiverProtocol.self
        )
        singboxConnection?.exportedObject = self

        singboxConnection?.resume()

        singboxConnection?.interruptionHandler = { [weak self] in
            self?.setupConnection()
        }

        singboxConnection?.invalidationHandler = { [weak self] in
            self?.setupConnection()
        }
    }

    @available(macOS 13.0, *)
    private func getSingboxService() -> SingboxProtocol? {
        return singboxConnection?.remoteObjectProxy as? SingboxProtocol
    }

    func processMessage(receiver: NativeReceiver, message: String?) {
        if #available(macOS 13.0, *) {
            let channel = getOrCreateReceiverChannel(for: receiver)
            if let message = message {
                channel.invokeMethod("sendMessage", arguments: message)
            }
        }
    }

    @available(macOS 13.0, *)
    private func singboxHandler(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let xpcService = getSingboxService() else {
            setupConnection()
            return singboxHandler(call, result: result)
        }

        switch call.method {
        case "setupOnce":
            return xpcService.setupOnce {
                result($0)
            }
        case "setup":
            guard let args = call.arguments as? [String: Any],
                let baseDir = args["baseDir"] as? String,
                let workingDir = args["workingDir"] as? String,
                let tempDir = args["tempDir"] as? String,
                let debug = args["debug"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for setup",
                        details: nil
                    )
                )
                return
            }
            return xpcService.setup(
                baseDir: baseDir,
                workingDir: workingDir,
                tempDir: tempDir,
                debug: debug
            ) {
                result($0)
            }

        case "parse":
            guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String,
                let tempPath = args["tempPath"] as? String,
                let debug = args["debug"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for parse",
                        details: nil
                    )
                )
                return
            }
            return xpcService.parse(
                path: path,
                tempPath: tempPath,
                debug: debug
            ) {
                result($0)
            }

        case "changeHiddifyOptions":
            guard let args = call.arguments as? [String: Any],
                let options = args["options"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for changeHiddifyOptions",
                        details: nil
                    )
                )
                return
            }
            return xpcService.changeHiddifyOptions(options: options) {
                result($0)
            }

        case "generateConfig":
            guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for generateConfig",
                        details: nil
                    )
                )
                return
            }
            return xpcService.generateConfig(path: path) {
                result($0)
            }

        case "start":
            guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String,
                let disableMemoryLimit = args["disableMemoryLimit"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for start",
                        details: nil
                    )
                )
                return
            }
            return xpcService.start(
                path: path,
                disableMemoryLimit: disableMemoryLimit
            ) {
                result($0)
            }

        case "stop":
            return xpcService.stop {
                result($0)
            }

        case "restart":
            guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String,
                let disableMemoryLimit = args["disableMemoryLimit"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for restart",
                        details: nil
                    )
                )
                return
            }
            return xpcService.restart(
                path: path,
                disableMemoryLimit: disableMemoryLimit
            ) {
                result($0)
            }

        case "stopCommandClient":
            guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? Int32
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for stopCommandClient", details: nil))
                return
            }
            return xpcService.stopCommandClient(id: id) {
                result($0)
            }

        case "startCommandClient":
            guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? Int32,
                let port = args["port"] as? Int64,
                let receiver = NativeReceiver(rawValue: port)
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for startCommandClient",
                        details: nil
                    )
                )
                return
            }
            return xpcService.startCommandClient(id: id, receiver: receiver) {
                result($0)
            }

        case "selectOutbound":
            guard let args = call.arguments as? [String: Any],
                let groupTag = args["groupTag"] as? String,
                let outboundTag = args["outboundTag"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for selectOutbound",
                        details: nil
                    )
                )
                return
            }
            return xpcService.selectOutbound(
                groupTag: groupTag,
                outboundTag: outboundTag
            ) {
                result($0)
            }

        case "urlTest":
            guard let args = call.arguments as? [String: Any],
                let groupTag = args["groupTag"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for urlTest",
                        details: nil
                    )
                )
                return
            }
            return xpcService.urlTest(
                groupTag: groupTag
            ) {
                result($0)
            }

        case "generateWarpConfig":
            guard let args = call.arguments as? [String: Any],
                let licenseKey = args["licenseKey"] as? String,
                let previousAccountId = args["previousAccountId"] as? String,
                let previousAccessToken = args["previousAccessToken"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for generateWarpConfig",
                        details: nil
                    )
                )
                return
            }
            return xpcService.generateWarpConfig(
                licenseKey: licenseKey,
                previousAccountId: previousAccountId,
                previousAccessToken: previousAccessToken
            ) {
                result($0)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // window manager hidden at launch
    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }
}
