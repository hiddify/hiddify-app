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
    
    @Stored(key: "VPN.ConfigOptions")
    var configOptions: String = ""
    
    @Stored(key: "VPN.DisableMemoryLimit")
    var disableMemoryLimit: Bool = false
}
