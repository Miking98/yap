//
//  editBillParticipantsSearchTableViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/24/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import AlamofireImage

class editBillParticipantsSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var result: Any! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            if let user = result as? User  {
                nameLabel.text = user.name
                if user.uid != nil {
                    self.profileImageView.image = DefaultOps.pictures(user: user)
                }
                else if user.facebookTaggableID != nil && user.photoURL != nil {
                    self.profileImageView.af_setImage(withURL: URL(string: user.photoURL!)!, placeholderImage: #imageLiteral(resourceName: "profile_icon"))
                }
            }
            else if let group = result as? Group {
                nameLabel.text = group.name
                profileImageView.image = #imageLiteral(resourceName: "profile_icon")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        profileImageView.image = #imageLiteral(resourceName: "profile_icon")
    }

}
