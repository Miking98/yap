//
//  billsTableViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/16/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class billsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var billNameLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var billDateLabel: UILabel!
    @IBOutlet weak var billTotalLabel: UILabel!
    @IBOutlet weak var paidLabel: UILabel!
    @IBOutlet weak var groupNameMembersLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var rectableView: UIView!
    
    var user: User?
    var group: Group?
    
    var bill: Bill! {
        didSet {
            billNameLabel.text = bill.name
            let formattedDate = formatDateForPrint(date: bill.createdDate)
            let location = bill.locationPrint()
            
            billDateLabel.text = "\(formattedDate) | \(location)"
            if bill.total != nil {
                billTotalLabel.text = String(format: "$%.2f", bill.total!)
            }
            let groupnum = bill.participants.count
            
            //Setting paid/unpaid bill scenarios
            paidLabel.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
            
            if bill.author != nil && bill.author!.uid != FirebaseOps.currentUser?.uid! {
                FirebaseOps.getUsersPaymentStatusForBill(bill: bill) { (status, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else if let status = status {
                        for (uid, _) in status{
                            let payvalue = status[uid] as! [String:Any]
                            if uid == FirebaseOps.currentUser?.uid! {
                                if payvalue["paid"] as! Bool == true {
                                    self.paidLabel.text = "Paid"
                                    self.rectableView.backgroundColor = UIColor.init(red: 82.0/255.0, green: 194.0/255.0, blue: 161.0/255.0, alpha: 1.0)
                                    self.billTotalLabel.textColor = UIColor.init(red: 82.0/255.0, green: 194.0/255.0, blue: 161.0/255.0, alpha: 1.0)
                                }
                                else {
                                    self.paidLabel.text = "Incomplete"
                                    self.rectableView.backgroundColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 1.0)
                                    self.billTotalLabel.textColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 1.0)
                                }
                                break
                            }
                        }
                    }
                }
            }
            else {
                if bill.completed != nil && bill.completed! {
                    paidLabel.text = "Paid"
                    rectableView.backgroundColor = UIColor.init(red: 82.0/255.0, green: 194.0/255.0, blue: 161.0/255.0, alpha: 1.0)
                    billTotalLabel.textColor = UIColor.init(red: 82.0/255.0, green: 194.0/255.0, blue: 161.0/255.0, alpha: 1.0)
                }
                else {
                    paidLabel.text = "Incomplete"
                    rectableView.backgroundColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 1.0)
                    billTotalLabel.textColor = UIColor.init(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 1.0)
                }
            }
            
            
            if bill.author != nil {
                FirebaseOps.getUser(user: bill.author!) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else if let user = user {
                        self.user = user
                        self.createdLabel.text = self.user?.name
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
            
            if bill.group != nil {
                FirebaseOps.getGroup(group: bill.group!) { (group, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        self.groupNameMembersLabel.text = "\(groupnum) Member(s)"
                    }
                    else if let group = group {
                        self.groupNameMembersLabel.text = "\(group.name!): \(group.users.count) Members"
                    }
                }
            }
            else {
                self.groupNameMembersLabel.text = "\(self.bill.participants.count) Member(s)"
            
            }
        }
    }
    
    func formatDateForPrint(date: Date?) -> String {
        if date == nil {
            return ""
        }
        // Returns date string in format: October 8, 2016 at 10:48:53 PM
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date!)
    }

    override func prepareForReuse() {
        billNameLabel.text = ""
        createdLabel.text = ""
        billDateLabel.text = ""
        billTotalLabel.text = ""
        paidLabel.text = ""
        groupNameMembersLabel.text = ""
        profilePicture.image = #imageLiteral(resourceName: "profile_icon")
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.selectionStyle = .none
//        let backgroundView = UIView()
//        backgroundView.backgroundColor = UIColor(red: 247/255.0, green: 248/255.0, blue: 249/255.0, alpha: 1)
//        self.selectedBackgroundView = backgroundView
    }
    
    
    
}
