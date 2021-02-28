//
//  Node.swift
//  mn-poc
//
//  Created by Ivan Podibka on 28.02.2021.
//

import Foundation
import Mysterium

class Node {
    
    private var node: MysteriumMobileNode!
    private var identity: Identity?
    
    func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
//        DispatchQueue.global(qos: .background).async { [unowned self] in
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.geniusee.mysterium.poc") else {
                print("Can't find caches directory")
                return
            }
            
            var error: NSError?
            node = MysteriumNewNode(url.path, MysteriumDefaultNodeOptions(), &error)
            print("")
            if let error = error {
//                DispatchQueue.main.async {
                    completion(.failure(error))
//                }
            } else {
                do {
                    try loadIdentity()
//                    DispatchQueue.main.async {
                        completion(.success(Void()))
//                    }
                } catch {
//                    DispatchQueue.main.async {
                        completion(.failure(error))
//                    }
                }
            }
//        }
    }
    
    func overrideWireguardTunnel(_ tunnelSetup: MysteriumWireguardTunnelSetup) {
        node.overrideWireguardConnection(tunnelSetup)
    }
    
    func getProposals(completion: @escaping (Result<Proposal.Response, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            let request = MysteriumGetProposalsRequest()
            request.refresh = false
            request.includeFailed = false
            request.serviceType = "wireguard"
            do {
                let data = try node.getProposals(request)
                let response = try JSONDecoder().decode(Proposal.Response.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func connect(to proposal: Proposal.Item, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let identity = identity else {
            return
        }
        DispatchQueue.global(qos: .background).async { [unowned self] in
            let request = MysteriumConnectRequest()
            request.identityAddress = identity.address
            request.providerID = proposal.providerId
            request.serviceType = proposal.serviceType
            node.connect(request)
            completion(.success(Void()))
        }
    }
    
    private func loadIdentity() throws {
        let identity = Identity(response: try node.getIdentity(MysteriumGetIdentityRequest()))
        if (!identity.registered) {
            let request = MysteriumRegisterIdentityRequest()
            request.identityAddress = identity.address
            try node.registerIdentity(request)
        }
        self.identity = identity
    }
}
