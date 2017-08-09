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
            self.memberPhotoView.image = DefaultOps.pictures(user: user)
            memberPhotoView.clipsToBounds = true
            //memberPhotoView.layer.cornerRadius = 40
        }
    }
}
