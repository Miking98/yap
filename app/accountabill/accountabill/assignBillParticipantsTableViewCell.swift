//
//  assignBillParticipantsCollectionViewCell
//  accountabill
//
//  Created by Michael Wornow on 7/26/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import AlamofireImage

class assignBillParticipantsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var firstCell: Bool? {
        didSet {
            let firstCellVal = firstCell!
            if firstCellVal {
                nameLabel.text = "Edit people"
                profileImageView.image = #imageLiteral(resourceName: "edituser_icon")
            }
        }
    }
    var secondCell: Bool? {
        didSet {
            let secondCellVal = secondCell!
            if secondCellVal {
                nameLabel.text = "Review"
                profileImageView.image = #imageLiteral(resourceName: "review_icon")
            }
        }
    }
    var user: User? {
        didSet {
            let userVal = user!
            nameLabel.text = userVal.name
            if userVal.photoURL != nil {
                profileImageView.af_setImage(withURL: URL(string: userVal.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
            else if userVal.facebookID != nil {
                let imageURL = "https://graph.facebook.com/v2.10/"+userVal.facebookID!+"/picture"
                profileImageView.af_setImage(withURL: URL(string: imageURL)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"), runImageTransitionIfCached: true, completion: nil)
            }
        }
    }
    
    override func awakeFromNib() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
        profileImageView.clipsToBounds = true;
    }
}

