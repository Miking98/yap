//
//  editBillScanViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CoreLocation
import SCLAlertView

class editBillScanViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var insetView: UIView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var billNameFloatingTextField: ACFloatingTextfield!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var tipFloatingTextField: ACFloatingTextfield!
    @IBOutlet weak var taxFloatingTextField: ACFloatingTextfield!
    @IBOutlet weak var totalLabel: UILabel!
    
    @IBOutlet weak var itemsTableView: UITableView!
    
    var bill: Bill!
    let locationServices = LocationManager.shared
    var currentLocation: CLLocation?
    var currentlySelectedItem: IndexPath?
    var itemEditAlert: SCLAlertView?
    
    var keyboardIsShown: Bool = false
    let greenButtonBGColor = UIColor(red: 51/255.0, green: 206/255.0, blue: 109/255.0, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Rationalize bill totals (in case subtotal and total weren't correctly parsed)
        bill.rationalizeTotals()
        
        // Style Inset View
        // TODO _ make inset shadow 
        
        // Set up Items Table View
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.setEditing(true, animated: true)
        
        // Set up text fields
        tipFloatingTextField.delegate = self
        taxFloatingTextField.delegate = self
        billNameFloatingTextField.delegate = self
        
        // Keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        // Location services
        locationServices.requestWhenInUseAuthorization()
        locationServices.delegate = self
        if bill.location == nil {
            locationServices.startUpdatingLocation()
        }
        
        // Set author to current user
        bill.setAuthor(user: DefaultOps.currentUser!)
        // Auto-fill in bill items
        billNameFloatingTextField.text = bill.name ?? "Default Bill Name"
        dateLabel.text = bill.createdDatePrint() + " | " + bill.locationPrint()
        setBillSpecialInfo()
        // Also poll for current location and reset locationLabel once that is determined
    }
    
    func setBillSpecialInfo() {
        subtotalLabel.text = String(format: "%.2f", bill.subtotal ?? 0)
        taxFloatingTextField.text = String(format: "%.2f", bill.tax ?? 0)
        tipFloatingTextField.text = String(format: "%.2f", bill.tip ?? 0)
        totalLabel.text = String(format: "$%.2f", bill.total ?? 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bill.items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "editBillItemTableViewCell", for: indexPath) as! editBillItemTableViewCell
        cell.item = bill.items[indexPath.row]
        
        return cell
    }
    // Editing of table view items
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            bill.removeItem(itemIndex: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            setBillSpecialInfo()
        }
        else if editingStyle == .insert {
            
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if keyboardIsShown {
            // Don't propogate taps if keyboard is shown, b/c user just wants to exit keyboard if tapping, not select something
            return
        }
        currentlySelectedItem = indexPath
        showEditItemAlert()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = (LocationManager.shared.location?.coordinate)!
        currentLocation =  CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        // Setting bill's locaiton must be asynchronous because reverse geo coding is a network request
        bill.formatLocationForPrint(location: currentLocation!, completion: { (location: String) in
            self.bill.location = location
            self.dateLabel.text = self.bill.createdDatePrint()  + " | " + self.bill.location!
            self.locationServices.stopUpdatingLocation()
        })
    }
    // Edit bill item alert
    func createEditItemAlert() -> SCLAlertView {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "Avenir", size: 20)!,
            kTextFont: UIFont(name: "Avenir", size: 14)!,
            kButtonFont: UIFont(name: "Avenir-Medium", size: 20)!,
            showCloseButton: false
        )
        itemEditAlert = SCLAlertView(appearance: appearance)
        return itemEditAlert!
    }
    func showEditItemAlert() {
        if currentlySelectedItem == nil {
            return
        }
        let indexPath = currentlySelectedItem!
        
        // Create alert
        let alert = createEditItemAlert()
        // Create text fields
        let nameTextField = alert.addTextField()
        nameTextField.layer.borderColor = UIColor.black.cgColor
        nameTextField.placeholder = "Item name"
        nameTextField.returnKeyType = UIReturnKeyType.done
        nameTextField.delegate = self
        let priceTextField = alert.addTextField()
        priceTextField.layer.borderColor = UIColor.black.cgColor
        priceTextField.placeholder = "0.00"
        priceTextField.keyboardType = UIKeyboardType.decimalPad
        priceTextField.returnKeyType = UIReturnKeyType.done
        priceTextField.delegate = self
        // Set text field values to current item values
        nameTextField.text = bill.items[indexPath.row].name ?? ""
        priceTextField.text = String(format: "%.2f", bill.items[indexPath.row].price ?? "")
        
        // Buttons
        alert.addButton("Confirm", backgroundColor: greenButtonBGColor, textColor: UIColor.white) {
            // Validate input
            let price = Double(priceTextField.text!)
            let name = nameTextField.text
            if name != nil && name != "" {
                self.bill.items[self.currentlySelectedItem!.row].name = name
            }
            if price != nil {
                self.bill.editItemPrice(oldItemIndex: self.currentlySelectedItem!.row, newPrice: price!)
            }
            self.itemsTableView.reloadData()
            self.setBillSpecialInfo()
        }
        // Add Button with Duration Status and custom Colors
        alert.addButton("Cancel", backgroundColor: UIColor.red, textColor: UIColor.white) {
            print("Canceled item edit")
        }
        alert.showEdit("Edit Item", subTitle: "")
    }
    func showAddItemAlert() {
        // Create alert
        let alert = createEditItemAlert()
        
        // Create text fields
        let nameTextField = alert.addTextField()
        nameTextField.layer.borderColor = UIColor.black.cgColor
        nameTextField.placeholder = "Item name"
        nameTextField.returnKeyType = UIReturnKeyType.done
        nameTextField.delegate = self
        let priceTextField = alert.addTextField()
        priceTextField.layer.borderColor = UIColor.black.cgColor
        priceTextField.placeholder = "0.00"
        priceTextField.keyboardType = UIKeyboardType.decimalPad
        priceTextField.returnKeyType = UIReturnKeyType.done
        priceTextField.delegate = self
        
        // Buttons
        alert.addButton("Add", backgroundColor: greenButtonBGColor, textColor: UIColor.white) {
            // Validate input
            let price = Double(priceTextField.text!)
            let name = nameTextField.text
            if name != nil && name != "" && price != nil {
                let newItem = BillItem(key: nil, name: name, price: price, quantity: nil, unitPrice: nil)
                self.bill.addItem(item: newItem)
            }
            self.itemsTableView.reloadData()
            self.setBillSpecialInfo()
        }
        // Add Button with Duration Status and custom Colors
        alert.addButton("Cancel", backgroundColor: UIColor.red, textColor: UIColor.white) {
            print("Canceled item add")
        }
        alert.showEdit("Add Item", subTitle: "")
    }
    
    // Keyboard events
    func keyboardDidShow(_ notification: NSNotification){
        keyboardIsShown = true
    }
    func keyboardDidHide(_ notification: NSNotification){
        keyboardIsShown = false
    }
    // Done button pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        itemEditAlert?.view.endEditing(true)
        view.endEditing(true)
        return true
    }
    
    //
    // Tapped on view, hide keyboard
    //
    @IBAction func mainTapGestureAction(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    
    // 
    // Text field editing
    //
    @IBAction func billNameFloatingTextFieldEditingDidEnd(_ sender: Any) {
        bill.name = billNameFloatingTextField.text
    }
    @IBAction func taxTextFieldEditingDidEnd(_ sender: Any) {
        bill.setTax(tax: Double(taxFloatingTextField.text!) ?? 0)
        setBillSpecialInfo()
    }
    @IBAction func tipTextFieldEditingDidEnd(_ sender: Any) {
        bill.setTip(tip: Double(tipFloatingTextField.text!) ?? 0)
        setBillSpecialInfo()
    }
    
    
    // Top menu buttons
    @IBAction func plusButtonTouch(_ sender: Any) {
        showAddItemAlert()
    }
    @IBAction func cancelButtonTouch(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "Avenir", size: 20)!,
            kTextFont: UIFont(name: "Avenir", size: 14)!,
            kButtonFont: UIFont(name: "Avenir-Medium", size: 20)!,
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Yes, delete bill", backgroundColor: UIColor.init(red: 157.0/255, green: 0/255.0, blue: 56.0/255.0, alpha: 1.0), textColor: UIColor.white) {
            self.navigationController?.popViewController(animated:true)
        }
        alert.addButton("No, wait", backgroundColor: UIColor.init(red: 0, green: 110.0/255.0, blue: 166.0/255.0, alpha: 1.0) , textColor: UIColor.white) {
        }
        alert.showWarning("Are you sure?", subTitle: "Cancelling will delete all of this bill's data.")
    }
    @IBAction func createButtonTouch(_ sender: Any) {
        self.performSegue(withIdentifier: "editBillScanToEditBillParticipants", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editBillScanToEditBillParticipants" {
            let vc = segue.destination as! editBillParticipantsViewController
            vc.bill = bill
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
