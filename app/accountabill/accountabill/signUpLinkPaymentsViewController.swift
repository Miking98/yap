//
//  signUpLinkPaymentsViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/15/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class signUpLinkPaymentsViewController: UIViewController {
    
    @IBOutlet weak var payPal: UIButton!
    @IBOutlet weak var venmo: UIButton!
    @IBOutlet weak var applePay: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //paypal button formatting
        payPal.layer.cornerRadius = 10
        payPal.layer.shadowColor = UIColor.black.cgColor
        payPal.layer.shadowOffset = CGSize(width: 0, height: 2)
        payPal.layer.shadowRadius = 4
        payPal.layer.shadowOpacity = 0.2
        payPal.layer.masksToBounds =  false
        payPal.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8).cgColor
        payPal.layer.borderWidth = 1
        
        //venmo button formatting
        venmo.layer.cornerRadius = 10
        venmo.layer.shadowColor = UIColor.black.cgColor
        venmo.layer.shadowOffset = CGSize(width: 0, height: 2)
        venmo.layer.shadowRadius = 4
        venmo.layer.shadowOpacity = 0.2
        venmo.layer.masksToBounds =  false
        venmo.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8).cgColor
        venmo.layer.borderWidth = 1
        
        //applePay button formatting
        applePay.layer.cornerRadius = 10
        applePay.layer.shadowColor = UIColor.black.cgColor
        applePay.layer.shadowOffset = CGSize(width: 0, height: 2)
        applePay.layer.shadowRadius = 4
        applePay.layer.shadowOpacity = 0.2
        applePay.layer.masksToBounds =  false
        applePay.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8).cgColor
        applePay.layer.borderWidth = 1
        
        
        //doneButton
        doneButton.layer.cornerRadius = 10
        doneButton.layer.shadowColor = UIColor.black.cgColor
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        doneButton.layer.shadowRadius = 4
        doneButton.layer.shadowOpacity = 0.2
        doneButton.layer.masksToBounds =  false
        doneButton.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8).cgColor
        doneButton.layer.borderWidth = 1
        
        
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
