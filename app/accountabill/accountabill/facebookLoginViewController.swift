//
//  facebookLoginViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 8/7/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

protocol FacebookLoginDelegate {
    func onDismiss()
}

class facebookLoginViewController: UIViewController {
    
    @IBOutlet weak var firstLoadingView: UIView!
    
    var delegate: FacebookLoginDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.firstLoadingView.frame.size.width = self.firstLoadingView.frame.width * 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.firstLoadingView.isHidden = true
            }
        }
    }
    
    @IBAction func loginButton(_ sender: Any) {
        dismiss(animated: true) {
            self.delegate?.onDismiss()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
