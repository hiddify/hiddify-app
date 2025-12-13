//
//  PlatformMethodHandler.swift
//  Runner
//
//  Created by Hiddify on 12/27/23.
//

import Flutter
import Combine
import Libcore

public class PlatformMethodHandler: NSObject, FlutterPlugin {
        
    public static let name = "\(Bundle.main.serviceIdentifier)/platform"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Self.name, binaryMessenger: registrar.messenger())
        let instance = PlatformMethodHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
    }
    
    private var channel: FlutterMethodChannel?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "get_paths":
            result(getPaths(args: call.arguments))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func getPaths(args: Any?) -> [String:String] {
        return [
            "base": FilePath.sharedDirectory.path,
            "working": FilePath.workingDirectory.path,
            "temp": FilePath.cacheDirectory.path
        ]
    }
}
