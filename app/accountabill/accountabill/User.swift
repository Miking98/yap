//
//  User.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseDatabase

class User: Base {
    var uid: String?
    var facebookID: String?
    var facebookTaggableID: String?
    var facebookAuthenticationToken: String?
    var name: String?
    var email: String?
    var photoURL: String?
    var heroBills: [Bill] = []
    var moocherBills: [Bill] = []
    var groups: [Group] = []
    
    init (uid: String) {
        super.init()
        self.uid = uid
    }
    
    init (uid: String?, name: String?, email: String?, photoURL: String?, heroBills: [Bill] = [], moocherBills: [Bill] = [], groups: [Group] = []) {
        super.init()
        self.uid = uid
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.heroBills = heroBills
        self.moocherBills = moocherBills
        self.groups = groups
    }
    
    init(snapshot: DataSnapshot) {
        super.init()
        storeSnapshot(snapshot: snapshot)
    }
    func update(snapshot: DataSnapshot) {
        storeSnapshot(snapshot: snapshot)
    }
    func storeSnapshot(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        uid = snapshot.key
        name = snapshotValue["name"] as? String
        email = snapshotValue["email"] as? String
        photoURL = snapshotValue["photoURL"] as? String
        let heroKeys = snapshotValue["herobills"] as? [String: Any] ?? [:]
        for (key, _) in heroKeys {
            let newBill = Bill(key: key)
            heroBills.append(newBill)
        }
        let moocherKeys = snapshotValue["moocherbills"] as? [String: Any] ?? [:]
        for (key, _) in moocherKeys {
            let newBill = Bill(key: key)
            moocherBills.append(newBill)
        }
        let groupKeys = snapshotValue["groups"] as? [String: Any] ?? [:]
        for (key, _) in groupKeys {
            let newGroup = Group(key: key)
            groups.append(newGroup)
        }
    }
    
    func serializeHeroBillsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in heroBills {
            if i.key != nil {
                serialization[i.key!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeMoocherBillsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in moocherBills {
            if i.key != nil {
                serialization[i.key!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeGroupsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in groups {
            if i.key != nil {
                serialization[i.key!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeForFirebase() -> NSDictionary {
        let s_heroBills = serializeHeroBillsForFirebase()
        let s_moocherBills = serializeMoocherBillsForFirebase()
        let s_groups = serializeGroupsForFirebase()
        // Need below code format to ensure Swift compiler doesn't take forever
        var serialization: [String: Any] = [:]
        serialization["uid"] = uid ?? ""
        serialization["name"] = name ?? ""
        serialization["email"] = email ?? ""
        serialization["photoURL"] = photoURL ?? ""
        serialization["heroKeys"] = s_heroBills
        serialization["moocherKeys"] = s_moocherBills
        serialization["groupKeys"] = s_groups
        return serialization as NSDictionary
    }
    
    
    static func createKeyOnly(keys: [String]?) -> [User] {
        if keys == nil {
            return []
        }
        var items: [User] = []
        for k in keys! {
            let new = User(uid: k)
            items.append(new)
        }
        return items
    }
    
    static func checkSameUser(user1: User, user2: User) -> Bool {
        // 1. Check Accountabill ID
        if user1.uid != nil && user2.uid != nil {
            if user1.uid! == user2.uid! {
                return true
            }
        }
        // 2. Check Facebook ID (if user has authorized app)
        if user1.facebookID != nil && user2.facebookID != nil {
            if user1.facebookID! == user2.facebookID! {
                return true
            }
        }
        // 3. Check Facebook Taggable ID (if user hasn't authorized app)
        if user1.facebookTaggableID != nil && user2.facebookTaggableID != nil {
            if user1.facebookTaggableID! == user2.facebookTaggableID! {
                return true
            }
        }
        return false
    }
}
