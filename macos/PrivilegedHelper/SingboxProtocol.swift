//
//  SingboxProtocol.swift
//  Runner
//
//  Created by Aleksandr Strizhnev on 18.02.2025.
//

import Foundation

@objc enum NativeReceiver: (Int64) {
    case serviceStatus = 0
    case stats = 1
    case groups = 2
    case activeGroups = 3
}

@objc protocol SingboxReceiverProtocol {
    @objc func processMessage(
        receiver: NativeReceiver,
        message: String?
    )
}

@objc protocol SingboxProtocol {
    @objc func setupOnce(
        completion: @escaping (String?) -> Void
    )
    
    @objc func setup(
        baseDir: String,
        workingDir: String,
        tempDir: String,
        debug: Bool,
        completion: @escaping (String?) -> Void
    )
    
    @objc func parse(
        path: String,
        tempPath: String,
        debug: Bool,
        completion: @escaping (String?) -> Void
    )
    
    @objc func changeHiddifyOptions(
        options: String,
        completion: @escaping (String?) -> Void
    )
    
    @objc func generateConfig(
        path: String,
        completion: @escaping (String?) -> Void
    )
    
    @objc func start(
        path: String,
        disableMemoryLimit: Bool,
        completion: @escaping (String?) -> Void
    )
    
    @objc func stop(
        completion: @escaping (String?) -> Void
    )
    
    @objc func restart(
        path: String,
        disableMemoryLimit: Bool,
        completion: @escaping (String?) -> Void
    )
    
    @objc func stopCommandClient(
        id: Int32,
        completion: @escaping (String?) -> Void
    )
    
    @objc func startCommandClient(
        id: Int32,
        receiver: NativeReceiver,
        completion: @escaping (String?) -> Void
    )
    
    @objc func selectOutbound(
        groupTag: String,
        outboundTag: String,
        completion: @escaping (String?) -> Void
    )
    
    @objc func urlTest(
        groupTag: String,
        completion: @escaping (String?) -> Void
    )
    
    @objc func generateWarpConfig(
        licenseKey: String,
        previousAccountId: String,
        previousAccessToken: String,
        completion: @escaping (String?) -> Void
    )
}
