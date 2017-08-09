//
//  billsDetailCollectionViewCell.swift
//  accountabill
//
//  Created by Tiffany Madruga on 7/25/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class billsDetailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profilePictures: UIImageView!
    
    var user: User? {
        didSet {
            self.profilePictures.layer.borderColor = UIColor.white.cgColor
            self.profilePictures.layer.borderWidth = 2
            self.profilePictures.layer.cornerRadius = self.profilePictures.frame.size.width / 2
            if let user = user {
                if user.photoURL != nil {
                    profilePictures.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
                }
                else if user.facebookID != nil {
                    let imageURL = "https://graph.facebook.com/v2.10/"+user.facebookID!+"/picture"
                    profilePictures.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
                }
                else if user.facebookTaggableID != nil && user.photoURL != nil {
                    profilePictures.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"))
                }
            }
        }
    }
}
