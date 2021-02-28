//
//  ProposalsViewController.swift
//  mn-poc
//
//  Created by Ivan Podibka on 26.02.2021.
//

import UIKit
import Mysterium
import NetworkExtension

class ProposalsViewController: UIViewController {

    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var connectContainerView: UIView!
    
    private let node = Node()
    private var vpnManager: NETunnelProviderManager = NETunnelProviderManager()
    private var proposals = [Proposal.Item]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNode()
        loadAllTunnelProviders()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ProposalsViewController.vpnStatusDidChange),
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
        vpnStatusDidChange()
        vpnManager.loadFromPreferences(completionHandler: { [unowned self] (error: Error?) in
            if let error = error {
                showError(error)
            } else {
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.serverAddress = "127.0.0.0"
                vpnManager.protocolConfiguration = providerProtocol
                vpnManager.localizedDescription = "Mysterium Network VPN"
                vpnManager.isEnabled = true

                saveCurrentConfig { result in
                    print(result)
                }
                vpnStatusDidChange()
            }
        })
    }

    @objc
    private func vpnStatusDidChange() {
        let status = self.vpnManager.connection.status
        switch status {
        case .connecting, .connected:
            print(status)
            connectButton.setTitle("Disconnect", for: .normal)
            connectButton.isSelected = true
            tableView.isHidden = true
            connectContainerView.isHidden = false
//            tableView.isHidden = true
//            connectContainerView.isHidden = false
        case .disconnecting:
            print("Disconnecting...")
            break
        case .disconnected:
            print("Disconnected...")
            tableView.isHidden = false
            connectContainerView.isHidden = true
//            tableView.isHidden = true
//            connectContainerView.isHidden = false
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

    private func configureNode() {
        activityIndicatorView.startAnimating()
        node.initialize { [weak self] result in
            switch result {
            case .success:
                self?.loadProposals()
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
    
    private func loadProposals() {
        node.getProposals { [weak self] result in
            switch result {
            case .success(let response):
                self?.activityIndicatorView.stopAnimating()
                self?.proposals = response.proposals
                self?.tableView.reloadData()
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
}

extension ProposalsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proposals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "proposalTableViewCell", for: indexPath) as! ProposalTableViewCell
        cell.proposal = proposals[indexPath.row]
        return cell
    }
    
}

extension ProposalsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let proposal = proposals[indexPath.row]
        self.vpnManager.loadFromPreferences { [unowned self] (error: Error?) in
            saveCurrentConfig(for: proposal) { result in
                do {
                    try vpnManager.connection.startVPNTunnel()
                } catch {
                    showError(error)
                }
            }
        }
    }
    
    private func saveCurrentConfig(for proposal: Proposal.Item? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        var options = [String: Any]()
        if let proposal = proposal {
            do {
                let data = String(data: try JSONEncoder().encode(proposal), encoding: .utf8) ?? ""
                options["proposal"] = data
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        if let provider = vpnManager.protocolConfiguration as? NETunnelProviderProtocol {
            provider.providerConfiguration = options
        }
        
        vpnManager.saveToPreferences(completionHandler: { [unowned self] (error: Error?) in
            if let error = error {
                showError(error)
                completion(.failure(error))
            } else {
                completion(.success(Void()))
            }
        })
    }
}

