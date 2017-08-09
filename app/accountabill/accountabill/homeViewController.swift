//
//  homeViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/14/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import SwiftyCam
import Photos

class homeViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate, EmbeddedViewControllerReceiver, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var homePanGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var billsButton: UIButton!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    var activitySpinner: ActivitySpinnerView!
    
    var embeddedDelegate: EmbeddedViewControllerDelegate?
    
    var parsedBill: Bill?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Swifty Cam set up
        cameraDelegate = self
        shouldUseDeviceOrientation = true
        allowAutoRotate = false
        audioEnabled = false
        doubleTapCameraSwitch = false
        swipeToZoom = false
        
        // Add buttons to camera view
        self.view.addSubview(groupButton)
        self.view.addSubview(flashButton)
        self.view.addSubview(billsButton)
        self.view.addSubview(captureButton)
        self.view.addSubview(libraryButton)
        self.view.addSubview(manualButton)
        self.view.addSubview(profileButton)
        self.view.addGestureRecognizer(homePanGestureRecognizer)
        
        // Add Activity Spinner loading icon for uploading image to Heroku
        activitySpinner = ActivitySpinnerView()
        self.view.addSubview(activitySpinner)
    }
    
    //
    // Swifty Cam delegate methods
    //
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
        print("Photo")
        processReceipt(receipt: photo)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // Called when stopVideoRecording() is called and the video is finished processing
        // Returns a URL in the temporary directory where video is stored
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        // Called when a user initiates a tap gesture on the preview layer
        // Will only be called if tapToFocus = true
        // Returns a CGPoint of the tap location on the preview layer
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        // Called when a user initiates a pinch gesture on the preview layer
        // Will only be called if pinchToZoomn = true
        // Returns a CGFloat of the current zoom level
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        // Called when user switches between cameras
        // Returns current camera selection   
    }
    
    //
    // Camera utility functions
    //
    func toggleFlashAction() {
        flashEnabled = !flashEnabled
        if (!flashEnabled) {
            flashButton.setImage(#imageLiteral(resourceName: "noflash_icon_white"), for: UIControlState())
        }
        else {
            flashButton.setImage(#imageLiteral(resourceName: "flash_icon_white"), for: UIControlState())
        }
    }
    
    //
    // Button icon actions
    //
    @IBAction func captureButtonTouch(_ sender: Any) {
        takePhoto()
    }
    @IBAction func billsButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.left, sender: sender)
    }
    @IBAction func groupButtonTouch(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.right, sender: sender)
    }
    @IBAction func profileButton(_ sender: Any) {
        embeddedDelegate?.onShowContainer(.top, sender: sender)
    }
    @IBAction func flashButtonTouch(_ sender: Any) {
        toggleFlashAction()
    }
    @IBAction func libraryButtonTouch(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.allowsEditing = true
        vc.sourceType = UIImagePickerControllerSourceType.photoLibrary
        vc.allowsEditing = false
        self.present(vc, animated: true, completion: nil)
    }
    @IBAction func manualButtonTouch(_ sender: Any) {
        var items: [BillItem] = []
        items.append(BillItem(key: nil, name: "++ Not Sharing ++", price: 0.00, quantity: nil, unitPrice: nil))
        items.append(BillItem(key: nil, name: "24 Hrs Beef Noodle Soup", price: 41.90, quantity: nil, unitPrice: nil))
        items.append(BillItem(key: nil, name: "Coke", price: 2.95, quantity: nil, unitPrice: nil))
        items.append(BillItem(key: nil, name: "Crispy Calamari", price: 14.00, quantity: nil, unitPrice: nil))
        items.append(BillItem(key: nil, name: "Panang Neua", price: 25.50, quantity: nil, unitPrice: nil))
        parsedBill = Bill(key: nil, name: "Farmhouse", author: DefaultOps.currentUser!, completed: false, modifiedDate: Date(), createdDate: Date(), location: nil, items: [], receiptImage: "", tax: nil, tip: nil, subtotal: nil, total: nil, participants: [], group: nil)
        parsedBill!.setItems(items: items)
        parsedBill!.setTax(tax: 7.17)
        parsedBill!.setTip(tip: 0.00)
    }

    //
    // Library image picker
    //
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Get the image captured by the UIImagePickerController
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Get image metadata
        let URL = info[UIImagePickerControllerReferenceURL] as! URL
        let opts = PHFetchOptions()
        opts.fetchLimit = 1
        let asset = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)[0]
        parsedBill?.createdDate = asset.creationDate
        if let loc = asset.location {
            parsedBill?.formatLocationForPrint(location: loc, completion: { (location: String) in
                self.parsedBill?.location = location
            })
        }
        self.dismiss(animated: true, completion: nil)
        processReceipt(receipt: image)
    }
    
    //
    // Pan gesture
    //
    @IBAction func homePanGestureAction(_ sender: UIPanGestureRecognizer) {
        embeddedDelegate?.panGestureAction(sender)
    }
    
    
    //
    // Send receipt to server for parsing
    //
    func processReceipt(receipt: UIImage) {
        activitySpinner.show(text: "Uploading image")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.activitySpinner.updateText(text: "Parsing receipt")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            var items: [BillItem] = []
            items.append(BillItem(key: nil, name: "++ NOT SHARING ++", price: 0.00, quantity: nil, unitPrice: nil))
            items.append(BillItem(key: nil, name: "24 Hrs Beef Noodle Soup", price: 41.90, quantity: nil, unitPrice: nil))
            items.append(BillItem(key: nil, name: "Coke", price: 2.95, quantity: nil, unitPrice: nil))
            items.append(BillItem(key: nil, name: "Crispy Calamari", price: 14.00, quantity: nil, unitPrice: nil))
            items.append(BillItem(key: nil, name: "Paneng Neua", price: 25.50, quantity: nil, unitPrice: nil))
            self.parsedBill = Bill(key: nil, name: "Farmhouse", author: DefaultOps.currentUser!, completed: false, modifiedDate: Date(), createdDate: Date(), location: nil, items: [], receiptImage: "", tax: nil, tip: nil, subtotal: nil, total: nil, participants: [], group: nil)
            self.parsedBill!.setItems(items: items)
            self.parsedBill!.setTax(tax: 7.17)
            self.parsedBill!.setTip(tip: 0.00)
            self.parsedBill!.location = "San Francisco, CA"
            self.performSegue(withIdentifier: "homeToEditBill", sender: self)
            self.activitySpinner.hide()
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToEditBill" {
            let vc = segue.destination as! editBillScanViewController
            vc.bill = parsedBill
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

}
