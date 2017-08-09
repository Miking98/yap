//
//  initialGifViewController.swift
//  accountabill
//
//  Created by Tiffany Madruga on 7/31/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import Gifu

class initialGifViewController: UIViewController {

    @IBOutlet weak var initialGifImageView: GIFImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Checkmark GIF
        initialGifImageView.animate(withGIFNamed: "yap_gif")
        
        // Segue to Home screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.performSegue(withIdentifier: "initialSegue", sender: self)
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

