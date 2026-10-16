@_exported import CFNetwork
import Combine
import Foundation

public enum NEVPNStatus: Int {
    case invalid
    case disconnected
    case connecting
    case connected
    case reasserting
    case disconnecting
}

public enum NEOnDemandRuleInterfaceType {
    case any
}

open class NEOnDemandRule: NSObject {}

open class NEOnDemandRuleConnect: NEOnDemandRule {
    public var interfaceTypeMatch: NEOnDemandRuleInterfaceType = .any
    public var probeURL: URL?

    public override init() {
        super.init()
    }
}

open class NEVPNProtocol: NSObject {}

open class NETunnelProviderProtocol: NEVPNProtocol {
    public var providerBundleIdentifier: String?
    public var serverAddress: String?
}

open class NEVPNConnection: NSObject {
    public var status: NEVPNStatus = .disconnected

    open func startVPNTunnel(options: [String: NSObject]? = nil) throws {
        FakeNetworkExtensionState.events.append("start")
        FakeNetworkExtensionState.startCount += 1
        FakeNetworkExtensionState.lastStartOptions = options
        status = .connected
    }

    open func stopVPNTunnel() {
        FakeNetworkExtensionState.events.append("stop")
        FakeNetworkExtensionState.stopCount += 1
        status = .disconnected
    }
}

open class NETunnelProviderSession: NEVPNConnection {
    open func sendProviderMessage(_ messageData: Data, responseHandler: ((Data?) -> Void)? = nil) throws {
        responseHandler?(nil)
    }
}

public struct ManagerSnapshot {
    public let isEnabled: Bool
    public let isOnDemandEnabled: Bool
    public let onDemandRuleCount: Int
}

open class NEVPNManager: NSObject {
    private static let sharedManager = NEVPNManager()

    public static func shared() -> NEVPNManager {
        sharedManager
    }

    public var protocolConfiguration: NEVPNProtocol?
    public var localizedDescription: String?
    public var isEnabled = false
    public var onDemandRules: [NEOnDemandRule]?
    public var isOnDemandEnabled = false
    public var connection: NEVPNConnection = NETunnelProviderSession()

    public override required init() {
        super.init()
    }

    open class func loadAllFromPreferences() async throws -> [NETunnelProviderManager] {
        FakeNetworkExtensionState.events.append("load-all")
        return FakeNetworkExtensionState.loadedManagers
    }

    open func saveToPreferences() async throws {
        FakeNetworkExtensionState.recordSave(self)
    }

    open func loadFromPreferences() async throws {
        FakeNetworkExtensionState.events.append("load")
    }

    open func removeFromPreferences() async throws {
        FakeNetworkExtensionState.events.append("remove")
    }

    open func saveToPreferences(completionHandler: @escaping (Error?) -> Void) {
        FakeNetworkExtensionState.recordSave(self)
        completionHandler(nil)
    }
}

// The older Apple SDK imported loadAllFromPreferences as an implicitly
// unwrapped array. This overload preserves both call shapes used by the
// production source when the fixture is compiled by a current Swift toolchain.
public func ?? <Element>(lhs: [Element], rhs: @autoclosure () -> [Element]) -> [Element] {
    lhs
}

open class NETunnelProviderManager: NEVPNManager {}

public enum FakeNetworkExtensionState {
    public static var loadedManagers: [NETunnelProviderManager] = []
    public static var events: [String] = []
    public static var saveSnapshots: [ManagerSnapshot] = []
    public static var startCount = 0
    public static var stopCount = 0
    public static var lastStartOptions: [String: NSObject]?

    public static func reset(loadedManagers managers: [NETunnelProviderManager] = []) {
        loadedManagers = managers
        events = []
        saveSnapshots = []
        startCount = 0
        stopCount = 0
        lastStartOptions = nil
    }

    fileprivate static func recordSave(_ manager: NEVPNManager) {
        events.append("save")
        saveSnapshots.append(
            ManagerSnapshot(
                isEnabled: manager.isEnabled,
                isOnDemandEnabled: manager.isOnDemandEnabled,
                onDemandRuleCount: manager.onDemandRules?.count ?? 0
            )
        )
    }
}

public extension Notification.Name {
    static let NEVPNStatusDidChange = Notification.Name("NEVPNStatusDidChange")
}
