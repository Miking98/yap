//
//  groupMemberCollectionViewCell.swift
//  accountabill
//
//  Created by Xueying Wang on 7/25/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import AlamofireImage

class groupMemberCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var memberPhotoView: UIImageView!
    
    var user: User!{
        didSet{
            memberPhotoView.clipsToBounds = true
            if user.photoURL != nil {
                self.memberPhotoView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
            else if user.facebookID != nil {
                let imageURL = "https://graph.facebook.com/v2.10/"+user.facebookID!+"/picture"
                self.memberPhotoView.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
            else if user.facebookTaggableID != nil && user.photoURL != nil {
                self.memberPhotoView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"))
            }
        }
    }
}
