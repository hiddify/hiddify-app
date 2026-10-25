//
//  ExtensionPlatformInterface.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/25/1402 AP.
//

import Foundation
import HiddifyCore
import Network
import NetworkExtension
import UserNotifications

public class ExtensionPlatformInterface: NSObject, LibboxPlatformInterfaceProtocol {
    
    
    private var tunnel: ExtensionProvider
    private var networkSettings: NEPacketTunnelNetworkSettings?

    init(_ tunnel: ExtensionProvider) {
        self.tunnel = tunnel
    }

    public func openTun(_ options: LibboxTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
        try runBlocking { [self] in
            try await openTun0(options, ret0_)
        }
    }

    private func openTun0(_ options: LibboxTunOptionsProtocol?, _ ret0_: UnsafeMutablePointer<Int32>?) async throws {
        guard let options else {
            throw NSError(domain: "ExtensionPlatformInterface", code: 0, userInfo: [NSLocalizedDescriptionKey: String(localized: "Nil options")])
        }
        guard let ret0_ else {
            throw NSError(domain: "ExtensionPlatformInterface", code: 0, userInfo: [NSLocalizedDescriptionKey: String(localized: "Nil return pointer")])
        }

        let prefs = tunnel.overridePreferences ?? ExtensionProvider.OverridePreferences()
        let autoRouteUseSubRangesByDefault = prefs.autoRouteUseSubRangesByDefault
        let excludeAPNs = prefs.excludeAPNsRoute
        let excludeDefaultRoute = prefs.excludeDefaultRoute
        let systemProxyEnabled = prefs.systemProxyEnabled

        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "::1")
        if options.getAutoRoute() {
            settings.mtu = NSNumber(value: options.getMTU())

            // the DNS servers of the TUN (none when its DNS mode is disabled), as sing-box-for-apple
            let dnsEnabled = options.getDNSMode()?.value != LibboxDNSModeDisabled
            var dnsServers: [String] = []
            if dnsEnabled {
                let dnsServerIterator = try options.getDNSServerAddress()
                while dnsServerIterator.hasNext() {
                    dnsServers.append(dnsServerIterator.next())
                }
            }
            
            var ipv4Address: [String] = []
            var ipv4Mask: [String] = []
            let ipv4AddressIterator = options.getInet4Address()!
            while ipv4AddressIterator.hasNext() {
                let ipv4Prefix = ipv4AddressIterator.next()!
                ipv4Address.append(ipv4Prefix.address())
                ipv4Mask.append(ipv4Prefix.mask())
            }
            let ipv4Settings = NEIPv4Settings(addresses: ipv4Address, subnetMasks: ipv4Mask)
            var ipv4Routes: [NEIPv4Route] = []
            var ipv4ExcludeRoutes: [NEIPv4Route] = []

            let inet4RouteAddressIterator = options.getInet4RouteAddress()!
            if inet4RouteAddressIterator.hasNext() {
                while inet4RouteAddressIterator.hasNext() {
                    let ipv4RoutePrefix = inet4RouteAddressIterator.next()!
                    ipv4Routes.append(NEIPv4Route(destinationAddress: ipv4RoutePrefix.address(), subnetMask: ipv4RoutePrefix.mask()))
                }
            } else if autoRouteUseSubRangesByDefault {
                ipv4Routes.append(NEIPv4Route(destinationAddress: "1.0.0.0", subnetMask: "255.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "2.0.0.0", subnetMask: "254.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "4.0.0.0", subnetMask: "252.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "8.0.0.0", subnetMask: "248.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "16.0.0.0", subnetMask: "240.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "32.0.0.0", subnetMask: "224.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "64.0.0.0", subnetMask: "192.0.0.0"))
                ipv4Routes.append(NEIPv4Route(destinationAddress: "128.0.0.0", subnetMask: "128.0.0.0"))
                ipv4Routes.append(NEIPv4Route.default())
            } else {
                ipv4Routes.append(NEIPv4Route.default())
            }

            let inet4RouteExcludeAddressIterator = options.getInet4RouteExcludeAddress()!
            while inet4RouteExcludeAddressIterator.hasNext() {
                let ipv4RoutePrefix = inet4RouteExcludeAddressIterator.next()!
                ipv4ExcludeRoutes.append(NEIPv4Route(destinationAddress: ipv4RoutePrefix.address(), subnetMask: ipv4RoutePrefix.mask()))
            }
            if excludeDefaultRoute, !ipv4Routes.isEmpty {
                if !ipv4ExcludeRoutes.contains(where: { it in
                    it.destinationAddress == "0.0.0.0" && it.destinationSubnetMask == "255.255.255.254"
                }) {
                    ipv4ExcludeRoutes.append(NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "255.255.255.254"))
                }
            }
            if excludeAPNs, !ipv4Routes.isEmpty {
                if !ipv4ExcludeRoutes.contains(where: { it in
                    it.destinationAddress == "17.0.0.0" && it.destinationSubnetMask == "255.0.0.0"
                }) {
                    ipv4ExcludeRoutes.append(NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"))
                }
           }
            ipv4Settings.includedRoutes = ipv4Routes
            ipv4Settings.excludedRoutes = ipv4ExcludeRoutes
            settings.ipv4Settings = ipv4Settings

            var ipv6Address: [String] = []
            var ipv6Prefixes: [NSNumber] = []
            let ipv6AddressIterator = options.getInet6Address()!
            while ipv6AddressIterator.hasNext() {
                let ipv6Prefix = ipv6AddressIterator.next()!
                ipv6Address.append(ipv6Prefix.address())
                ipv6Prefixes.append(NSNumber(value: ipv6Prefix.prefix()))
            }
            let ipv6Settings = NEIPv6Settings(addresses: ipv6Address, networkPrefixLengths: ipv6Prefixes)
            var ipv6Routes: [NEIPv6Route] = []
            var ipv6ExcludeRoutes: [NEIPv6Route] = []

            let inet6RouteAddressIterator = options.getInet6RouteAddress()!
            if inet6RouteAddressIterator.hasNext() {
                while inet6RouteAddressIterator.hasNext() {
                    let ipv6RoutePrefix = inet6RouteAddressIterator.next()!
                    ipv6Routes.append(NEIPv6Route(destinationAddress: ipv6RoutePrefix.address(), networkPrefixLength: NSNumber(value: ipv6RoutePrefix.prefix())))
                }
            } else if autoRouteUseSubRangesByDefault {
                ipv6Routes.append(NEIPv6Route(destinationAddress: "100::", networkPrefixLength: 8))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "200::", networkPrefixLength: 7))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "400::", networkPrefixLength: 6))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "800::", networkPrefixLength: 5))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "1000::", networkPrefixLength: 4))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "2000::", networkPrefixLength: 3))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "4000::", networkPrefixLength: 2))
                ipv6Routes.append(NEIPv6Route(destinationAddress: "8000::", networkPrefixLength: 1))
                ipv6Routes.append(NEIPv6Route.default())
            } else {
                ipv6Routes.append(NEIPv6Route.default())
            }

            let inet6RouteExcludeAddressIterator = options.getInet6RouteExcludeAddress()!
            while inet6RouteExcludeAddressIterator.hasNext() {
                let ipv6RoutePrefix = inet6RouteExcludeAddressIterator.next()!
                ipv6ExcludeRoutes.append(NEIPv6Route(destinationAddress: ipv6RoutePrefix.address(), networkPrefixLength: NSNumber(value: ipv6RoutePrefix.prefix())))
            }
            if excludeDefaultRoute, !ipv6Routes.isEmpty {
                if !ipv6ExcludeRoutes.contains(where: { it in
                    it.destinationAddress == "::" && it.destinationNetworkPrefixLength == 127
                }) {
                    ipv6ExcludeRoutes.append(NEIPv6Route(destinationAddress: "::", networkPrefixLength: 127))
                }
            }
            ipv6Settings.includedRoutes = ipv6Routes
            ipv6Settings.excludedRoutes = ipv6ExcludeRoutes
            settings.ipv6Settings = ipv6Settings

            // Hiddify's IPv6 fix: with an IPv6 TUN address, also offer an IPv6 DNS server (the TUN
            // address; DNS to it is hijacked) when the core gave none, for IPv6-only networks
            if dnsEnabled, let tunIPv6 = ipv6Address.first, !dnsServers.contains(where: { $0.contains(":") }) {
                dnsServers.append(tunIPv6)
            }
            let dnsSettings: NEDNSSettings? = dnsServers.isEmpty ? nil : NEDNSSettings(servers: dnsServers)

            // without a default route, the TUN's DNS must still answer every domain
            let hasDefaultRoute = ipv4Routes.contains(where: {
                $0.destinationAddress == "0.0.0.0" && $0.destinationSubnetMask == "0.0.0.0"
            })
            if !hasDefaultRoute {
                dnsSettings?.matchDomains = [""]
                dnsSettings?.matchDomainsNoSearch = true
            }
            settings.dnsSettings = dnsSettings
        }

        if options.isHTTPProxyEnabled() {
            let proxySettings = NEProxySettings()
            let proxyServer = NEProxyServer(address: options.getHTTPProxyServer(), port: Int(options.getHTTPProxyServerPort()))
            proxySettings.httpServer = proxyServer
            proxySettings.httpsServer = proxyServer
            if systemProxyEnabled {
                proxySettings.httpEnabled = true
                proxySettings.httpsEnabled = true
            }

            var bypassDomains: [String] = []
            let bypassDomainIterator = options.getHTTPProxyBypassDomain()!
            while bypassDomainIterator.hasNext() {
                bypassDomains.append(bypassDomainIterator.next())
            }

            if excludeAPNs {
                if !bypassDomains.contains(where: { it in
                    it == "push.apple.com"
                }) {
                    bypassDomains.append("push.apple.com")
                }
            }

            if !bypassDomains.isEmpty {
                proxySettings.exceptionList = bypassDomains
            }

            var matchDomains: [String] = []

            let matchDomainIterator = options.getHTTPProxyMatchDomain()!

            while matchDomainIterator.hasNext() {
                matchDomains.append(matchDomainIterator.next())
            }

            if !matchDomains.isEmpty {
                proxySettings.matchDomains = matchDomains
            }
            settings.proxySettings = proxySettings
        }

        networkSettings = settings
        try await tunnel.setTunnelNetworkSettings(settings)

        if let tunFd = tunnel.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 {
            ret0_.pointee = tunFd
            return
        }

        let tunFdFromLoop = LibboxGetTunnelFileDescriptor()
        if tunFdFromLoop != -1 {
            ret0_.pointee = tunFdFromLoop
        } else {
            throw NSError(domain: "missing file descriptor", code: 0)
        }
    }

    public func usePlatformAutoDetectControl() -> Bool {
        false
    }

    public func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32, destinationAddress: String?, destinationPort: Int32) throws -> LibboxConnectionOwner {
        #if os(macOS)
            if Variant.useSystemExtension {
                guard let sourceAddress, let destinationAddress else {
                    throw NSError(domain: "findConnectionOwner", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Missing source or destination address",
                    ])
                }
                let owner = try RootHelperClient.shared.findConnectionOwner(
                    ipProtocol: ipProtocol,
                    sourceAddress: sourceAddress,
                    sourcePort: sourcePort,
                    destinationAddress: destinationAddress,
                    destinationPort: destinationPort
                )
                let result = LibboxConnectionOwner()
                result.userId = owner.userId
                result.userName = owner.userName
                result.processPath = owner.processPath
                return result
            }
        #endif
        throw NSError(domain: "ExtensionPlatformInterface", code: 0, userInfo: [NSLocalizedDescriptionKey: String(localized: "Not implemented")])
    }

    public func useProcFS() -> Bool {
        false
    }

    public func writeLog(_ message: String?) {
        guard let message else {
            return
        }
        tunnel.writeMessage(message)
    }

    private var nwMonitor: NWPathMonitor?
    private var lastNetworkPath: String?

    // the core needs the current physical interface (Wi-Fi/cellular) to bind its connections to,
    // as sing-box-for-apple; it waits for the first update
    public func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        guard let listener else {
            return
        }
        let monitor = NWPathMonitor()
        nwMonitor = monitor
        let semaphore = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { path in
            self.onUpdateDefaultInterface(listener, path)
            semaphore.signal()
            monitor.pathUpdateHandler = { path in
                self.onUpdateDefaultInterface(listener, path)
            }
        }
        monitor.start(queue: DispatchQueue.global())
        semaphore.wait()
    }

    private func onUpdateDefaultInterface(_ listener: LibboxInterfaceUpdateListenerProtocol, _ path: Network.NWPath) {
        let networkPath = describeNetworkPath(path)
        listener.updateNetworkPath(networkPath)
        if networkPath == lastNetworkPath {
            return
        }
        lastNetworkPath = networkPath
        guard path.status != .unsatisfied,
              let defaultInterface = path.availableInterfaces.first
        else {
            listener.updateDefaultInterface("", interfaceIndex: -1, isExpensive: false, isConstrained: false)
            return
        }
        listener.updateDefaultInterface(defaultInterface.name, interfaceIndex: Int32(defaultInterface.index), isExpensive: path.isExpensive, isConstrained: path.isConstrained)
    }

    private func describeNetworkPath(_ path: Network.NWPath) -> String {
        var components: [String] = []
        switch path.status {
        case .satisfied:
            components.append("satisfied")
        case .unsatisfied:
            components.append("unsatisfied(\(path.unsatisfiedReason))")
        case .requiresConnection:
            components.append("requiresConnection")
        @unknown default:
            components.append("unknown")
        }
        if !path.availableInterfaces.isEmpty {
            components.append("interfaces=" + path.availableInterfaces.map { "\($0.name)#\($0.index)/\($0.type)" }.joined(separator: ","))
        }
        if !path.gateways.isEmpty {
            components.append("gateways=" + path.gateways.map { "\($0)" }.sorted().joined(separator: ","))
        }
        if path.supportsIPv4 {
            components.append("ipv4")
        }
        if path.supportsIPv6 {
            components.append("ipv6")
        }
        if path.supportsDNS {
            components.append("dns")
        }
        if path.isExpensive {
            components.append("expensive")
        }
        if path.isConstrained {
            components.append("constrained")
        }
        return components.joined(separator: " ")
    }

    public func closeDefaultInterfaceMonitor(_: LibboxInterfaceUpdateListenerProtocol?) throws {
        nwMonitor?.cancel()
        nwMonitor = nil
        lastNetworkPath = nil
    }

    public func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
        guard let nwMonitor else {
            throw NSError(domain: "ExtensionPlatformInterface", code: 0, userInfo: [NSLocalizedDescriptionKey: String(localized: "NWMonitor not started")])
        }
        let path = nwMonitor.currentPath
        if path.status == .unsatisfied {
            return networkInterfaceArray([])
        }
        var interfaces: [LibboxNetworkInterface] = []
        for it in path.availableInterfaces {
            let interface = LibboxNetworkInterface()
            interface.name = it.name
            interface.index = Int32(it.index)
            switch it.type {
            case .wifi:
                interface.type = LibboxInterfaceTypeWIFI
            case .cellular:
                interface.type = LibboxInterfaceTypeCellular
            case .wiredEthernet:
                interface.type = LibboxInterfaceTypeEthernet
            default:
                interface.type = LibboxInterfaceTypeOther
            }
            interfaces.append(interface)
        }
        return networkInterfaceArray(interfaces)
    }

    class networkInterfaceArray: NSObject, LibboxNetworkInterfaceIteratorProtocol {
        private var iterator: IndexingIterator<[LibboxNetworkInterface]>
        init(_ array: [LibboxNetworkInterface]) {
            iterator = array.makeIterator()
        }

        private var nextValue: LibboxNetworkInterface?

        func hasNext() -> Bool {
            nextValue = iterator.next()
            return nextValue != nil
        }

        func next() -> LibboxNetworkInterface? {
            nextValue
        }
    }

    public func underNetworkExtension() -> Bool {
        true
    }

    public func includeAllNetworks() -> Bool {
        #if os(tvOS)
            return false
        #else
            return tunnel.overridePreferences?.includeAllNetworks ?? false
        #endif
    }

    public func clearDNSCache() {
        guard let networkSettings else {
            return
        }
        runBlocking {
            self.tunnel.reasserting = true
            defer { self.tunnel.reasserting = false }
            await withCheckedContinuation { continuation in
                self.tunnel.setTunnelNetworkSettings(nil) { _ in
                    continuation.resume()
                }
            }
            await withCheckedContinuation { continuation in
                self.tunnel.setTunnelNetworkSettings(networkSettings) { _ in
                    continuation.resume()
                }
            }
        }
    }

    public func readWIFIState() -> LibboxWIFIState? {
//        #if os(iOS)
//            let network = runBlocking {
//                await NEHotspotNetwork.fetchCurrent()
//            }
//            guard let network else {
//                return nil
//            }
//            return LibboxWIFIState(network.ssid, wifiBSSID: network.bssid)!
//        #elseif os(macOS)
//            if Variant.useSystemExtension {
//                return UserServiceClient.shared.readWIFIState()
//            }
//            guard let interface = CWWiFiClient.shared().interface() else {
//                return nil
//            }
//            guard let ssid = interface.ssid() else {
//                return nil
//            }
//            guard let bssid = interface.bssid() else {
//                return nil
//            }
//            return LibboxWIFIState(ssid, wifiBSSID: bssid)!
//        #else
            return nil
//        #endif
    }

    public func readWIFISSID() -> String? {
//        #if os(iOS)
//            return runBlocking {
//                await NEHotspotNetwork.fetchCurrent()?.ssid
//            }
//        #elseif os(macOS)
//            return CWWiFiClient.shared().interface()?.ssid()
//        #else
            return nil
//        #endif
    }

