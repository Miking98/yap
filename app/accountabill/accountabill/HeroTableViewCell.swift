//
//  HeroTableViewCell.swift
//  accountabill
//
//  Created by Tiffany Madruga on 7/28/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class HeroTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountOwedLabel: UILabel!
    @IBOutlet weak var moneyLabel: UILabel!
    @IBOutlet weak var cellView: UIView!
    
    var user: User! {
        didSet {
            FirebaseOps.getUser(user: user!) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let user = user {
                    //self.user = user
                    self.user?.photoURL = user.photoURL
                    self.user?.name = user.name
                    self.nameLabel.text = user.name
                    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2
                    
                    if user.photoURL != nil {
                        self.profilePicture.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
                    }
                    else if user.facebookID != nil {
                        let imageURL = "https://graph.facebook.com/v2.10/"+user.facebookID!+"/picture"
                        self.profilePicture.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
                    }
                    else if user.facebookTaggableID != nil && user.photoURL != nil {
                        self.profilePicture.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"))
                    }
                }
            }
        }
    }
    
    var bill:Bill! {
        didSet {
            FirebaseOps.getUsersPaymentStatusForBill(bill: bill) { (status, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let status = status {
                    for (uid, _) in status{
                        let payvalue = status[uid] as! [String:Any]
                        if payvalue["paid"] as! Bool == true{
                            self.cellView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0)
                            self.moneyLabel.text = "Paid"
                            self.amountOwedLabel.text = ""
                        }
                        else {
                            self.cellView.backgroundColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 0.5)
                            self.moneyLabel.text = "Owes"
                            self.moneyLabel.textColor = UIColor.black
                        }
                    }
                }
            }
            
            FirebaseOps.getUsersPaymentStatusForBill(bill: bill) { (status, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let status = status {
                    for (uid, _) in status{
                        if uid == self.user.uid{
                            let userstatus = status[uid] as! [String:Any]
                            self.amountOwedLabel.text = "$" + String(format: "%.2f", userstatus["amount"]! as? Double ?? 0.00)
                            break
                            
                        }
                    }
                }
            }
            
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
