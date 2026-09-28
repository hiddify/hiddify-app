//
//  ExtensionPlatformInterface.swift
//  HiddifyPacketTunnel
//

import Darwin
import Foundation
import HiddifyTunnelCore
import Network
import NetworkExtension

/// Implements libbox's platform callbacks using macOS NetworkExtension APIs.
/// Go invokes these callbacks synchronously from its worker threads.
final class ExtensionPlatformInterface: NSObject, LibboxPlatformInterfaceProtocol {
    private unowned let tunnel: ExtensionProvider
    private let monitorQueue = DispatchQueue(label: "app.hiddify.packet-tunnel.path")
    // Network snapshots are shared by the monitor queue and Go callbacks.
    private let pathLock = NSLock()
    // Serialize settings installation, DNS resets, and clearing cached settings.
    private let settingsLock = NSLock()
    private var monitor: NWPathMonitor?
    private var path: Network.NWPath?
    private var networkSettings: NEPacketTunnelNetworkSettings?

    init(_ tunnel: ExtensionProvider) { self.tunnel = tunnel }

    // MARK: - Tunnel configuration

    /// Applies the core's routes and DNS settings, then returns its utun descriptor.
    func openTun(_ options: LibboxTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
        guard let options = options, let descriptor = ret0_ else {
            throw tunnelError("Missing tunnel options.")
        }
        // NetworkExtension requires a remote address even though libbox handles
        // the transport to the actual proxy server.
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = NSNumber(value: options.getMTU())
        let v4 = prefixes(options.getInet4Address())
        let v6 = prefixes(options.getInet6Address())
        if !v4.isEmpty {
            let ipv4 = NEIPv4Settings(addresses: v4.map { $0.address() }, subnetMasks: v4.map { $0.mask() })
            if options.getAutoRoute() {
                let routes = prefixes(options.getInet4RouteRange())
                // Use the default route when the core supplies no explicit IPv4 ranges.
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
            // The empty match domain makes this resolver apply to all DNS queries.
            dnsSettings.matchDomains = [""]
            dnsSettings.matchDomainsNoSearch = true
            settings.dnsSettings = dnsSettings
        }
        settingsLock.lock()
        defer { settingsLock.unlock() }
        try applyNetworkSettings(settings)
        networkSettings = settings
        // The core reads the utun socket directly. Fall back to libbox's lookup
        // if packetFlow does not expose the descriptor.
        let fd = (tunnel.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? NSNumber)?.int32Value
            ?? LibboxGetTunnelFileDescriptor()
        guard fd >= 0 else { throw tunnelError("macOS did not provide a tunnel descriptor.") }
        descriptor.pointee = fd
    }

    private func applyNetworkSettings(_ settings: NEPacketTunnelNetworkSettings?) throws {
        try runBlocking(timeoutMessage: "macOS timed out while applying the VPN network settings.") { [self] in
            try await tunnel.setTunnelNetworkSettings(settings)
        }
    }

    private func prefixes(_ iterator: LibboxRoutePrefixIteratorProtocol?) -> [LibboxRoutePrefix] {
        var result: [LibboxRoutePrefix] = []
        while let iterator = iterator, iterator.hasNext() {
            if let prefix = iterator.next() { result.append(prefix) }
        }
        return result
    }

    // MARK: - Platform capabilities

    func localDNSTransport() -> LibboxLocalDNSTransportProtocol? { nil }
    func usePlatformAutoDetectControl() -> Bool { false }
    func autoDetectControl(_ fd: Int32) throws {}
    func useProcFS() -> Bool { false }
    func underNetworkExtension() -> Bool { true }
    func includeAllNetworks() -> Bool { false }
    func readWIFIState() -> LibboxWIFIState? { nil }
    func systemCertificates() -> LibboxStringIteratorProtocol? { nil }

    // MARK: - DNS cache

    func clearDNSCache() {
        settingsLock.lock()
        defer { settingsLock.unlock() }
        guard let networkSettings = networkSettings else { return }
        tunnel.reasserting = true
        defer { tunnel.reasserting = false }
        do {
            // The core clears its own DNS cache before this callback. Reapplying
            // the tunnel settings refreshes macOS's resolver state as well.
            try applyNetworkSettings(nil)
            try applyNetworkSettings(networkSettings)
        } catch {
            // A failed reset can leave network settings removed; stop the tunnel.
            tunnel.writeFatalError("(packet-tunnel) DNS cache reset failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notifications

    // User notification delivery is not provided by this system extension.
    func send(_ notification: LibboxNotification?) throws {}

    // MARK: - Process lookup

    func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32,
                             destinationAddress: String?, destinationPort: Int32) throws -> LibboxConnectionOwner {
        guard let sourceAddress = sourceAddress else {
            throw tunnelError("Missing source address for process lookup.")
        }
        var error: NSError?
        // Use the core's macOS process lookup; this platform does not provide procfs.
        guard let owner = TunnelFindConnectionOwner(ipProtocol, sourceAddress, sourcePort, &error) else {
            throw error ?? tunnelError("macOS could not identify the connection's process.")
        }
        return owner
    }

    // MARK: - Network interfaces

    /// Starts path monitoring and waits for the initial network-state report.
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
            // Choosing utun as the upstream interface would route the engine's
            // outbound traffic back into the VPN.
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

    /// Drops cached settings and monitoring state during provider cleanup.
    func reset() {
        // Coordinate with a DNS reset already holding the lock. Later DNS cache
        // callbacks see nil settings and return without starting another reset.
        settingsLock.lock()
        networkSettings = nil
        settingsLock.unlock()
        closeMonitor()
    }

    func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
        pathLock.lock()
        let interfaces = path?.availableInterfaces ?? []
        pathLock.unlock()
        // NWPath supplies interface names and types; getifaddrs supplies their
        // addresses, subnet masks, and flags.
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
                    // libbox expects CIDR addresses, so convert each netmask
                    // into an IPv4 or IPv6 prefix length.
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
            result.mtu = 1500 // Fallback MTU for interface metadata.
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

// MARK: - Libbox iterators

// Bridge Swift arrays to the iterator protocols exposed by the Go bindings.
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
