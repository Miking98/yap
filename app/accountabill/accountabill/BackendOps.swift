//
//  DefaultOps.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON

// For interacting with Python server on Heroku
class BackendOps {
    
    static let baseURL = "https://accountabillbackend.herokuapp.com/"
    static let APIKey = "21da54f1-7f14-4847-b093-a2420007b34d"
    
    // Input: UIImage of receipt
    // Returns: Array of BillItems parsed from receipt
    static func getReceiptItems(receipt: UIImage, activitySpinner: ActivitySpinnerView, completion:  @escaping (_ success: Bool, _ bill: Bill?) -> Void)  {
        activitySpinner.show(text: "Uploading image")
        
        // Construct request
        let URLString = baseURL + "getReceiptItems"
        let parameters = ["APIKey" : APIKey ]
        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imageData = UIImagePNGRepresentation(receipt) {
                multipartFormData.append(imageData, withName: "receipt", fileName: "receipt.png", mimeType: "image/png")
            }
            for (key, value) in parameters {
                multipartFormData.append((value.data(using: .utf8))!, withName: key)
            }}, to: URLString, method: .post,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                        case .success(let upload, _, _):
                            activitySpinner.updateText(text: "Parsing receipt")
                            print("Success encoding receipt")
                            upload.responseJSON { response in
                                print(response)
                                switch response.result {
                                    case .success(let value):
                                        let jsonResponse = JSON(value)
                                        print("Successful server response")
                                        let error = jsonResponse["error"].intValue
                                        if error == 0 {
                                            let bill = Bill(parsedJSON: jsonResponse)
                                            completion(true, bill)
                                        }
                                        else {
                                            print("Server side error")
                                            completion(false, nil)
                                        }
                                    case .failure(let error):
                                        print("Error with server response")
                                        print(error)
                                        completion(false, nil)
                                }
                            }
                        case .failure(let encodingError):
                            print("Error encoding receipt")
                            print(encodingError)
                            completion(false, nil)
                    }
                }
        )
        
    }

}
