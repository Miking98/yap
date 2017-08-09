//
//  billsViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/14/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import FirebaseDatabase

class billsViewController: UIViewController, EmbeddedViewControllerReceiver, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var selectedMenuItemView: UIView!
    
    @IBOutlet weak var billsButton: UIButton!
    @IBOutlet weak var billsTableView: UITableView!
    
    @IBOutlet weak var billsSegmentedControl: UISegmentedControl!
    
    var embeddedDelegate: EmbeddedViewControllerDelegate?
    var moocherbills: [Bill] = []
    var herobills: [Bill] = []
    var bills: [Bill] = []
    var user = DefaultOps.currentUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        billsSegmentedControl.layer.cornerRadius = 4.0
        billsSegmentedControl.clipsToBounds = true
        billsTableView.dataSource = self
        billsTableView.delegate = self
        
        // Menu
        selectedMenuItemView.layer.cornerRadius = 2
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchHeroBills()
        fetchMoocherBills()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if billsSegmentedControl.selectedSegmentIndex == 1{
            return moocherbills.count
        }
        else {
            return herobills.count
            
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "billsTableViewCell", for: indexPath) as! billsTableViewCell
        if billsSegmentedControl.selectedSegmentIndex == 1{
            cell.bill = moocherbills[indexPath.row]
        }
        else {
            cell.bill = herobills[indexPath.row]
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    
    
    func fetchMoocherBills(){
        DefaultOps.getUserMoocherBills(user: DefaultOps.currentUser!) { (bills, error) in
            if let error = error {
                print("Error getting home timeline: " + error.localizedDescription)
            }
            else if let moocherbills = bills {
                self.moocherbills = moocherbills
                self.user.moocherBills = moocherbills
                self.billsTableView.reloadData()
            }
        }
        
    }
    
    func fetchHeroBills(){
        DefaultOps.getUserHeroBills(user: DefaultOps.currentUser!) { (bills, error) in
            if let error = error {
                print("Error getting home timeline: " + error.localizedDescription)
            }
            else if let herobills = bills {
                self.herobills = herobills
                self.user.heroBills = herobills
                self.billsTableView.reloadData()
            }
            
        }
    }
    
    
    @IBAction func onHeroMoocher(_ sender: Any) {
        if billsSegmentedControl.selectedSegmentIndex == 1{
            bills = self.moocherbills
            billsTableView.reloadData()
        }else{
            bills = self.herobills
            billsTableView.reloadData()
        }
    }
    
    
    //
    // Pan gesture
    //
    @IBAction func billPanGestureAction(_ sender: UIPanGestureRecognizer) {
        embeddedDelegate?.panGestureAction(sender)
    }
    @IBAction func groupButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.right, sender: sender)
    }
    @IBAction func homeButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.center, sender: sender)
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "billDetailSegue"{
            let vc = segue.destination as! billDetailViewController
            if let cell = sender as? UITableViewCell, let indexPath = billsTableView.indexPath(for: cell) {
                if billsSegmentedControl.selectedSegmentIndex == 1{
                    vc.bill = moocherbills[indexPath.row]
                }else{
                    vc.bill = herobills[indexPath.row]
                }
                
            }
            
        }
    }
}
