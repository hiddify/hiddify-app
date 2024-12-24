//
//  VPNConfig.swift
//  Runner
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation
import Combine

class VPNConfig: ObservableObject {
    static let shared = VPNConfig()
    
    @Stored(key: "VPN.ActiveConfigPath")
    var activeConfigPath: String = ""
    
    @Stored(key: "VPN.ActiveProfileName")
    var activeProfileName: String = ""
    
    @Stored(key: "VPN.GrpcServiceModePort")
    var grpcServiceModePort: Int = 0
    
    @Stored(key: "VPN.workingDir")
    var workingDir: String = ""
    
    @Stored(key: "VPN.tempDir")
    var tempDir: String = ""
    
    @Stored(key: "VPN.baseDir")
    var baseDir: String = ""
    
//    @Stored(key: "VPN.grpcFlutterPublicKey")
//    var grpcFlutterPublicKey: String = ""
    
    
    @Stored(key: "VPN.ConfigOptions")
    var configOptions: String = ""
    
    @Stored(key: "VPN.DisableMemoryLimit")
    var disableMemoryLimit: Bool = false
}
