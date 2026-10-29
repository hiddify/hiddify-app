//
//  StatusEventHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation
import Combine

public class StatusEventHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    static let name = "\(Bundle.main.serviceIdentifier)/service.status"
    
    private var channel: FlutterEventChannel?
    
    private var cancellable: AnyCancellable?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = StatusEventHandler()
        instance.channel = FlutterEventChannel(name: Self.name, binaryMessenger: registrar.messenger(), codec: FlutterJSONMethodCodec())
        instance.channel?.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // .invalid is the state before the VPN preferences are loaded, not a disconnected tunnel: sent
        // as Stopped it shows a disconnect for a moment whenever the app comes back to a tunnel
        // that is up. The loaded state follows at once.
        cancellable = VPNManager.shared.$state
            .filter { $0 != .invalid }
            .receive(on: DispatchQueue.main)
            .sink { [events] status in
            switch status {
            case .reasserting, .connecting:
                events(["status": "Starting"])
            case .connected:
                events(["status": "Started"])
            case .disconnecting:
                events(["status": "Stopping"])
            case .disconnected, .invalid:
                events(["status": "Stopped"])
            @unknown default:
                events(["status": "Stopped"])
            }
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancellable?.cancel()
        return nil
    }
}
