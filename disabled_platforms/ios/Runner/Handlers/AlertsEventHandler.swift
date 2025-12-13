//
//  AlertEventHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation
import Combine

public class AlertsEventHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    static let name = "\(Bundle.main.serviceIdentifier)/service.alerts"
    
    private var channel: FlutterEventChannel?
    
    private var cancellable: AnyCancellable?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AlertsEventHandler()
        instance.channel = FlutterEventChannel(name: Self.name, binaryMessenger: registrar.messenger(), codec: FlutterJSONMethodCodec())
        instance.channel?.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        cancellable = VPNManager.shared.$alert.sink { [events] alert in
            var data = [
                "status": "Stopped",
                "alert": alert.alert?.rawValue,
                "message": alert.message,
            ]
            for key in data.keys {
                if data[key] == nil {
                    data.removeValue(forKey: key)
                }
            }
            events(data)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancellable?.cancel()
        return nil
    }
}
