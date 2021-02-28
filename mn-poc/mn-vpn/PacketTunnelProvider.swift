//
//  PacketTunnelProvider.swift
//  mn-vpn
//
//  Created by Ivan Podibka on 26.02.2021.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var session: NWUDPSession?
    private let node = Node()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelProvider = protocolConfiguration as? NETunnelProviderProtocol else {
            return
        }
        guard let data = tunnelProvider.providerConfiguration else {
            return
        }
        guard let json = data["proposal"] as? String, let jsonData = json.data(using: .utf8) else {
            return
        }
        
        do {
            let proposal = try JSONDecoder().decode(Proposal.Item.self, from: jsonData)
            print("")
            node.initialize { [weak self] result in
                switch result {
                case .success:
                    self?.node.overrideWireguardTunnel(WireguardTunnelSetup(tunnelProvider: self))
                    self?.connect(with: proposal)
                    print("")
                case .failure(let error):
                    completionHandler(error)
                }
            }
        } catch {
            print(error)
        }
        
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        
    }

    private func connect(with proposal: Proposal.Item) {
        
    }

}
