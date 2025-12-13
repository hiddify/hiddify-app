import Foundation
import Flutter
import Combine
import Libcore

public class StatsEventHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    static let name = "\(Bundle.main.serviceIdentifier)/stats"
    
    private var commandClient: CommandClient?
    private var channel: FlutterEventChannel?
    private var events: FlutterEventSink?
    private var cancellable: AnyCancellable?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = StatsEventHandler()
        instance.channel = FlutterEventChannel(name: Self.name,
                                               binaryMessenger: registrar.messenger(),
                                               codec: FlutterJSONMethodCodec())
        instance.channel?.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        self.events = events
        commandClient = CommandClient(.status)
        commandClient?.connect()
        cancellable =  commandClient?.$status.sink{ [self] status in
            self.writeStatus(status)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        commandClient?.disconnect()
        cancellable?.cancel()
        events = nil
        return nil
    }
    
    func writeStatus(_ message: LibboxStatusMessage?) {
        guard let message else { return }
        
        let data = [
            "connections-in": message.connectionsIn,
            "connections-out": message.connectionsOut,
            "uplink": message.uplink,
            "downlink": message.downlink,
            "uplink-total": message.uplinkTotal,
            "downlink-total": message.downlinkTotal
        ] as [String:Any]
        events?(data)
    }
}
