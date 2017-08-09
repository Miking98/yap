//
//  groupUsersCollectionViewCell.swift
//  accountabill
//
//  Created by Xueying Wang on 7/25/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import AlamofireImage
import UICircularProgressRing

class groupUsersCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var paidProgressRing: UICircularProgressRingView!
    @IBOutlet weak var receivedProgressRing: UICircularProgressRingView!
    @IBOutlet weak var paidLabel: UILabel!
    @IBOutlet weak var receivedLabel: UILabel!
    
    
    var user: User! {
        didSet {
            photoView.layer.borderColor = UIColor.white.cgColor
            photoView.layer.borderWidth = 2
            self.layer.shadowOffset = CGSize(width: 1, height: 0)
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowRadius = 3
            self.layer.shadowOpacity = 0.25
            self.clipsToBounds = false
            self.layer.masksToBounds = false
            userNameLabel.text = user.name
            photoView.clipsToBounds = true
            photoView.layer.cornerRadius = photoView.frame.size.width / 2
            if user.photoURL != nil {
                self.photoView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
            else if user.facebookID != nil {
                let imageURL = "https://graph.facebook.com/v2.10/"+user.facebookID!+"/picture"
                self.photoView.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
            else if user.facebookTaggableID != nil && user.photoURL != nil {
                self.photoView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"))
            }
        }
    }
    
    var amounts: [String: Double]!{
        didSet{
            paidLabel.text = String(format: "$"+"%.2f"+"/"+"%.2f", amounts["paid"] ?? 0, amounts["totalPay"] ?? 0)
            receivedLabel.text = String(format: "$"+"%.2f"+"/"+"%.2f", amounts["received"] ?? 0, amounts["totalReceive"] ?? 0)
            paidProgressRing.backgroundColor = UIColor.clear
            receivedProgressRing.backgroundColor = UIColor.clear
            paidProgressRing.setProgress(value: 0.0, animationDuration: 1.0) {
                self.paidProgressRing.setProgress(value: CGFloat(self.amounts["paidPercentage"] ?? 100.0), animationDuration: 2.0)
            }
            paidProgressRing.font = UIFont.systemFont(ofSize: 13)
            receivedProgressRing.setProgress(value: 0.0, animationDuration: 1.0) {
                self.receivedProgressRing.setProgress(value: CGFloat(self.amounts["receivedPercentage"] ?? 0.0), animationDuration: 2.0)
            }
            receivedProgressRing.font = UIFont.systemFont(ofSize: 13)
        }
    }
}
