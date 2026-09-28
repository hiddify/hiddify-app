import Darwin
import Foundation
import HiddifyTunnelCore
import Network
import NetworkExtension

// Go calls openTun synchronously on the engine queue. Waiting for Apple's
// asynchronous settings callback never blocks the app or provider main queue.
final class ExtensionPlatformInterface: NSObject, LibboxPlatformInterfaceProtocol {
    private unowned let tunnel: PacketTunnelProvider
    private let monitorQueue = DispatchQueue(label: "app.hiddify.packet-tunnel.path")
    private let pathLock = NSLock()
    private var monitor: NWPathMonitor?
    private var path: Network.NWPath?

    init(_ tunnel: PacketTunnelProvider) { self.tunnel = tunnel }

    func openTun(_ options: LibboxTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
        guard let options = options, let descriptor = ret0_ else {
            throw tunnelError("Missing tunnel options.")
        }
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = NSNumber(value: options.getMTU())
        let v4 = prefixes(options.getInet4Address())
        let v6 = prefixes(options.getInet6Address())
        if !v4.isEmpty {
            let ipv4 = NEIPv4Settings(addresses: v4.map { $0.address() }, subnetMasks: v4.map { $0.mask() })
            if options.getAutoRoute() {
                let routes = prefixes(options.getInet4RouteRange())
                ipv4.includedRoutes = routes.isEmpty ? [NEIPv4Route.default()] : routes.map {
                    NEIPv4Route(destinationAddress: $0.address(), subnetMask: $0.mask())
                }
                ipv4.excludedRoutes = prefixes(options.getInet4RouteExcludeAddress()).map {
                    NEIPv4Route(destinationAddress: $0.address(), subnetMask: $0.mask())
                }
            }
            settings.ipv4Settings = ipv4
        }
        if !v6.isEmpty {
            let ipv6 = NEIPv6Settings(addresses: v6.map { $0.address() }, networkPrefixLengths: v6.map {
                NSNumber(value: $0.prefix())
            })
            if options.getAutoRoute() {
                let routes = prefixes(options.getInet6RouteRange())
                ipv6.includedRoutes = routes.isEmpty ? [NEIPv6Route.default()] : routes.map {
                    NEIPv6Route(destinationAddress: $0.address(), networkPrefixLength: NSNumber(value: $0.prefix()))
                }
                ipv6.excludedRoutes = prefixes(options.getInet6RouteExcludeAddress()).map {
                    NEIPv6Route(destinationAddress: $0.address(), networkPrefixLength: NSNumber(value: $0.prefix()))
                }
            }
            settings.ipv6Settings = ipv6
        }
        if options.getAutoRoute() {
            let dns = try options.getDNSServerAddress()
            let dnsSettings = NEDNSSettings(servers: [dns.value])
            dnsSettings.matchDomains = [""]
            dnsSettings.matchDomainsNoSearch = true
            settings.dnsSettings = dnsSettings
        }
        let applied = DispatchSemaphore(value: 0)
        var settingsError: Error?
        tunnel.setTunnelNetworkSettings(settings) { error in
            settingsError = error
            applied.signal()
        }
        guard applied.wait(timeout: .now() + 30) == .success else {
            throw tunnelError("macOS timed out while applying the VPN network settings.")
        }
        if let error = settingsError { throw error }
        // This is the same libbox utun integration used by the iOS provider.
        let fd = (tunnel.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? NSNumber)?.int32Value
            ?? LibboxGetTunnelFileDescriptor()
        guard fd >= 0 else { throw tunnelError("macOS did not provide a tunnel descriptor.") }
        descriptor.pointee = fd
    }

    private func prefixes(_ iterator: LibboxRoutePrefixIteratorProtocol?) -> [LibboxRoutePrefix] {
        var result: [LibboxRoutePrefix] = []
        while let iterator = iterator, iterator.hasNext() {
            if let prefix = iterator.next() { result.append(prefix) }
        }
        return result
    }

    func localDNSTransport() -> LibboxLocalDNSTransportProtocol? { nil }
    func usePlatformAutoDetectControl() -> Bool { false }
    func autoDetectControl(_ fd: Int32) throws {}
    func useProcFS() -> Bool { false }
    func underNetworkExtension() -> Bool { true }
    func includeAllNetworks() -> Bool { false }
    func readWIFIState() -> LibboxWIFIState? { nil }
    func systemCertificates() -> LibboxStringIteratorProtocol? { nil }
    func clearDNSCache() {}
    func send(_ notification: LibboxNotification?) throws {}

