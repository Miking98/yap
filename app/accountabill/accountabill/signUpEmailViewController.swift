//
//  signUpEmailViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/14/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class signUpEmailViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func facebookLoginButtonTouch(_ sender: Any) {
        FacebookOps.userLogin(completion: { (success: Bool) -> Void in
            if (success) {
                self.performSegue(withIdentifier: "signUpEmailToSignUpLinkPayments", sender: nil)
            }
            else {
                print("Error logging user into Facebook.")
            }
        })
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
