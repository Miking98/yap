//
//  taxTableViewCell.swift
//  accountabill
//
//  Created by Tiffany Madruga on 7/30/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class taxTableViewCell: UITableViewCell {
    
    @IBOutlet weak var taxTotalLabel: UILabel!
    @IBOutlet weak var userTaxTotalLabel: UILabel!
    @IBOutlet weak var taxView: UIView!
    
    var tax: Double!{
        didSet{
            if tax != nil{
                let stringFormat = String(format: "%.2f", tax)
                taxTotalLabel.text = "$"+stringFormat
            }
            else{
                taxTotalLabel.text = ""
            }
        }
    }
    
    var bill:Bill! {
        didSet {
            FirebaseOps.getUsersPaymentStatusForBill(bill: bill) { (status, error) in
                if let error = error {
                    print(error.localizedDescription)
                }else if let status = status{
                    let payvalue = status[(FirebaseOps.currentUser?.uid)!] as! [String:Any]
                    if payvalue["paid"] as! Bool == true{
                        self.taxView.backgroundColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5)
                    }else{
                        self.taxView.backgroundColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 0.5)
                        
                        
                    }
                    
                }
                
            }
            
        }
        
    }

    var taxCalc: Double! {
        didSet{
            let formattedTax = String(format: "%.2f", taxCalc)
            userTaxTotalLabel.text = "$"+formattedTax
        
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