//    public func serviceStop() throws {
//        tunnel.stopService()
//    }

    public func serviceReload() throws {
        try runBlocking { [self] in
            try await tunnel.reloadService()
        }
    }

    public func getSystemProxyStatus() throws -> LibboxSystemProxyStatus {
        let status = LibboxSystemProxyStatus()
        guard let networkSettings else {
            return status
        }
        guard let proxySettings = networkSettings.proxySettings else {
            return status
        }
        if proxySettings.httpServer == nil {
            return status
        }
        status.available = true
        status.enabled = proxySettings.httpEnabled
        return status
    }

    public func setSystemProxyEnabled(_ isEnabled: Bool) throws {
        guard let networkSettings else {
            return
        }
        guard let proxySettings = networkSettings.proxySettings else {
            return
        }
        if proxySettings.httpServer == nil {
            return
        }
        if proxySettings.httpEnabled == isEnabled {
            return
        }
        proxySettings.httpEnabled = isEnabled
        proxySettings.httpsEnabled = isEnabled
        networkSettings.proxySettings = proxySettings
        try runBlocking {
            try await self.tunnel.setTunnelNetworkSettings(networkSettings)
        }
    }

    public func writeDebugMessage(_ message: String?) {
        guard let message else {
            return
        }
        NSLog("%@", message)
    }

    func reset() {
        networkSettings = nil
        nwMonitor?.cancel()
        nwMonitor = nil
        lastNetworkPath = nil
    }

    public func send(_ notification: LibboxNotification?) throws {
        #if !os(tvOS)
            guard let notification else {
                return
            }
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.subtitle = notification.subtitle
            content.body = notification.body
            if !notification.openURL.isEmpty {
                content.userInfo["OPEN_URL"] = notification.openURL
                content.categoryIdentifier = "OPEN_URL"
            }
            content.interruptionLevel = .active
            let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: nil)
            try runBlocking {
                try await center.requestAuthorization(options: [.alert])
                try await center.add(request)
            }
        #endif
    }

    public func localDNSTransport() -> (any LibboxLocalDNSTransportProtocol)? {
        nil
    }

    public func systemCertificates() -> (any LibboxStringIteratorProtocol)? {
        nil
    }
    public func autoDetectControl(_: Int32) throws {}

    // MARK: - not available in the packet tunnel extension

    private func notSupported(_ feature: String) -> NSError {
        NSError(domain: "ExtensionPlatformInterface", code: 0, userInfo: [NSLocalizedDescriptionKey: "\(feature) is not supported in the packet tunnel"])
    }

    public func usePlatformShell() -> Bool {
        false
    }

    public func checkPlatformShell() throws {
        throw notSupported("Platform shell")
    }

    public func lookupUser(_: String?) throws -> LibboxPlatformUser {
        throw notSupported("User lookup")
    }

    public func openShellSession(_: LibboxPlatformUser?, command _: String?, environ _: (any LibboxStringIteratorProtocol)?, term _: String?, rows _: Int32, cols _: Int32) throws -> any LibboxShellSessionProtocol {
        throw notSupported("Shell session")
    }

    public func lookupSFTPServer() throws -> LibboxStringBox {
        throw notSupported("SFTP server")
    }

    public func readSystemSSHHostKey() throws -> LibboxStringBox {
        throw notSupported("System SSH host key")
    }

    public func usePlatformBridge() -> Bool {
        false
    }

    public func createBridge(_: LibboxBridgeOptions?) throws -> any LibboxBridgeSessionProtocol {
        throw notSupported("Platform bridge")
    }

    public func usePlatformAutoRedirect() -> Bool {
        false
    }

    public func createAutoRedirect(_: Data?, handler _: (any LibboxAutoRedirectHandlerProtocol)?) throws -> any LibboxAutoRedirectSessionProtocol {
        throw notSupported("Auto redirect")
    }

    public func startNeighborMonitor(_: (any LibboxNeighborUpdateListenerProtocol)?) throws {}

    public func closeNeighborMonitor(_: (any LibboxNeighborUpdateListenerProtocol)?) throws {}

    public func registerMyInterface(_: String?) {}

    public func cancelNotification(_ identifier: String?, typeID _: Int32) throws {
        #if !os(tvOS)
            guard let identifier else {
                return
            }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        #endif
    }

    public func tailscaleHostname() -> String {
        ProcessInfo.processInfo.hostName
    }
}
