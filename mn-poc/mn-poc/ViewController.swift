//
//  ViewController.swift
//  mn-poc
//
//  Created by Ivan Podibka on 26.02.2021.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {

    @IBOutlet private weak var connectButton: UIButton!

    private let config = VPNConfig(
        serverAddress: "219.100.37.221",
        serverPort: "54345",
        mtu: "1400",
        ip: "10.8.0.2",
        subnet: "255.255.255.0",
        dns: "8.8.8.8,8.4.4.4"
    )
    private var vpnManager: NETunnelProviderManager = NETunnelProviderManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadAllTunnelProviders()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.vpnStatusDidChange),
                                               name: NSNotification.Name.NEVPNStatusDidChange,
                                               object: nil)
    }

    private func loadAllTunnelProviders() {
        NETunnelProviderManager.loadAllFromPreferences { [unowned self] (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                showError(error)
                return
            } else {
                initilizeVPNManager(from: savedManagers ?? [])
            }
        }
    }

    private func initilizeVPNManager(from savedManagers: [NETunnelProviderManager]) {
        guard let manager = savedManagers.first else {
            return
        }

        vpnManager = manager
        vpnManager.loadFromPreferences(completionHandler: { [unowned self] (error: Error?) in
            if let error = error {
                showError(error)
            } else {
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.providerConfiguration = config.raw
                providerProtocol.serverAddress = config.serverAddress
                vpnManager.protocolConfiguration = providerProtocol
                vpnManager.localizedDescription = "Mysterium Network VPN"
                vpnManager.isEnabled = true

                vpnManager.saveToPreferences(completionHandler: { (error: Error?) in
                    if let error = error {
                        showError(error)
                    } else {
                        print("Save successfully")
                    }
                })
                vpnStatusDidChange()
            }
        })
    }

    @objc
    private func vpnStatusDidChange() {
        let status = self.vpnManager.connection.status
        switch status {
        case .connecting:
            print("Connecting...")
            connectButton.setTitle("Disconnect", for: .normal)
            connectButton.isSelected = true
            break
        case .connected:
            print("Connected...")
            connectButton.setTitle("Disconnect", for: .normal)
            connectButton.isSelected = true
            break
        case .disconnecting:
            print("Disconnecting...")
            break
        case .disconnected:
            print("Disconnected...")
            connectButton.setTitle("Connect", for: .normal)
            connectButton.isSelected = false
            break
        case .invalid:
            print("Invliad")
            break
        case .reasserting:
            print("Reasserting...")
            break
        @unknown default:
            print("Unknown state")
        }
    }

    @IBAction
    private func connect(_ sender: UIButton) {
        self.vpnManager.loadFromPreferences { [unowned self] (error: Error?) in
            if let error = error {
                print(error)
            }
            if self.connectButton.isSelected {
                vpnManager.connection.stopVPNTunnel()
            } else {
                do {
                    try vpnManager.connection.startVPNTunnel()
                } catch {
                    showError(error)
                }
            }
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

