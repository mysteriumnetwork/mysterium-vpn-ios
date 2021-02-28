//
//  WireguardTunnelSetup.swift
//  mn-vpn
//
//  Created by Ivan Podibka on 28.02.2021.
//

import Foundation
import NetworkExtension
import Mysterium

class WireguardTunnelSetup: MysteriumWireguardTunnelSetup {
    
    private weak var packetTunnelProvider: NEPacketTunnelProvider?
    private var builder: NetworkSettingsBuilderBuilder?
    
    private var tunnelFileDescriptor: Int32? {
        return self.packetTunnelProvider?.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32
    }
    
    init(tunnelProvider: NEPacketTunnelProvider? = nil) {
        super.init()
        self.packetTunnelProvider = tunnelProvider
    }
    
    override func addRoute(_ route: String?, prefixLen: Int) {
        guard let route = route else {
            return
        }
        builder?.addRoute(route: route, prefixLength: prefixLen)
    }
    
    override func addTunnelAddress(_ ip: String?, prefixLen: Int) {
        guard let ip = ip else {
            return
        }
        builder?.addTunnelAddress(ip: ip, prefixLength: prefixLen)
    }
    
    override func setMTU(_ mtu: Int) {
        builder?.setMtu(mtu)
    }
    
    override func newTunnel() {
        builder = NetworkSettingsBuilderBuilder()
    }
    
    override func establish(_ ret0_: UnsafeMutablePointer<Int>?) throws {
        guard let settings = builder?.build() else {
            return
        }
        
        var systemError: Error?
        let condition = NSCondition()
        
        condition.lock()
        defer {
            condition.unlock()
        }
        
        packetTunnelProvider?.setTunnelNetworkSettings(settings, completionHandler: { error in
            systemError = error
            condition.signal()
        })
        
        let setTunnelNetworkSettingsTimeout: TimeInterval = 5

        if condition.wait(until: Date().addingTimeInterval(setTunnelNetworkSettingsTimeout)) {
            if let systemError = systemError {
                throw systemError
            } else if let fileDescriptor = tunnelFileDescriptor {
                ret0_?.pointee = Int(fileDescriptor)
            }
        } else {
            print("setTunnelNetworkSettings timed out after 5 seconds; proceeding anyway")
        }
    }
    
}
