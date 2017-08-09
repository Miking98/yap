//
//  assignBillItemsTableViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/26/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class assignBillItemsTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pricePerUserLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var profileImagesCollectionView: UICollectionView!
    
    var item: BillItem! {
        didSet {
            nameLabel.text = item.name
            let totalPrice = item.price ?? 0
            let perPersonPrice = item.pricePerUser ?? 0
            pricePerUserLabel.text = String(format: "$%.2f", perPersonPrice)
            totalPriceLabel.text = String(format: "$%.2f total", totalPrice)
            profileImagesCollectionView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set up profile image collection view
        profileImagesCollectionView.dataSource = self
        profileImagesCollectionView.delegate = self
    }
    // Profile Images collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item.participants.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "assignBillItemsParticipantsCollectionViewCell", for: indexPath) as! assignBillItemsParticipantsCollectionViewCell
        cell.user = item.participants[indexPath.row]
        return cell
    }
}
