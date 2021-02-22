//
//  PacketTunnelProvider.swift
//  Mysterium Network Extension
//
//  Created by Hanzo on 17.02.2021.
//

import NetworkExtension
import OpenVPNAdapter

class PacketTunnelProvider: NEPacketTunnelProvider {

    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    var vpnReachability = OpenVPNReachability()

    var configuration: OpenVPNConfiguration!
    var properties: OpenVPNProperties!
    var UDPSession: NWUDPSession!
    var TCPConnection: NWTCPConnection!

    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
            else {
                fatalError()
        }
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else { return }
            let configuration = OpenVPNConfiguration()
            configuration.fileContent = ovpnFileContent
            do {
                properties = try vpnAdapter.apply(configuration: configuration)
            } catch {
                completionHandler(error)
                return
            }
        configuration.tunPersist = true

        if !properties.autologin {
            if let username: String = providerConfiguration["username"] as? String, let password: String = providerConfiguration["password"] as? String {
                let credentials = OpenVPNCredentials()
                credentials.username = username
                credentials.password = password
                do {
                    try vpnAdapter.provide(credentials: credentials)
                } catch {
                    completionHandler(error)
                    return
                }
            }
        }

        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }

        startHandler = completionHandler
        vpnAdapter.connect()

    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        vpnAdapter.disconnect()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
    }

}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(networkSettings) { (error) in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            guard let startHandler = startHandler else { return }
            startHandler(nil)
            self.startHandler = nil
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            stopHandler()
            self.stopHandler = nil
        case .reconnecting:
            reasserting = true
        default:
            break
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        NSLog("Error: \(error.localizedDescription)")
        NSLog("Connection Info: \(vpnAdapter.connectionInformation.debugDescription)")
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        NSLog("Log: \(logMessage)")
    }

}


extension PacketTunnelProvider: OpenVPNAdapterPacketFlow {
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        packetFlow.readPackets(completionHandler: completionHandler)
    }

    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return packetFlow.writePackets(packets, withProtocols: protocols)
    }

}
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}
