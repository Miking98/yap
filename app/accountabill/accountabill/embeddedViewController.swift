//
//  embeddedViewController.swift
//  accountabill
//
//  Created by Michael Wornow 7/15/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

protocol EmbeddedViewControllerDelegate: class {
    
    // delegate to provide information about other containers
    func isContainerActive(_ position: SwipePosition) -> Bool
    
    // delegate to handle containers events
    func onDone(_ sender: Any)
    func onShowContainer(_ position: SwipePosition, sender: Any)
    func panGestureAction(_ sender: UIPanGestureRecognizer)
}

protocol EmbeddedViewControllerReceiver: class {
    var embeddedDelegate: EmbeddedViewControllerDelegate? { get set }
}
