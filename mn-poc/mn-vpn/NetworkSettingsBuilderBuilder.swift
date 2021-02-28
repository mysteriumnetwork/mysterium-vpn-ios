//
//  VPNServiceBuilder.swift
//  mn-vpn
//
//  Created by Ivan Podibka on 27.02.2021.
//

import Foundation
import Network
import NetworkExtension

class NetworkSettingsBuilderBuilder {
    
    fileprivate struct Address {
        let address: String
        let prefixLength: Int
    }
    
    private var routes = [Address]()
    private var tunelAddresses = [Address]()
    private var mtu: Int = 1280
    private var dnsServers = [String]()
    
    @discardableResult
    func addRoute(route: String, prefixLength: Int) -> Self {
        routes.append(Address(address: route, prefixLength: prefixLength))
        return self
    }
    
    @discardableResult
    func addTunnelAddress(ip: String, prefixLength: Int) -> Self {
        tunelAddresses.append(Address(address: ip, prefixLength: prefixLength))
        return self
    }
    
    @discardableResult
    func setMtu(_ mtu: Int) -> Self {
        self.mtu = mtu
        return self
    }
    
    @discardableResult
    func addDNS(_ ip: String) -> Self {
        dnsServers.append(ip)
        return self
    }
    
    @discardableResult
    func build() -> NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        if !dnsServers.isEmpty {
            let dnsSettings = NEDNSSettings(servers: dnsServers)
            dnsSettings.matchDomains = [""]
            networkSettings.dnsSettings = dnsSettings
        }

        networkSettings.mtu = NSNumber(value: mtu)
        
        var ipV4Routes = [NEIPv4Route]()
        var ipV6Routes = [NEIPv6Route]()
        tunelAddresses.forEach {
            if let address = $0.ipAddress as? IPv4Address {
                ipV4Routes.append(
                    NEIPv4Route(
                        destinationAddress: "\(address)",
                        subnetMask: "\(address.submask(prefixLength: $0.prefixLength))"
                    )
                )
            } else if let address = $0.ipAddress as? IPv6Address {
                ipV6Routes.append(
                    NEIPv6Route(
                        destinationAddress: "\(address)",
                        networkPrefixLength: NSNumber(value: $0.prefixLength)
                    )
                )
            }
        }
        
        let ipV4Settings = NEIPv4Settings(
            addresses: ipV4Routes.map { $0.destinationAddress },
            subnetMasks: ipV4Routes.map { $0.destinationSubnetMask }
        )
        let ipV6Settings = NEIPv6Settings(
            addresses: ipV6Routes.map { $0.destinationAddress },
            networkPrefixLengths: ipV6Routes.map { $0.destinationNetworkPrefixLength }
        )
        
        networkSettings.ipv4Settings = ipV4Settings
        networkSettings.ipv6Settings = ipV6Settings
        
        return networkSettings
    }
    
}

private extension NetworkSettingsBuilderBuilder.Address {
    
    var ipAddress: IPAddress? {
        return IPv4Address(address) ?? IPv6Address(address)
    }
}

private extension IPAddress {
    
    func submask(prefixLength: Int) -> IPAddress {
        if self is IPv4Address {
            let mask = prefixLength > 0 ? ~UInt32(0) << (32 - prefixLength) : UInt32(0)
            let bytes = Data([
                UInt8(truncatingIfNeeded: mask >> 24),
                UInt8(truncatingIfNeeded: mask >> 16),
                UInt8(truncatingIfNeeded: mask >> 8),
                UInt8(truncatingIfNeeded: mask >> 0)
            ])
            return IPv4Address(bytes)!
        }
        if self is IPv6Address {
            var bytes = Data(repeating: 0, count: 16)
            for i in 0..<Int(prefixLength / 8) {
                bytes[i] = 0xff
            }
            let nibble = prefixLength % 32
            if nibble != 0 {
                let mask = ~UInt32(0) << (32 - nibble)
                let i = Int(prefixLength / 32 * 4)
                bytes[i + 0] = UInt8(truncatingIfNeeded: mask >> 24)
                bytes[i + 1] = UInt8(truncatingIfNeeded: mask >> 16)
                bytes[i + 2] = UInt8(truncatingIfNeeded: mask >> 8)
                bytes[i + 3] = UInt8(truncatingIfNeeded: mask >> 0)
            }
            return IPv6Address(bytes)!
        }
        fatalError()
    }
}
