//
//  groupsViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/15/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import FirebaseAuth

class groupsViewController: UIViewController, EmbeddedViewControllerReceiver, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var billsButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var selectedMenuItemView: UIView!
    
    var embeddedDelegate: EmbeddedViewControllerDelegate?
    var groups: [Group] = []
    var allUsers: [[User]] = []
    var storedOffsets = [Int: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menu item
        selectedMenuItemView.layer.cornerRadius = 2
        
        //set up layout of collection view
        collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchGroups()
    }
    
    func fetchGroups() {
        FirebaseOps.getUserGroups(user: FirebaseOps.currentUser!) { (groups, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            else if let groups = groups {
                self.groups = groups
                self.collectionView.reloadData()
                for i in 0..<groups.count{
                    self.allUsers.append([])
                    self.fetchUsers(group: groups[i], index: i)
                }
            }
        }
    }
    
    func fetchUsers(group: Group, index: Int) {
        FirebaseOps.getGroupUsers(group: group) { (users, error) in
            if let error = error {
                print("error getting group members")
                print(error)
            }
            else if let users = users {
                for user in users{
                    if user.uid == group.author?.uid {
                        group.author = user
                    }
                }
                group.users = users
                self.allUsers[index] = users
                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView{
            return groups.count
        } else {
            return allUsers[collectionView.tag].count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupsCollectionViewCell", for: indexPath) as! groupsCollectionViewCell
            cell.setCollectionViewDataSourceDelegate(self, forItem: indexPath.item)
            cell.collectionViewOffset = storedOffsets[indexPath.item] ?? 0
            cell.group = groups[indexPath.item]
            cell.group.users = groups[indexPath.item].users
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupMemberCollectionViewCell", for: indexPath) as! groupMemberCollectionViewCell
            cell.user = allUsers[collectionView.tag][indexPath.item]
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView{
            guard let groupCell = cell as? groupsCollectionViewCell else { return }
            groupCell.setCollectionViewDataSourceDelegate(self, forItem: indexPath.item)
            groupCell.collectionViewOffset = storedOffsets[indexPath.item] ?? 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
            guard let groupCell = cell as? groupsCollectionViewCell else { return }
            storedOffsets[indexPath.item] = groupCell.collectionViewOffset
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //
    // Pan gesture
    //
    @IBAction func groupPanGestureAction(_ sender: UIPanGestureRecognizer) {
        embeddedDelegate?.panGestureAction(sender)
    }
    @IBAction func homeButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.center, sender: sender)
    }
    @IBAction func billsButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.left, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        if let indexPath = collectionView.indexPath(for: cell){
            let group = groups[indexPath.item]
            let detailViewController = segue.destination as! groupDetailViewController
            detailViewController.group = group
        }
    }

}
