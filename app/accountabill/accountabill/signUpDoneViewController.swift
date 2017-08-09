//
//  signUpDoneViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/16/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import Gifu

class signUpDoneViewController: UIViewController {

    @IBOutlet weak var checkmarkGIFImageView: GIFImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Checkmark GIF
        checkmarkGIFImageView.animate(withGIFNamed: "checkmark_gif")
        
        // Segue to Home screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            self.performSegue(withIdentifier: "signUpDoneToHome", sender: self)
        }
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
