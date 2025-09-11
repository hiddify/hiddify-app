import Foundation
import Combine
import Libcore

public class ActiveGroupsEventHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    static let name = "\(Bundle.main.serviceIdentifier)/active-groups"
    private var commandClient: CommandClient?
    private var channel: FlutterEventChannel?
    private var events: FlutterEventSink?
    private var cancellable: AnyCancellable?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ActiveGroupsEventHandler()
        instance.channel = FlutterEventChannel(name: Self.name,
                                               binaryMessenger: registrar.messenger())
        instance.channel?.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        self.events = events
        commandClient = CommandClient(.groupsInfoOnly)
        commandClient?.connect()
        cancellable =  commandClient?.$groups.sink{ [self] sbGroups in
            self.writeGroups(sbGroups)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        commandClient?.disconnect()
        cancellable?.cancel()
        events = nil
        return nil
    }
    
    func writeGroups(_ sbGroups: [SBGroup]?) {
        guard let sbGroups else {return}
        if
            let groups = try? JSONEncoder().encode(sbGroups),
            let groups = String(data: groups, encoding: .utf8)
        {
            DispatchQueue.main.async { [events = self.events, groups] () in
                events?(groups)
            }
        }
    }
}
