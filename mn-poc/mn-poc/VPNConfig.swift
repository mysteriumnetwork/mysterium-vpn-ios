//
//  VPNConfig.swift
//  mn-poc
//
//  Created by Ivan Podibka on 26.02.2021.
//

import Foundation


struct VPNConfig {
    let serverAddress: String
    let serverPort: String
    let mtu: String
    let ip: String
    let subnet: String
    let dns: String

    var raw: [String: String] {
        return [
            "port": serverPort,
            "server": serverAddress,
            "ip": ip,
            "subnet": subnet,
            "mtu": mtu,
            "dns": dns
        ]
    }
}

extension VPNConfig {
    
    init(raw: [String: Any]) {
        serverAddress = raw["server"] as! String
        serverPort = raw["port"] as! String
        ip = raw["ip"] as! String
        subnet = raw["subnet"] as! String
        mtu = raw["mtu"] as! String
        dns = raw["dns"] as! String
    }
}
