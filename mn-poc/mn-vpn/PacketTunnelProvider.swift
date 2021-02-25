//
//  PacketTunnelProvider.swift
//  mn-vpn
//
//  Created by Ivan Podibka on 26.02.2021.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var session: NWUDPSession?
    private var vpnConfig: VPNConfig!

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelProvider = protocolConfiguration as? NETunnelProviderProtocol else {
            return
        }
        guard let data = tunnelProvider.providerConfiguration else {
            return
        }
        vpnConfig = VPNConfig(raw: data)
        setupUDPSession()
        tunnelToUDP()
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        session?.cancel()
        super.stopTunnel(with: reason, completionHandler: completionHandler)
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
        // no need to implement
    }

    // These 2 are core methods for VPN tunnelling
    //   - read from tun device, encrypt, write to UDP fd
    //   - read from UDP fd, decrypt, write to tun device
    private func tunnelToUDP() {
        packetFlow.readPackets { [weak self] (packets: [Data], protocols: [NSNumber]) in
            for packet in packets {
                // This is where encrypt() should reside
                // A comprehensive encryption is not easy and not the point for this demo
                // I just omit it
                self?.session?.writeDatagram(packet, completionHandler: { (error: Error?) in
                    if let error = error {
                        print(error)
                        self?.setupUDPSession()
                        return
                    }
                })
            }
            self?.tunnelToUDP()
        }
    }

    private func udpToTunnel() {
        // It's callback here
        session?.setReadHandler({ (_packets: [Data]?, error: Error?) -> Void in
            if let packets = _packets {
                // This is where decrypt() should reside, I just omit it like above
                self.packetFlow.writePackets(packets, withProtocols: [NSNumber](repeating: AF_INET as NSNumber, count: packets.count))
            }
        }, maxDatagrams: NSIntegerMax)
    }

    private func setupPacketTunnelNetworkSettings() {
        let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: self.protocolConfiguration.serverAddress!)
        tunnelNetworkSettings.ipv4Settings = NEIPv4Settings(
            addresses: [vpnConfig.ip],
            subnetMasks: [vpnConfig.subnet]
        )

        // Refers to NEIPv4Settings#includedRoutes or NEIPv4Settings#excludedRoutes,
        // which can be used as basic whitelist/blacklist routing.
        // This is default routing.
        tunnelNetworkSettings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        tunnelNetworkSettings.mtu = NSNumber(value: Int(vpnConfig.mtu) ?? 0)

        let dnsSettings = NEDNSSettings(servers: vpnConfig.dns.components(separatedBy: ","))
        // This overrides system DNS settings
        dnsSettings.matchDomains = [""]
        tunnelNetworkSettings.dnsSettings = dnsSettings

        setTunnelNetworkSettings(tunnelNetworkSettings) { [weak self] (error: Error?) -> Void in
            self?.udpToTunnel()
        }
    }

    private func setupUDPSession() {
        if session != nil {
            reasserting = true
            session = nil
        }
        let endpoint = NWHostEndpoint(hostname: vpnConfig.serverPort, port: vpnConfig.serverPort)
        reasserting = false
        setTunnelNetworkSettings(nil) { [weak self] (error: Error?) -> Void in
            if let error = error {
                print(error)
            } else {
                self?.session = self?.createUDPSession(to: endpoint, from: nil)
                self?.setupPacketTunnelNetworkSettings()
            }
        }
    }
}
