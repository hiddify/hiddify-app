import Foundation
import Libcore

public class CommandClient: ObservableObject {
    public enum ConnectionType {
        case status
        case groups
        case log
        case groupsInfoOnly
    }
    
    private let connectionType: ConnectionType
    private let logMaxLines: Int
    private var commandClient: LibboxCommandClient?
    private var connectTask: Task<Void, Error>?
    
    @Published private(set) var isConnected: Bool
    @Published private(set) var status: LibboxStatusMessage?
    @Published private(set) var groups: [SBGroup]?
    @Published private(set) var logList: [String]
    
    public init(_ connectionType: ConnectionType, logMaxLines: Int = 300) {
        self.connectionType = connectionType
        self.logMaxLines = logMaxLines
        logList = []
        isConnected = false
    }
    
    public func connect() {
        if isConnected {
            return
        }
        if let connectTask {
            connectTask.cancel()
        }
        connectTask = Task {
            await connect0()
        }
    }
    
    public func disconnect() {
        if let connectTask {
            connectTask.cancel()
            self.connectTask = nil
        }
        if let commandClient {
            try? commandClient.disconnect()
            self.commandClient = nil
        }
    }
    
    private nonisolated func connect0() async {
        let clientOptions = LibboxCommandClientOptions()
        switch connectionType {
        case .status:
            clientOptions.command = LibboxCommandStatus
        case .groups:
            clientOptions.command = LibboxCommandGroup
        case .log:
            clientOptions.command = LibboxCommandLog
        case .groupsInfoOnly:
            clientOptions.command = LibboxCommandGroupInfoOnly
        }
        clientOptions.statusInterval = Int64(2 * NSEC_PER_SEC)
        let client = LibboxNewCommandClient(clientHandler(self), clientOptions)!
        do {
            for i in 0 ..< 10 {
                try await Task.sleep(nanoseconds: UInt64(Double(100 + (i * 50)) * Double(NSEC_PER_MSEC)))
                try Task.checkCancellation()
                do {
                    try client.connect()
                    await MainActor.run {
                        commandClient = client
                    }
                    return
                } catch {}
                try Task.checkCancellation()
            }
        } catch {
            try? client.disconnect()
        }
    }
    
    private class clientHandler: NSObject, LibboxCommandClientHandlerProtocol {
        private let commandClient: CommandClient
        
        init(_ commandClient: CommandClient) {
            self.commandClient = commandClient
        }
        
        func connected() {
            DispatchQueue.main.async { [self] in
                if commandClient.connectionType == .log {
                    commandClient.logList = []
                }
                commandClient.isConnected = true
            }
        }
        
        func disconnected(_: String?) {
            DispatchQueue.main.async { [self] in
                commandClient.isConnected = false
            }
        }
        
        func clearLog() {
            DispatchQueue.main.async { [self] in
                commandClient.logList.removeAll()
            }
        }
        
        func writeLog(_ message: String?) {
            guard let message else {
                return
            }
            DispatchQueue.main.async { [self] in
                if commandClient.logList.count > commandClient.logMaxLines {
                    commandClient.logList.removeFirst()
                }
                commandClient.logList.append(message)
            }
        }
        
        func writeStatus(_ message: LibboxStatusMessage?) {
            DispatchQueue.main.async { [self] in
                commandClient.status = message
            }
        }
        
        func writeGroups(_ groups: LibboxOutboundGroupIteratorProtocol?) {
            guard let groups else {
                return
            }
            var sbGroups = [SBGroup]()
            while groups.hasNext() {
                let group = groups.next()!
                var items = [SBItem]()
                let groupItems = group.getItems()
                while groupItems?.hasNext() ?? false {
                    let item = groupItems?.next()!
                    items.append(SBItem(tag: item!.tag,
                                        type: item!.type,
                                        urlTestDelay: Int(item!.urlTestDelay)
                                       )
                    )
                }
                
                sbGroups.append(.init(tag: group.tag,
                                      type: group.type,
                                      selected: group.selected,
                                      items: items)
                )
                
            }
            DispatchQueue.main.async { [self] in
                commandClient.groups = sbGroups
            }
        }
        
        func initializeClashMode(_ modeList: LibboxStringIteratorProtocol?, currentMode: String?) {
        }
        
        func updateClashMode(_ newMode: String?) {
        }
    }
}
