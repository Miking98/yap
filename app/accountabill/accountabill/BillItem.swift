//
//  BillItem.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseDatabase

class BillItem: Base {
    var key: String?
    var name: String?
    var price: Double?
    var pricePerUser: Double?
    var quantity: Int?
    var unitPrice: Double?
    var participants: [User] = []
    var userPrice: Double?
    
    init (key: String) {
        super.init()
        self.key = key
    }
    
    init(key: String?, name: String?, price: Double?, quantity: Int?, unitPrice: Double?) {
        super.init()
        self.key = key
        self.name = name
        self.price = price
        self.pricePerUser = price
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
    
    init(key: String?, name: String?, price: Double?, quantity: Int?, unitPrice: Double?, participants: [User]) {
        super.init()
        self.key = key
        self.name = name
        self.price = price
        self.pricePerUser = price
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.setParticipants(participants: participants)
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
        key = snapshot.key
        name = snapshotValue["name"] as? String
        price = snapshotValue["price"] as? Double
        quantity = snapshotValue["quantity"] as? Int
        unitPrice = snapshotValue["unitPrice"] as? Double
        let participantKeys = snapshotValue["participants"] as? [String: Any] ?? [:]
        participants = []
        for (key, _) in participantKeys {
            let newParticipant = User(uid: key)
            participants.append(newParticipant)
        }
        userPrice = price!/Double(participants.count)
    }
    
    func hasParticipant(user: User) -> Bool {
        for p in participants {
            if User.checkSameUser(user1: user, user2: p) {
                return true
            }
        }
        return false
    }
    func setParticipants(participants newParticipants: [User]) {
        participants = []
        for p in newParticipants {
            addParticipant(user: p)
        }
    }
    func addParticipant(user: User) {
        participants.append(user)
        resetPerPersonPrice()
    }
    func removeParticipant(user: User) {
        for i in 0..<participants.count {
            if User.checkSameUser(user1: user, user2: participants[i]) {
                participants.remove(at: i)
                resetPerPersonPrice()
                return
            }
        }
    }
    func resetPerPersonPrice() {
        if price != nil {
            pricePerUser = participants.count > 0 ? price!/Double(participants.count) : price!
        }
    }
    
    func serializeParticipantsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in participants {
            if i.uid != nil {
                serialization[i.uid!] = true
            }
        }
        return serialization as NSDictionary
    }
    func serializeForFirebase() -> NSDictionary {
        let s_participants = serializeParticipantsForFirebase()
        // Need below code format to ensure Swift compiler doesn't take forever
        var serialization: [String: Any] = [:]
        serialization["name"] = name ?? ""
        serialization["price"] = price ?? ""
        serialization["quantity"] = quantity ?? ""
        serialization["unitPrice"] = unitPrice ?? ""
        serialization["participants"] = s_participants
        return serialization as NSDictionary
    }
    
    static func createKeyOnly(keys: [String]?) -> [BillItem] {
        if keys == nil {
            return []
        }
        var items: [BillItem] = []
        for k in keys! {
            let new = BillItem(key: k)
            items.append(new)
        }
        return items
    }
}
