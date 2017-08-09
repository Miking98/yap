//
//  groupsCollectionViewCell.swift
//  accountabill
//
//  Created by Michael Wornow on 7/16/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class groupsCollectionViewCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var greenView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var memberCountLabel: UILabel!
    
    var group: Group! {
        didSet {
            self.layer.borderColor = UIColor(red: 153.0/255.0, green: 227.0/255.0, blue: 211.0/255.0, alpha: 0.85).cgColor
            self.layer.borderWidth = 2
            self.greenView.backgroundColor = UIColor(red: 82.0/255.0, green: 194.0/255.0, blue: 161.0/255.0, alpha: 0.95)
            self.groupNameLabel.text = group.name
            self.memberCountLabel.text = "\(group.users.count)" + " Members"
        }
    }
    
    override func awakeFromNib() {
        let screenWidth = 167
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: screenWidth/2, height: screenWidth/2)
    }
}


extension groupsCollectionViewCell {
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate: D, forItem item: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = item
        collectionView.setContentOffset(collectionView.contentOffset, animated:false) // Stops collection view if it was scrolling.
        collectionView.reloadData()
    }
    
    var collectionViewOffset: CGFloat {
        set { collectionView.contentOffset.y = newValue }
        get { return collectionView.contentOffset.y }
    }
}
