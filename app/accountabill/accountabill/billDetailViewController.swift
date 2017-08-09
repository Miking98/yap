//
//  billDetailViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/15/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SCLAlertView

class billDetailViewController: UIViewController, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    var billStatus: [String:Bool] = [:]
    var status: [String:Bool] = [:]
    var users: [User] = []
    var author: User?
    var bill: Bill!
    var items: [BillItem] = []
    var userOwes: [String:Double] = [:]
    var taxCalc: Double?
    var tipCalc: Double?
    var userTotal: Double?
    var leftovers: Double = Double(0)
    var userAmounts: [String: Double] = [:]
    var userCompletedAmounts: [String: Double] = [:]
    var userCompletedPercentages: [String: Double] = [:]
    var userReceivedAmounts: [String: Double] = [:]
    var paid: Bool = false
    var amount: Double = Double(0)
    
    
    @IBOutlet weak var billDetailItemsTableView: UITableView!
    @IBOutlet weak var heroTableView: UITableView!
    @IBOutlet weak var profileCollectionView: UICollectionView!
    @IBOutlet weak var dateandLocationLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var billNameLabel: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var receiptImage: UIImageView!
    @IBOutlet weak var yourTotalLabel: UILabel!
    @IBOutlet weak var remindButton: UIButton!
    var activitySpinner: ActivitySpinnerView!
    
    let greenButtonBGColor = UIColor(red: 51/255.0, green: 206/255.0, blue: 109/255.0, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileCollectionView.dataSource = self
        billDetailItemsTableView.dataSource = self
        billDetailItemsTableView.delegate = self
        heroTableView.dataSource = self
        heroTableView.delegate = self
        fetchUsers()
        
        profileCollectionView.backgroundColor = UIColor.clear
        
        //receipt image formatting
        receiptImage.image = #imageLiteral(resourceName: "profile_icon")// TODO - image of receipt
        receiptImage.layer.borderColor = UIColor.white.cgColor
        receiptImage.layer.borderWidth = 3
        
        //button formatting
        payButton.layer.cornerRadius = 10
        payButton.layer.shadowColor = UIColor.gray.cgColor
        payButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        payButton.layer.shadowRadius = 5
        payButton.layer.shadowOpacity = 0.5
        payButton.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
        payButton.layer.borderWidth = 1
        
        //button formatting
        remindButton.layer.cornerRadius = 10
        remindButton.layer.shadowColor = UIColor.gray.cgColor
        remindButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        remindButton.layer.shadowRadius = 5
        remindButton.layer.shadowOpacity = 0.5
        remindButton.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
        remindButton.layer.borderWidth = 1
        
        
        //if bill creater is the current user show a different table view
        if bill.author?.uid == FirebaseOps.currentUser?.uid{
            billDetailItemsTableView.isHidden = true
            heroTableView.isHidden = false
            payButton.isHidden = true
            
        }
        else {
            heroTableView.isHidden = true
            billDetailItemsTableView.isHidden = false
            remindButton.isHidden = true
        }
        
        billNameLabel.text = bill?.name
        if let group = bill?.group{
            groupNameLabel.text = group.name
        }
        else {
            groupNameLabel.text = "Participants"
        }
        let formattedDate = bill.createdDatePrint()
        if let location = bill?.location {
            dateandLocationLabel.text = formattedDate + " | " + location
        }
        else {
            dateandLocationLabel.text = formattedDate
        }
        
        // Add Activity Spinner loading icon for uploading image to Heroku
        activitySpinner = ActivitySpinnerView()
        self.view.addSubview(activitySpinner)
    }
    
    @IBAction func onReceiptImage(_ sender: UITapGestureRecognizer){
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
    }
    
    func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }
    
    // Pay bill in bill detail view
    func showAlert() {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "Avenir", size: 20)!,
            kTextFont: UIFont(name: "Avenir", size: 14)!,
            kButtonFont: UIFont(name: "Avenir-Medium", size: 20)!,
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Yes, pay now", backgroundColor: greenButtonBGColor, textColor: UIColor.white) {
            FirebaseOps.payBill(bill: self.bill, user: FirebaseOps.currentUser!, completion: { (error: Error?) in
                self.navigationController?.popViewController(animated: true)
            })
        }
        alert.addButton("No, forget it", backgroundColor: UIColor.red, textColor: UIColor.white) {
        }
        alert.showSuccess("Confirm Payment", subTitle: "Are you sure you want to pay " + bill.author!.name!+"?")
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === billDetailItemsTableView{
            return bill.items.count + 2
        }
        else {
            return bill.participants.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        if tableView === heroTableView && bill.participants[indexPath.row].uid == FirebaseOps.currentUser?.uid {
            return 0.0
        }
        else {
            return 60.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if tableView === billDetailItemsTableView {
            if indexPath.row == bill.items.count{
                let taxcell = billDetailItemsTableView.dequeueReusableCell(withIdentifier: "taxTableViewCell") as! taxTableViewCell
                taxcell.bill = bill
                taxcell.tax = bill.tax
                taxcell.taxCalc = bill.tax!/Double(3)
                taxcell.selectionStyle = UITableViewCellSelectionStyle.none
                return taxcell
            }
            else if indexPath.row == bill.items.count + 1{
                let tipcell = billDetailItemsTableView.dequeueReusableCell(withIdentifier: "tipTableViewCell") as! tipTableViewCell
                tipcell.bill = bill
                tipcell.tip = bill.tip
                self.tipCalc = bill.tip!/Double(3)
                tipcell.tipCalc = self.tipCalc
                tipcell.selectionStyle = UITableViewCellSelectionStyle.none
                return tipcell
            }
            else {
                let cell = billDetailItemsTableView.dequeueReusableCell(withIdentifier: "billDetailItemTableViewCell", for: indexPath) as! billDetailItemTableViewCell
                cell.bill = bill
                cell.item = bill.items[indexPath.row]
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                return cell
            }
        }
        else {
            let herocell = heroTableView.dequeueReusableCell(withIdentifier: "heroTableViewCell", for: indexPath) as! HeroTableViewCell
            herocell.user = bill.participants[indexPath.row]
            herocell.bill = bill
            herocell.selectionStyle = UITableViewCellSelectionStyle.none
            return herocell
        }
        
    }
    
    
    func computePaymentStatuses() {
        FirebaseOps.getUsersPaymentStatusForBill(bill: bill) { (statuses: [String : Any]?, error: Error?) in
            var calculation = Double(0)
            if let error = error {
                print("Error getting payment statuses for bill "+(self.bill.name ?? ""))
                print(error)
            }
            else if let statuses = statuses {
                self.userReceivedAmounts = [self.bill.author!.uid!:0]
                for (uid, value) in statuses {
                    if let value = value as? [String: Any] {
                        let amount = value["amount"] as? Double ?? 0
                        self.userAmounts[uid] = amount
                        calculation += amount
                        if uid == FirebaseOps.currentUser?.uid {
                            self.paid = value["paid"] as? Bool ?? false
                            if self.paid == false{
                                self.payButton.backgroundColor = UIColor(red: 200.0/255.0, green: 82.0/255.0, blue: 115.0/255.0, alpha: 1)
                            }
                            else {
                                self.payButton.isHidden = true
                                
                            }
                            self.userReceivedAmounts[self.bill.author!.uid!]! += self.paid ? amount : 0
                        }
                    }
                    
                }
                if self.bill.author?.uid == FirebaseOps.currentUser?.uid {
                    var waiting = false
                    var waitingAmount = 0.0
                    var receivedAmount = 0.0
                    for (uid, value) in statuses {
                        if let value = value as? [String: Any] {
                            if !(value["paid"] as? Bool ?? false) {
                                waiting = true
                                if FirebaseOps.currentUser?.uid != uid {
                                    waitingAmount += value["amount"] as? Double ?? 0
                                }
                            }
                            else {
                                if FirebaseOps.currentUser?.uid != uid {
                                    receivedAmount += value["amount"] as? Double ?? 0
                                }
                            }
                        }
                    }
                    if waiting {
                        self.yourTotalLabel.text = "Waiting On:"
                        self.amountLabel.text = "$" + String(format: "%.2f", waitingAmount)
                    }
                    else {
                        self.yourTotalLabel.text = "Received: "
                        self.amountLabel.text = "$" + String(format: "%.2f", receivedAmount)
                        self.remindButton.isHidden = true
                    }
                }
                else {
                    if self.paid == true{
                        self.yourTotalLabel.text = "You Paid"
                        self.amountLabel.text = "$" + String(format: "%.2f", self.userAmounts[(FirebaseOps.currentUser?.uid)!]!)
                    }
                    else{
                        self.yourTotalLabel.text = "Your Total"
                        self.amountLabel.text = "$" + String(format: "%.2f", self.userAmounts[(FirebaseOps.currentUser?.uid)!]!)
                    }
                }
                self.heroTableView.reloadData()
                self.billDetailItemsTableView.reloadData()
            }
            
        }
        
    }
    
    func fetchUsers(){
        FirebaseOps.getBillUsers(bill: bill!) { (users, error) in
            if let error = error{
                print(error.localizedDescription)
            }
            else if let users = users{
                self.users = users
                self.computePaymentStatuses()
                self.profileCollectionView.reloadData()
            }
        }
        FirebaseOps.getUser(user: bill.author!) { (user, error) in
            if let user = user {
                self.author = user
            }
            else if let error = error {
                print("error getting author")
            }
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "billsDetailCollectionViewCell", for: indexPath) as! billsDetailCollectionViewCell
        let user = users[indexPath.item]
        cell.user = user
        return cell
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //
    // Hide carrier status bar
    //
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //
    // Top menu buttons
    //
    @IBAction func backButtonTouch(_ sender: Any) {
        navigationController?.popViewController(animated:true)
    }
    
    
    @IBAction func onPay(_ sender: Any) {
        showAlert()
    }
    
    @IBAction func remindButtonTouch(_ sender: Any) {
        activitySpinner.show(text: "Sending reminder")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.activitySpinner.updateText(text: "Done")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activitySpinner.hide()
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
