//
//  ActivitySpinnerView.swift
//  accountabill
//
//  Created by Michael Wornow on 7/19/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit

class ActivitySpinnerView: UIVisualEffectView {
        
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    let label: UILabel = UILabel()
    let blurEffect = UIBlurEffect(style: .light)
    let vibrancyView: UIVisualEffectView
    
    init() {
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(effect: blurEffect)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        contentView.addSubview(vibrancyView)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(label)
        self.hide()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = self.superview {
            
            let width: CGFloat = 200
            let height: CGFloat = 50.0
            self.frame = CGRect(x: superview.frame.size.width / 2 - width / 2,
                                y: superview.frame.height / 2 - height / 2,
                                width: width,
                                height: height)
            vibrancyView.frame = self.bounds
            
            let activityIndicatorSize: CGFloat = 40
            activityIndicator.frame = CGRect(x: 5,
                                            y: height / 2 - activityIndicatorSize / 2,
                                            width: activityIndicatorSize,
                                            height: activityIndicatorSize)
            
            layer.cornerRadius = 8.0
            layer.masksToBounds = true
            label.text = text
            label.textAlignment = NSTextAlignment.center
            label.frame = CGRect(x: activityIndicatorSize + 5,
                                 y: 0,
                                 width: width - activityIndicatorSize - 15,
                                 height: height)
            label.textColor = UIColor.black
            label.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
    
    func show(text: String?) {
        self.text = text
        activityIndicator.startAnimating()
        self.isHidden = false
    }
    
    func updateText(text: String?) {
        self.text = text
    }
    
    func hide() {
        self.isHidden = true
    }

}
