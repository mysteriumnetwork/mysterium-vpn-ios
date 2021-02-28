//
//  Identity.swift
//  mn-poc
//
//  Created by Ivan Podibka on 27.02.2021.
//

import Foundation
import Mysterium

struct Identity {
    
    enum Status: String {
        case unknown = "Unknown"
        case registered = "Registered"
        case unregistered = "Unregistered"
        case inProgress = "InProgress"
        case registrationError = "RegistrationError"
    }
    
    let address: String
    let channelAddress: String
    let status: Status

    init(response: MysteriumGetIdentityResponse) {
        address = response.identityAddress
        channelAddress = response.channelAddress
        status = Status(rawValue: response.registrationStatus) ?? .unknown
    }
    
}

extension Identity {
    
    var registered: Bool {
        get {
            return status == .registered || status == .inProgress
        }
    }
    
    var registrationFailed: Bool {
        get {
            return status == .registrationError
        }
    }
}
