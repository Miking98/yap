//
//  Group.swift
//  accountabill
//
//  Created by Xueying Wang on 7/18/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Group: Base {
    var key: String?
    var name: String?
    var author: User?
    var users: [User] = []
    var bills: [Bill] = []
    var createdDate: Date?
    
    init (key: String) {
        super.init()
        self.key = key
    }
    
    init (key: String?, name: String?, author: User?, users: [User] = [], bills: [Bill] = [], createdDate: Date?) {
        super.init()
        self.key = key
        self.name = name
        self.author = author
        self.users = users
        self.bills = bills
        self.createdDate = createdDate
    }
    init(snapshot: DataSnapshot) {
        super.init()
        storeSnapshot(snapshot: snapshot)
    }
    func update(snapshot: DataSnapshot) {
        storeSnapshot(snapshot: snapshot)
    }
    func storeSnapshot(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        key = snapshot.key
        name = snapshotValue["name"] as? String
        createdDate = convertDateFromFirebaseToString(dateString: snapshotValue["createdDate"] as? String)
        let authorKey = snapshotValue["author"] as! String
        author = User(uid: authorKey)
        let userKeys = snapshotValue["users"] as? [String: Any] ?? [:]
        for (key, _) in userKeys {
            let newUser = User(uid: key)
            users.append(newUser)
        }
        let billKeys = snapshotValue["bills"] as? [String: Any] ?? [:]
        for (key, _) in billKeys {
            let newBill = Bill(key: key)
            bills.append(newBill)
        }
    }
    
    
    func serializeUsersForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in users {
            if i.uid != nil {
                serialization[i.uid!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeBillsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in bills {
            if i.key != nil {
                serialization[i.key!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeForFirebase() -> NSDictionary {
        let s_users = serializeUsersForFirebase()
        let s_bills = serializeBillsForFirebase()
        // Need below code format to ensure Swift compiler doesn't take forever
        var serialization: [String: Any] = [:]
        serialization["name"] = name ?? ""
        serialization["author"] = author?.uid
        serialization["users"] = s_users
        serialization["bills"] = s_bills
        serialization["createdDate"] = super.formatDateForFirebase(date: createdDate)
        return serialization as NSDictionary
    }
    
    func createdDatePrint() -> String {
        if createdDate == nil {
            return ""
        }
        return super.formatDateForPrint(date: createdDate!)
    }
    
    static func createKeyOnly(keys: [String]?) -> [Group] {
        if keys == nil {
            return []
        }
        var items: [Group] = []
        for k in keys! {
            let new = Group(key: k)
            items.append(new)
        }
        return items
    }
}
