//
//  FacebookOps.swift
//  accountabill
//
//  Created by Michael Wornow on 7/14/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseAuth
import FacebookCore
import FacebookLogin
import FacebookShare
import SwiftyJSON

struct FacebookGraphSearchUsers: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var users: [User] = []
        var next: String = ""
        
        init(rawResponse: Any?) {
            if rawResponse != nil {
                let parsedJSON = JSON(rawResponse!).dictionaryObject!
                let data = parsedJSON["data"] as! [[String: Any]]
                for d in data {
                    let d_name = d["name"] as? String
                    let newUser = User(uid: nil, name: d_name, email: nil, photoURL: nil)
                    newUser.facebookID = d["id"] as? String
                    users.append(newUser)
                }
                if parsedJSON["paging"] != nil {
                    let paging = parsedJSON["paging"] as! [String: Any]
                    next = paging["next"] as? String ?? ""
                }
            }
        }
    }
    var graphPath = "search"
    var parameters: [String : Any]?
    var accessToken: AccessToken?
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    init(query: String) {
        parameters = [:]
        parameters?["fields"] = "email,name,picture"
        parameters?["q"] = query
        parameters?["type"] = "user"
        // Get Facebook access token
        if let f_token = FirebaseOps.currentUser?.facebookAuthenticationToken {
            accessToken = AccessToken(authenticationToken: f_token)
        }
    }
}
struct FacebookGraphSearchFriends: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var users: [User] = []
        var next: String = ""
        
        init(rawResponse: Any?) {
            if rawResponse != nil {
                let parsedJSON = JSON(rawResponse!).dictionaryObject!
                let data = parsedJSON["data"] as! [[String: Any]]
                for d in data {
                    let d_name = d["name"] as? String
                    let newUser = User(uid: nil, name: d_name, email: nil, photoURL: nil)
                    newUser.facebookID = d["id"] as? String
                    users.append(newUser)
                }
                if parsedJSON["paging"] != nil {
                    let paging = parsedJSON["paging"] as! [String: Any]
                    next = paging["next"] as? String ?? ""
                }
            }
        }
    }
    var userID: String?
    var graphPath = "/friends"
    var parameters: [String : Any]?
    var accessToken: AccessToken?
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    init(query: String) {
        parameters = [:]
        parameters?["fields"] = "email,name,picture"
        parameters?["limit"] = 5000
        // Get Facebook access token
        if let f_token = FirebaseOps.currentUser?.facebookAuthenticationToken {
            accessToken = AccessToken(authenticationToken: f_token)
        }
        if let f_userID = FirebaseOps.currentUser?.facebookID {
            userID = f_userID
            graphPath = userID! + graphPath
        }
    }
}
struct FacebookGraphSearchTaggableFriends: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var users: [User] = []
        var next: String = ""
        
        init(rawResponse: Any?) {
            if rawResponse != nil {
                let parsedJSON = JSON(rawResponse!).dictionaryObject!
                let data = parsedJSON["data"] as! [[String: Any]]
                for d in data {
                    let d_name = d["name"] as? String
                    let d_picture = d["picture"] as! [String:Any]
                    let d_pictureData = d_picture["data"] as! [String: Any]
                    let d_pictureURL = d_pictureData["url"] as? String ?? nil
                    let newUser = User(uid: nil, name: d_name, email: nil, photoURL: d_pictureURL)
                    newUser.facebookTaggableID = d["id"] as? String
                    users.append(newUser)
                }
                if parsedJSON["paging"] != nil {
                    let paging = parsedJSON["paging"] as! [String: Any]
                    next = paging["next"] as? String ?? ""
                }
            }
        }
    }
    var userID: String?
    var graphPath = "/taggable_friends"
    var parameters: [String : Any]?
    var accessToken: AccessToken?
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    init(query: String) {
        parameters = [:]
        parameters?["fields"] = "name,picture"
        parameters?["limit"] = 5000
        // Get Facebook access token
        if let f_token = FirebaseOps.currentUser?.facebookAuthenticationToken {
            accessToken = AccessToken(authenticationToken: f_token)
        }
        if let f_userID = FirebaseOps.currentUser?.facebookID {
            userID = f_userID
            graphPath = userID! + graphPath
        }
    }
}

class FacebookOps {
    
    static func userLogin(completion: @escaping (_ success: Bool) -> Void) {
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn([ .publicProfile, .email, .userFriends ]) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
                completion(false)
            case .cancelled:
                print("User cancelled login")
                completion(false)
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged into Facebook")
                print(grantedPermissions)
                print(declinedPermissions)
                // Save Facebook info in cookies
                let defaults = UserDefaults.standard
                defaults.set(accessToken.authenticationToken, forKey: "facebookAuthenticationToken")
                defaults.set(accessToken.userId, forKey: "facebookUserID")
                let credential =  FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                // Firebase authentication
                FirebaseOps.userLogin(credential: credential, completion: completion)
            }
        }
    }
    
    static func searchFriends(query: String, completion: @escaping (_ success: Bool, _ users: [User]?, _ next: String?) -> Void) {
        let request = FacebookGraphSearchTaggableFriends(query: query)
        request.start { (urlResponse, result) in
            switch result {
            case .success(let graphResponse):
                print("Facebook users search succeeded")
                completion(true, graphResponse.users, graphResponse.next)
            case .failed(let error):
                print("Facebook users search failed")
                print(error)
                completion(false, nil, nil)
            }
        }
    }
    
    static func searchAll(query: String, completion: @escaping (_ success: Bool, _ users: [User]?, _ next: String?) -> Void) {
        let request = FacebookGraphSearchUsers(query: query)
        request.start { (urlResponse, result) in
            switch result {
                case .success(let graphResponse):
                    print("Facebook users search succeeded")
                    completion(true, graphResponse.users, graphResponse.next)
                case .failed(let error):
                    print("Facebook users search failed")
                    print(error)
                    completion(false, nil, nil)
            }
        }
    }
}
