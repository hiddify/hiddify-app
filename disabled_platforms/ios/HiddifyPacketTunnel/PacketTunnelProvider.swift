//
//  PacketTunnelProvider.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/24/1402 AP.
//

import NetworkExtension

class PacketTunnelProvider: ExtensionProvider {

    private var upload: Int64 = 0
    private var download: Int64 = 0
    // private var trafficLock: NSLock = NSLock()
    
    // var trafficReader: TrafficReader!
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        try await super.startTunnel(options: options)
        /*trafficReader = TrafficReader { [unowned self] traffic in
            trafficLock.lock()
            upload += traffic.up
            download += traffic.down
            trafficLock.unlock()
        }*/
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        let message = String(data: messageData, encoding: .utf8)
        switch message {
        case "stats":
            return "\(upload),\(download)".data(using: .utf8)!
        default:
            return nil
        }
    }
}
