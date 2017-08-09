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
    
    var user: User?{
        didSet {
            self.profilePictures.layer.borderColor = UIColor.white.cgColor
            self.profilePictures.layer.borderWidth = 2
            self.profilePictures.layer.cornerRadius = self.profilePictures.frame.size.width / 2
            self.profilePictures.image = DefaultOps.pictures(user: user!)
        }
    }
}
