//
//  billDetailItemTableViewCell.swift
//  accountabill
//
//  Created by Tiffany Madruga on 7/27/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import FirebaseDatabase

class billDetailItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemUserPriceLabel: UILabel!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var youPayLabel: UILabel!
   
    var item: BillItem! {
        didSet {
            DefaultOps.getBillItem(item: item) { (item, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let item = item {
                    self.itemNameLabel.text = item.name
                    self.itemPriceLabel.text = "$" + String(format: "%.2f", item.price!)
                    self.item.participants = item.participants
                    self.item.price = item.price
                    self.itemUserPriceLabel.text = "$" + String(format: "%.2f", item.pricePerUser!)
                }
            }
        }
    }
    
    var bill:Bill! {
        didSet{
            DefaultOps.getUsersPaymentStatusForBill(bill: bill) { (status, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let status = status{
                    let payvalue = status[(DefaultOps.currentUser?.uid)!] as! [String:Any]
                    if payvalue["paid"] as! Bool == true {
                        self.cellView.backgroundColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5)
                        self.youPayLabel.text = "you paid"
                    }
                    else {
                        self.cellView.backgroundColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 0.5)
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        itemNameLabel.text = ""
        itemPriceLabel.text = ""
        itemUserPriceLabel.text = ""
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 247/255.0, green: 248/255.0, blue: 249/255.0, alpha: 1)
        self.selectedBackgroundView = backgroundView
    }
    
}
