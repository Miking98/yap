//
//  splashViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/14/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class splashViewController: UIViewController {
    
    
    @IBOutlet weak var yapTitle: UILabel!
    @IBOutlet weak var sharebillsTagLine: UILabel!
    @IBOutlet weak var loginFacebookButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var stopPaying: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        yapTitle.shadowColor = UIColor(red: 0, green: 135.0/255.0, blue: 182.0/255.0, alpha: 1.0)
        yapTitle.layer.shadowOffset = CGSize(width: 4, height: 4)
        yapTitle.layer.shadowOpacity = 0.5
    
        
        //sharebills tagline
        sharebillsTagLine.layer.masksToBounds = false
        sharebillsTagLine.shadowColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        sharebillsTagLine.shadowOffset = CGSize(width: 1 , height: 0)
        sharebillsTagLine.layer.shadowOpacity = 0.5
        sharebillsTagLine.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        //stopPaying tagline
        stopPaying.layer.masksToBounds = false
        stopPaying.shadowColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        stopPaying.shadowOffset = CGSize(width: 1 , height: 0)
        stopPaying.layer.shadowOpacity = 0.5
        stopPaying.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        
        
        
        
    
        //facebook button formatting
        loginFacebookButton.layer.cornerRadius = 10
        loginFacebookButton.layer.shadowColor = UIColor.black.cgColor
        loginFacebookButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        loginFacebookButton.layer.shadowRadius = 4
        loginFacebookButton.layer.shadowOpacity = 0.2
        loginFacebookButton.layer.masksToBounds =  false
        loginFacebookButton.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8).cgColor
        loginFacebookButton.layer.borderWidth = 1
        
        //email button formatting
        emailButton.layer.cornerRadius = 10
        emailButton.layer.shadowColor = UIColor.black.cgColor
        emailButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        emailButton.layer.shadowRadius = 3
        emailButton.layer.shadowOpacity = 0.5
        emailButton.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
        emailButton.layer.borderWidth = 1
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func facebookLoginButtonTouch(_ sender: Any) {
        FacebookOps.userLogin(completion: { (success: Bool) -> Void in
            if (success) {
                self.performSegue(withIdentifier: "splashToSignUpLinkPayments", sender: nil)
            }
            else {
                print("Error logging user into Facebook.")
            }
        })
    }
    
    
}
