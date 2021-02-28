//
//  Proposal.swift
//  mn-poc
//
//  Created by Ivan Podibka on 27.02.2021.
//

import Foundation

struct Proposal {
    
    struct Response: Codable {
        let proposals: [Item]
    }
    
    struct Item: Codable {
        let providerId: String
        let serviceType: String
        let countryCode: String
        let qualityLevel: Int
        let nodeType: String
        let monitoringFailed: Bool
        let payment: PaymentMethod
    }
    
    struct PaymentMethod: Codable {
        let type: String
        let price: PaymentMoney
        let rate: PaymentRate
    }
    
    struct PaymentMoney: Codable {
        let amount: Double
        let currency: String
    }
    
    struct PaymentRate: Codable {
        let perSeconds: Double
        let perBytes: Double
    }
}