    func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32,
                             destinationAddress: String?, destinationPort: Int32) throws -> LibboxConnectionOwner {
        throw tunnelError("Process ownership rules are unavailable in the macOS packet tunnel.")
    }

    func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        guard let listener = listener else { return }
        closeMonitor()
        let monitor = NWPathMonitor()
        let initialUpdate = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.pathLock.lock()
            self.path = path
            self.pathLock.unlock()
            if path.status == .satisfied,
               let interface = path.availableInterfaces.first(where: {
                   !$0.name.hasPrefix("utun") && path.usesInterfaceType($0.type)
               }) ?? path.availableInterfaces.first(where: { !$0.name.hasPrefix("utun") }) {
                listener.updateDefaultInterface(interface.name, interfaceIndex: Int32(interface.index),
                                                isExpensive: path.isExpensive, isConstrained: path.isConstrained)
            } else {
                listener.updateDefaultInterface("", interfaceIndex: -1, isExpensive: false, isConstrained: false)
            }
            initialUpdate.signal()
        }
        self.monitor = monitor
        monitor.start(queue: monitorQueue)
        guard initialUpdate.wait(timeout: .now() + 10) == .success else {
            closeMonitor()
            throw tunnelError("macOS did not report an underlying network interface.")
        }
    }

    func closeDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws { closeMonitor() }
    func closeMonitor() {
        monitor?.cancel()
        monitor = nil
        pathLock.lock()
        path = nil
        pathLock.unlock()
    }

    func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
        pathLock.lock()
        let interfaces = path?.availableInterfaces ?? []
        pathLock.unlock()
        var addresses: [String: [String]] = [:]
        var flags: [String: Int32] = [:]
        var first: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&first) == 0, let first = first {
            defer { freeifaddrs(first) }
            var current: UnsafeMutablePointer<ifaddrs>? = first
            while let entry = current {
                defer { current = entry.pointee.ifa_next }
                let name = String(cString: entry.pointee.ifa_name)
                flags[name] = Int32(entry.pointee.ifa_flags)
                guard let addr = entry.pointee.ifa_addr,
                      addr.pointee.sa_family == AF_INET || addr.pointee.sa_family == AF_INET6 else { continue }
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let address = String(cString: host).components(separatedBy: "%")[0]
                    var prefix = addr.pointee.sa_family == AF_INET ? 32 : 128
                    if let mask = entry.pointee.ifa_netmask {
                        if addr.pointee.sa_family == AF_INET {
                            prefix = mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                                $0.pointee.sin_addr.s_addr.nonzeroBitCount
                            }
                        } else {
                            var bits = mask.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee.sin6_addr }
                            prefix = withUnsafeBytes(of: &bits) { bytes in bytes.reduce(0) { $0 + $1.nonzeroBitCount } }
                        }
                    }
                    addresses[name, default: []].append("\(address)/\(prefix)")
                }
            }
        }
        let results = interfaces.filter { !$0.name.hasPrefix("utun") }.map { interface -> LibboxNetworkInterface in
            let result = LibboxNetworkInterface()
            result.name = interface.name
            result.index = Int32(interface.index)
            result.mtu = 1500
            result.flags = flags[interface.name] ?? 0
            result.addresses = StringIterator(addresses[interface.name] ?? [])
            switch interface.type {
            case .wifi: result.type = LibboxInterfaceTypeWIFI
            case .cellular: result.type = LibboxInterfaceTypeCellular
            case .wiredEthernet: result.type = LibboxInterfaceTypeEthernet
            default: result.type = LibboxInterfaceTypeOther
            }
            return result
        }
        return InterfaceIterator(results)
    }
}

private final class StringIterator: NSObject, LibboxStringIteratorProtocol {
    private var items: [String]
    private var index = 0
    init(_ items: [String]) { self.items = items }
    func hasNext() -> Bool { index < items.count }
    func next() -> String { defer { index += 1 }; return items[index] }
    func len() -> Int32 { Int32(items.count) }
}

private final class InterfaceIterator: NSObject, LibboxNetworkInterfaceIteratorProtocol {
    private var items: [LibboxNetworkInterface]
    private var index = 0
    init(_ items: [LibboxNetworkInterface]) { self.items = items }
    func hasNext() -> Bool { index < items.count }
    func next() -> LibboxNetworkInterface? { defer { index += 1 }; return items[index] }
}
