//
//  profileViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/28/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class profileViewController: UIViewController, EmbeddedViewControllerReceiver {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var embeddedDelegate: EmbeddedViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = DefaultOps.currentUser!
        usernameLabel.text = currentUser.name!
        profileImageView.image = DefaultOps.pictures(user: currentUser)
    }
    
    //
    // Pan gesture
    //
    @IBAction func profilePanGestureAction(_ sender: UIPanGestureRecognizer) {
        embeddedDelegate?.panGestureAction(sender)
    }
    
    @IBAction func logoutButtonTouch(_ sender: Any) {
        DefaultOps.userLogout { (success: Bool) in
            if success {
                print("Logged out successfully")
                // Send user to Splash page
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = mainStoryboard.instantiateViewController(withIdentifier: "splashViewController")
                UIApplication.shared.keyWindow?.rootViewController = vc
            }
            else {
                print("Error logging user out")
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
