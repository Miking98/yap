//
//  groupDetailViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/15/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class groupDetailViewController: UIViewController, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var billCountLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    var group: Group!
    var userAmounts: [String: Double] = [:]
    var userCompletedAmounts: [String: Double] = [:]
    var userCompletedPercentages: [String: Double] = [:]
    var userTotalReceiveAmounts: [String: Double] = [:]
    var userReceivedAmounts: [String: Double] = [:]
    var userReceivedPercentages: [String: Double] = [:]
    //var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.isHidden = true
        collectionView.isHidden = false
        segmentedControl.layer.cornerRadius = 4.0
        segmentedControl.clipsToBounds = true
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let cellsPerLine: CGFloat = 2
        let interItemSpacingTotal = layout.minimumInteritemSpacing * (cellsPerLine - 1)
        let width = collectionView.frame.size.width / cellsPerLine - interItemSpacingTotal / cellsPerLine
        layout.itemSize = CGSize(width: width, height: width)
        
        nameLabel.text = group.name
        memberCountLabel.text = String(format: "%d", group.users.count)
        billCountLabel.text = String(format: "%d", group.bills.count)
        createdAtLabel.text = group.createdDatePrint()
    }
    
    //
    // Hide carrier status bar
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
        initializeAmounts()
        computePaymentStatuses()
    }
    
    func initializeAmounts() {
        for user in group.users {
            userAmounts[user.uid!] = 0.0
            userCompletedAmounts[user.uid!] = 0.0
            userCompletedPercentages[user.uid!] = 0.0
            userTotalReceiveAmounts[user.uid!] = 0.0
            userReceivedAmounts[user.uid!] = 0.0
            userReceivedPercentages[user.uid!] = 0.0
        }
    }
    
    func computePaymentStatuses() {
        for b in group.bills {
            DefaultOps.getUsersPaymentStatusForBill(bill: b) { (statuses: [String : Any]?, error: Error?) in
                if let error = error {
                    print("Error getting payment statuses for bill "+(b.name ?? ""))
                    print(error)
                }
                else if let statuses = statuses {
                    for (uid, value) in statuses {
                        if let value = value as? [String: Any] {
                            let paid = value["paid"] as? Bool ?? false
                            let amount = value["amount"] as? Double ?? 0
                            let timeTaken = value["timeTaken"] as? Int ?? 0
                            self.userAmounts[uid]! += amount
                            self.userCompletedAmounts[uid]! += paid ? amount : 0
                            self.userCompletedPercentages[uid] = (100 * self.userCompletedAmounts[uid]!/self.userAmounts[uid]!).rounded()
                            self.userReceivedAmounts[b.author!.uid!]! += paid ? amount : 0
                            self.userTotalReceiveAmounts[b.author!.uid!]! += amount
                            self.userReceivedPercentages[b.author!.uid!] = (100 * self.userReceivedAmounts[b.author!.uid!]!/self.userTotalReceiveAmounts[b.author!.uid!]!).rounded()
                        }
                    }
                    for user in self.group.users {
                        if self.userAmounts[user.uid!] == 0.0 {
                            self.userCompletedPercentages[user.uid!] = 100.0
                        }
                        if self.userTotalReceiveAmounts[user.uid!] == 0.0 {
                            self.userReceivedPercentages[user.uid!] = 100.0
                        }
                    }
                    self.collectionView.reloadData()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return group.users.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupUsersCollectionViewCell", for: indexPath) as! groupUsersCollectionViewCell
        let user = group.users[indexPath.item]
        var amounts: [String: Double] = [:]
        amounts["paid"] = userCompletedAmounts[user.uid!]
        amounts["totalPay"] = userAmounts[user.uid!]
        amounts["paidPercentage"] = userCompletedPercentages[user.uid!]
        amounts["received"] = userReceivedAmounts[user.uid!]
        amounts["totalReceive"] = userTotalReceiveAmounts[user.uid!]
        amounts["receivedPercentage"] = userReceivedPercentages[user.uid!]
        
        cell.user = user
        cell.amounts = amounts
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.bills.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupBillsTableViewCell", for: indexPath) as! billsTableViewCell
        cell.bill = group.bills[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func onSegmentedChange(_ sender: Any) {
        let index = segmentedControl.selectedSegmentIndex
        if index == 0 {
            self.tableView.isHidden = true
            self.collectionView.isHidden = false
        } else {
            tableView.isHidden = false
            collectionView.isHidden = true
        }
    }
    
    //
    // Top menu buttons
    //
    @IBAction func backButtonTouch(_ sender: Any) {
        navigationController?.popViewController(animated:true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "groupToBillDetail" {
            let cell = sender as! billsTableViewCell
            if let indexPath = tableView.indexPath(for: cell){
                let bill = group.bills[indexPath.row]
                let detailViewController = segue.destination as! billDetailViewController
                detailViewController.bill = bill
                
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
