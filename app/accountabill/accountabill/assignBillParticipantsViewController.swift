//
//  assignBillParticipantsViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/26/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import SCLAlertView

class assignBillParticipantsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var billNameLabel: UILabel!
    
    @IBOutlet weak var participantCollectionView: UICollectionView! // Has tag = 1 for scrollview identification
    @IBOutlet weak var participantSelectionPaneView: UIView!
    @IBOutlet weak var billItemsTableView: UITableView! // Has tag = 2
    
    @IBOutlet weak var finishButton: UIButton!
    
    
    var bill: Bill!
    var selectedParticipant: Int? // Holds index of participant currently selected by participant carousel
    var finishButtonConfirmed = false // Used to confirm Finish on consecutive double tap
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        billNameLabel.text = bill.name!
        
        // Participant collection view
        participantCollectionView.delegate = self
        participantCollectionView.dataSource = self
        participantCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        // Style selection pane for participants
        participantSelectionPaneView.layer.borderWidth = 2
        participantSelectionPaneView.layer.cornerRadius = 4
        participantSelectionPaneView.layer.borderColor = UIColor(red:93/255.0, green:178/255.0, blue:167/255.0, alpha: 1.0).cgColor
        
        // Set up Table View of bill items
        billItemsTableView.delegate = self
        billItemsTableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // Participant carousel collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bill.participants.count + 2 // Need to add 2 because of add participant cell and everyone cell
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "assignBillParticipantsCollectionViewCell", for: indexPath) as! assignBillParticipantsCollectionViewCell
        if indexPath.row == 0 {
            // Have first cell always be add participant cell
            cell.firstCell = true
        }
        else if indexPath.row == 1 {
            cell.secondCell = true
        }
        else {
            cell.user = bill.participants[indexPath.row - 2]
        }
        return cell
    }
    // Snap scrolling carousel to grid
    func participantCarouselSnapToGrid() {
        let visibleCenterPositionOfScrollView = Float(participantCollectionView.contentOffset.x + (participantCollectionView!.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<participantCollectionView.visibleCells.count {
            let cell = participantCollectionView.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = participantCollectionView.indexPath(for: cell)!.row
            }
        }
        if closestCellIndex != -1 {
            participantCollectionView!.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
        if closestCellIndex > 1 {
            // User cell is selected, not a non-user cell
            if selectedParticipant == closestCellIndex - 2 {
                // Selection pane hasn't moved, do nothing
            }
            else {
                selectedParticipant = closestCellIndex - 2
                // Recalculate which rows should be selected
                billItemsTableView.reloadData()
            }
        }
        else {
            // Non-user cell is selected (e.g. edit users, review mode)
            selectedParticipant = nil
            // Deselect all rows
            billItemsTableView.reloadData()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.tag == 1 {
            participantCarouselSnapToGrid()
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.tag == 1 {
            if !decelerate {
                participantCarouselSnapToGrid()
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            // Edit participants button clicked
            performSegue(withIdentifier: "assignBillParticipantsToEditBillParticipants", sender: self)
        }
    }
    // Propagate pan gesture from selection pane to participant carousel collection view
    @IBAction func selectionPanePanGestureAction(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: self.view)
            participantCollectionView.contentOffset = CGPoint(x: participantCollectionView.contentOffset.x - translation.x, y: participantCollectionView.contentOffset.y)
            sender.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
        }
        if sender.state == .ended {
            participantCarouselSnapToGrid()
        }
    }
    
    // Add participant to item
    @IBAction func billItemTableViewCellTapGesture(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: billItemsTableView)
        let indexPathOfTap = billItemsTableView.indexPathForRow(at: location)
        if let indexPath = indexPathOfTap {
            // Check if a user is currently selected
            if let participantIndex = selectedParticipant {
                let user = bill.participants[participantIndex]
                if bill.items[indexPath.row].hasParticipant(user: user) {
                    deselectRow(indexPath: indexPath, user: user)
                }
                else {
                    selectRow(indexPath: indexPath, user: user)
                }
            }
            else {
                // Functional cell (e.g. add user) is currently selected
                billItemsTableView.deselectRow(at: indexPath, animated: true)
            }
        }
        // Reset finish button to default state
        resetFinishButton()
    }
    
    // Bill Items table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bill.items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "assignBillItemsTableViewCell", for: indexPath) as! assignBillItemsTableViewCell
        cell.item = bill.items[indexPath.row]
        cell.selectionStyle = .none
        styleRow(indexPath: indexPath, cell: cell)
        return cell
    }
    func selectRow(indexPath: IndexPath, user: User) {
        bill.items[indexPath.row].addParticipant(user: user)
        billItemsTableView.reloadData()
    }
    func deselectRow(indexPath: IndexPath, user: User) {
        bill.items[indexPath.row].removeParticipant(user: user)
        billItemsTableView.reloadData()
    }
    func styleRow(indexPath: IndexPath, cell: assignBillItemsTableViewCell) {
        if selectedParticipant != nil {
            if bill.items[indexPath.row].hasParticipant(user: bill.participants[selectedParticipant!]) {
                styleSelectedRow(indexPath: indexPath, cell: cell)
            }
            else {
                styleDeselectedRow(indexPath: indexPath, cell: cell)
            }
        }
        else {
            styleDeselectedRow(indexPath: indexPath, cell: cell)
        }
    }
    func styleSelectedRow(indexPath: IndexPath, cell: assignBillItemsTableViewCell) {
        let bgColor = UIColor(red: 195/255.0, green: 231/255.0, blue: 232/255.0, alpha: 1)
        cell.contentView.backgroundColor = bgColor
        cell.profileImagesCollectionView.backgroundColor = bgColor
    }
    func styleDeselectedRow(indexPath: IndexPath, cell: assignBillItemsTableViewCell) {
        let bgColor = UIColor.white
        cell.contentView.backgroundColor = bgColor
        cell.profileImagesCollectionView.backgroundColor = bgColor
    }
    
    // Split check button
    @IBAction func splitButtonTouch(_ sender: Any) {
        for i in bill.items {
            i.setParticipants(participants: bill.participants)
        }
        // Reselect rows
        billItemsTableView.reloadData()
        resetFinishButton()
    }
    
    // Cancel button
    @IBAction func cancelButtonTouch(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "Avenir", size: 20)!,
            kTextFont: UIFont(name: "Avenir", size: 14)!,
            kButtonFont: UIFont(name: "Avenir-Medium", size: 20)!,
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Yes, delete bill", backgroundColor: UIColor.red, textColor: UIColor.white) {
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addButton("No, wait", backgroundColor: UIColor.blue, textColor: UIColor.white) {
        }
        alert.showWarning("Are you sure?", subTitle: "Cancelling will delete all of this bill's data.")
    }

    // Finish button
    func resetFinishButton() {
        finishButtonConfirmed = false
        finishButton.backgroundColor = UIColor(red: 226/255.0, green: 96/255.0, blue: 135/255.0, alpha: 1.0)
        finishButton.setTitle("Looks Good", for: UIControlState.normal)
    }
    func activateFinishButton() {
        finishButton.setTitle("Finish and Send", for: UIControlState.normal)
        finishButton.backgroundColor = UIColor(red: 0/255.0, green: 162/255.0, blue: 78/255.0, alpha: 1.0)
        finishButtonConfirmed = true
    }
    @IBAction func finishButtonTouch(_ sender: Any) {
        if finishButtonConfirmed {
            print("Finish button clicked")
            DefaultOps.createBill(bill: bill, completion: { (error: Error?, newBill: Bill?) in
                if let error = error {
                    print("Error creating bill")
                    print(error.localizedDescription)
                }
                else {
                    print("Success creating bill")
                    DefaultOps.sendBill(bill: newBill!, completion: { (error: Error?) in
                        if let error = error {
                            print("Error sending bill")
                            print(error.localizedDescription)
                        }
                        else {
                            print("Successfully created and sent out bill")
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                }
            })
        }
        else {
            activateFinishButton()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "assignBillParticipantsToEditBillParticipants" {
            let vc = segue.destination as! accountabill.editBillParticipantsViewController
            vc.bill = bill
        }
    }

}
