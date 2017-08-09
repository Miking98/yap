//
//  editBillItemTableViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class editBillItemTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    var item: BillItem! {
        didSet {
            nameLabel.text = item.name
            totalPriceLabel.text = String(format: "$%.2f", item.price ?? 0)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        nameLabel.text = ""
        totalPriceLabel.text = ""
    }

}
