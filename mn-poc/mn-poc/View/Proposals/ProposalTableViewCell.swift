//
//  ProposalTableViewCell.swift
//  mn-poc
//
//  Created by Ivan Podibka on 27.02.2021.
//

import UIKit

class ProposalTableViewCell: UITableViewCell {

    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var qualityLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var perSecondLabel: UILabel!
    @IBOutlet private weak var perBytesLabel: UILabel!
    @IBOutlet private weak var countryLabel: UILabel!
    
    var proposal: Proposal.Item! {
        didSet {
            update()
        }
    }
    
    private func update() {
        idLabel.text = proposal.providerId
        typeLabel.text = proposal.nodeType
        qualityLabel.text = "Quality: \(proposal.qualityLevel)"
        priceLabel.text = "Price: \(proposal.payment.price.amount) \(proposal.payment.price.currency)"
        perSecondLabel.text = "\(proposal.payment.rate.perSeconds)/sec"
        perBytesLabel.text = "\(proposal.payment.rate.perBytes)/bytes"
        countryLabel.text = "Country: \(proposal.countryCode)"
    }

}
