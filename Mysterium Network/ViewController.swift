//
//  ViewController.swift
//  Mysterium Network
//
//  Created by Hanzo on 17.02.2021.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {
    
    var manager: NETunnelProviderManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        establishVPNConnection()
    }
    
    func establishVPNConnection() {
        let callback = { (error: Error?) -> Void in
            self.manager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    print("\(error!.localizedDescription)")
                    return
                }
                
                let options: [String : NSObject] = [
                    "username": "vpnbook" as NSString,
                    "password": "mku97sb" as NSString
                ]
                
                
                do {
                    try self.manager?.connection.startVPNTunnel(options: options)
                } catch {
                    print("\(error.localizedDescription)")
                }
            })
        }
        
        configureVPN(callback: callback)
    }
    
    
    func configureVPN(callback: @escaping (Error?) -> Void) {
        let configurationFile = Bundle.main.url(forResource: "test", withExtension: "ovpn")
        let configurationContent = try! Data(contentsOf: configurationFile!)
        
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            guard error == nil else {
                print("\(error!.localizedDescription)")
                callback(error)
                return
            }
            
            self.manager = managers?.first ?? NETunnelProviderManager()
            self.manager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    print("\(error!.localizedDescription)")
                    callback(error)
                    return
                }
                
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.serverAddress = "vpnbook.org"
                tunnelProtocol.providerBundleIdentifier = "com.geniusee.mysterium.poc.extension"
                tunnelProtocol.providerConfiguration = ["configuration": configurationContent]
                tunnelProtocol.disconnectOnSleep = false
                
                self.manager?.protocolConfiguration = tunnelProtocol
                self.manager?.localizedDescription = "Mysterium Network VPN"
                
                self.manager?.isEnabled = true
                
                self.manager?.saveToPreferences(completionHandler: { (error) in
                    guard error == nil else {
                        print("\(error!.localizedDescription)")
                        callback(error)
                        return
                    }
                    
                    callback(nil)
                })
            })
        }
    }
}

