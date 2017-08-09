//
//  editBillParticipantsAddedCollectionViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/24/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import AlamofireImage

protocol editBillParticipantsAddedDelegate {
    func removeParticipant(user: User)
}

class editBillParticipantsAddedCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    
    var delegate: editBillParticipantsAddedDelegate?
    
    var user: User! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            nameLabel.text = user.name
            self.profileImageView.image = DefaultOps.pictures(user: user)
//            if user.photoURL != nil {
//                profileImageView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
//            }
//            else if user.facebookID != nil {
//                let imageURL = "https://graph.facebook.com/v2.10/"+user.facebookID!+"/picture"
//                profileImageView.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
//            }
        }
    }
    
    override func awakeFromNib() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
    }
    
    @IBAction func removeButtonTouch(_ sender: Any) {
        delegate?.removeParticipant(user: user)
    }
}
