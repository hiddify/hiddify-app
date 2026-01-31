//
//  SingBox.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/25/1402 AP.
//

import Foundation

class SingBox {
    static func setupConfig(config: String, mtu: Int = 9000) -> String? {
        guard
            let config = config.data(using: .utf8),
            var json = try? JSONSerialization
                .jsonObject(
                    with: config,
                    options: [.mutableLeaves, .mutableContainers]
                ) as? [String:Any]
        else {
            return nil
        }
        /*json["log"] = [
            "disabled": false,
            "level": "info",
            "output": "log",
            "timestamp": true
        ] as [String:Any]
        json["experimental"] = [
            "clash_api": [
                "external_controller": "127.0.0.1:10864"
            ]
        ]
        json["inbounds"] = [
            [
                "type": "tun",
                "inet4_address": "172.19.0.1/30",
                "auto_route": true,
                "mtu": mtu,
                "sniff": true
            ] as [String:Any]
        ]
        var routing = (json["route"] as? [String:Any]) ?? [
            "rules": [Any](),
            "auto_detect_interface": true,
            "final": (json["inbounds"] as? [[String:Any]])?.first?["tag"] ?? "proxy"
        ]
        routing["geoip"] = [
            "path": FilePath.assetsDirectory.appendingPathComponent("geoip.db"),
        ]
        routing["geosite"] = [
            "path": FilePath.assetsDirectory.appendingPathComponent("geosite.db"),
        ]
        json["route"] = routing*/
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
