import Foundation
import Combine
import Libcore

class LogsEventHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    static let name = "\(Bundle.main.serviceIdentifier)/service.logs"
    
    private var commandClient: CommandClient?
    private var events: FlutterEventSink?
    private var channel: FlutterEventChannel?
    private var cancellable: AnyCancellable?

    public static func register(with registrar: FlutterPluginRegistrar) {
          let instance = LogsEventHandler()
          instance.channel = FlutterEventChannel(name: Self.name,
                                                 binaryMessenger: registrar.messenger())
          instance.channel?.setStreamHandler(instance)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        self.events = events
        commandClient = CommandClient(.log)
        commandClient?.connect()
        cancellable =  commandClient?.$logList.sink{ [self] logs in
            events(logs)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        commandClient?.disconnect()
        cancellable?.cancel()
        events = nil
        return nil
    }
}

/*
extension LogsEventHandler {
    public func clearLog() {}
    public func connected() {}
    public func disconnected(_ message: String?) {}
    public func initializeClashMode(_ modeList: LibboxStringIteratorProtocol?, currentMode: String?) {}
    public func updateClashMode(_ newMode: String?) {}
    public func writeGroups(_ message: LibboxOutboundGroupIteratorProtocol?) {}
    public func writeStatus(_ message: LibboxStatusMessage?) {}
}
*/
