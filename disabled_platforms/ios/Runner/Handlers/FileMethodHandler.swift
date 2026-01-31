//
//  FileMethodHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation

public class FileMethodHandler: NSObject, FlutterPlugin {
        
    public static let name = "\(Bundle.main.serviceIdentifier)/files.method"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Self.name, binaryMessenger: registrar.messenger())
        let instance = FileMethodHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
    }
    
    private var channel: FlutterMethodChannel?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "get_paths":
            result([
                "working": FilePath.workingDirectory.path,
                "temp": FilePath.cacheDirectory.path,
                "base": FilePath.sharedDirectory.path
            ])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
