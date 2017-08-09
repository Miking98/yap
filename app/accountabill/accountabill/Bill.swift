//
//  Bill.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseDatabase
import SwiftyJSON
import CoreLocation

class Bill: Base {
    var key: String?
    var ref: DatabaseReference?
    var name: String?
    var author: User?
    var completed: Bool?
    var modifiedDate: Date?
    var createdDate: Date?
    var location: String?
    var subtotal: Double?
    var tax: Double?
    var tip: Double?
    var total: Double?
    var receiptImage: String? // URL to AWS S3 bucket TODO
    var items: [BillItem] = []
    var participants: [User] = []
    var group: Group?
    var paid: Bool = false
    
    init (key: String) {
        super.init()
        self.key = key
    }
    
    init(key: String?, name: String?, author: User?, completed: Bool?, modifiedDate: Date?, createdDate: Date?, location: String?,
         items: [BillItem] = [], receiptImage: String?, tax: Double?, tip: Double?, subtotal: Double?, total: Double?,
         participants: [User] = [], group: Group?) {
        super.init()
        self.key = key
        self.name = name
        self.author = author
        self.completed = completed
        self.modifiedDate = modifiedDate
        self.createdDate = createdDate
        self.location = location
        self.items = items
        self.receiptImage = receiptImage
        self.tax = tax
        self.tip = tip
        self.subtotal = subtotal
        self.total = total
        self.participants = participants
        self.group = group
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
        let authorKey = snapshotValue["author"] as? String
        author = authorKey != nil ? User(uid: authorKey!) : nil
        modifiedDate = convertDateFromFirebaseToString(dateString: snapshotValue["modifiedDate"] as? String)
        createdDate = convertDateFromFirebaseToString(dateString: snapshotValue["createdDate"] as? String)
        location = snapshotValue["location"] as? String
        let itemKeys = snapshotValue["items"] as? [String:Any] ?? [:]
        for (key, _) in itemKeys {
            let newItem = BillItem(key: key)
            items.append(newItem)
        }
        receiptImage = snapshotValue["receiptImage"] as? String
        tax = snapshotValue["tax"] as? Double
        tip = snapshotValue["tip"] as? Double
        subtotal = snapshotValue["subtotal"] as? Double
        total = snapshotValue["total"] as? Double
        completed = snapshotValue["completed"] as? Bool
        let participantKeys = snapshotValue["participants"] as? [String:Any] ?? [:]
        for (key, _) in participantKeys {
            let newParticipant = User(uid: key)
            participants.append(newParticipant)
        }
        let groupKey = snapshotValue["group"] as? String
        if groupKey != nil && groupKey != "" {
            let newGroup = Group(key: groupKey!)
            group = newGroup
        }
    }
    
    init(parsedJSON: JSON) {
        let billDict: [String: Any] = parsedJSON["bill"].dictionaryObject!
        self.name = billDict["name"] as? String
        self.subtotal = billDict["subtotal"] as? Double
        self.tax = billDict["tax"] as? Double
        self.tip = billDict["tip"] as? Double
        self.total = billDict["total"] as? Double
        let items = billDict["items"] as! [[String: Any]]
        for i in items {
            let name = i["name"] as? String
            let price = i["price"] as? Double
            let quantity = i["quantity"] as? Int
            let unitPrice = i["unitPrice"] as? Double
            let newBillItem = BillItem(key: nil, name: name, price: price, quantity: quantity, unitPrice: unitPrice)
            self.items.append(newBillItem)
        }
    }
    
    func setAuthor(user: User) {
        author = user
        participants.append(user)
    }
    func setTax(tax newTax: Double) {
        let diff = newTax - (tax ?? 0)
        tax = newTax
        addToTotal(diff: diff)
    }
    func setTip(tip newTip: Double) {
        let diff = newTip - (tip ?? 0)
        tip = newTip
        addToTotal(diff: diff)
    }
    func setItems(items newItems: [BillItem]) {
        items = []
        for i in newItems {
            items.append(i)
            addToSubtotal(diff: i.price ?? 0)
        }
    }
    func editItemPrice(oldItemIndex: Int, newPrice: Double) {
        let oldItem = items[oldItemIndex]
        if oldItem.price != newPrice {
            let diff = newPrice - (oldItem.price ?? 0)
            oldItem.price = newPrice
            addToSubtotal(diff: diff)
        }
    }
    func addItem(item: BillItem) {
        if let price = item.price {
            addToSubtotal(diff: price)
        }
        items.append(item)
    }
    func removeItem(itemIndex: Int) {
        let price = -(items[itemIndex].price ?? 0)
        addToSubtotal(diff: price)
        items.remove(at: itemIndex)
    }
    func addToSubtotal(diff: Double) {
        subtotal = subtotal != nil ? subtotal! + diff : diff
        addToTotal(diff: diff)
    }
    func addToTotal(diff: Double) {
        total = total != nil ? total! + diff : diff
    }
    func setParticipants(participants newParticipants: [User]) {
        participants = newParticipants
        // Enforce that only current participants are added to Bill Items (remove any old participants who didn't make the new participant cut)
        for item in items {
            for itemParticipant in item.participants {
                var keepParticipant = false
                for newParticipant in participants {
                    if User.checkSameUser(user1: itemParticipant, user2: newParticipant) {
                        keepParticipant = true
                    }
                }
                if !keepParticipant {
                    item.removeParticipant(user: itemParticipant)
                }
            }
        }
    }
    func rationalizeTotals() {
        // Re-align subtotal and total to reflect sum of item prices
        subtotal = 0
        for i in items {
            subtotal! += i.price ?? 0
        }
        total = subtotal! + (tax ?? 0) + (tip ?? 0)
    }
    
    func serializeParticipantsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for p in participants {
            if p.uid != nil {
                // Calculate amount this person owes
                var amount: Double = 0
                for i in items {
                    var pIsInThisItem = false
                    for ip in i.participants {
                        if User.checkSameUser(user1: p, user2: ip) {
                            pIsInThisItem = true
                            break
                        }
                    }
                    if pIsInThisItem {
                        amount += i.pricePerUser ?? 0
                    }
                }
                // Add tax and tip
                let denominator: Double = (subtotal ?? Double(INT_MAX))
                let tipAmt: Double = tip ?? 0
                let taxAmt: Double = tax ?? 0
                amount += (amount/denominator) * tipAmt + (amount/denominator) * taxAmt
                // Set author of bill to have already paid
                var paidStatus = false
                if author != nil {
                    if User.checkSameUser(user1: p, user2: author!) {
                        paidStatus = true
                    }
                }
                serialization[p.uid!] = [ "paid" : paidStatus, "amount" : amount, "timeTaken" : 0 ]
            }
        }
        return serialization as NSDictionary
    }
    func serializeBillItemsForFirebase() -> NSDictionary {
        var serialization: [String: Any] = [:]
        for i in items {
            if i.key != nil {
                serialization[i.key!] = true
            }
        }
        return serialization as NSDictionary
    }
    
    
    func serializeForFirebase() -> NSDictionary {
        let s_items = serializeBillItemsForFirebase()
        let s_participants = serializeParticipantsForFirebase()
        let s_createdDate = super.formatDateForFirebase(date: createdDate)
        let s_modifiedDate = super.formatDateForFirebase(date: modifiedDate)
        // Need below code format to ensure Swift compiler doesn't take forever
        var serialization: [String: Any] = [:]
        serialization["name"] = name ?? ""
        serialization["author"] = author?.uid ?? ""
        serialization["modifiedDate"] = s_modifiedDate
        serialization["createdDate"] = s_createdDate
        serialization["location"] = location ?? ""
        serialization["items"] = s_items
        serialization["receiptImage"] = receiptImage ?? ""
        serialization["tax"] = tax ?? 0
        serialization["tip"] = tip ?? 0
        serialization["subtotal"] = subtotal ?? 0
        serialization["total"] = total ?? 0
        serialization["completed"] = completed ?? false
        serialization["participants"] = s_participants
        serialization["group"] = group?.key ?? ""
        return serialization as NSDictionary
    }
    
    // Print formatting
    func locationPrint() -> String {
        if location == nil {
            return "Awesometown, USA"
        }
        return location!
    }
    func createdDatePrint() -> String {
        if createdDate == nil {
            return ""
        }
        return super.formatDateForPrint(date: createdDate!)
    }
    func modifiedDatePrint() -> String {
        if modifiedDate == nil {
            return ""
        }
        return super.formatDateForPrint(date: modifiedDate!)
    }
    
    static func createKeyOnly(keys: [String]?) -> [Bill] {
        if keys == nil {
            return []
        }
        var items: [Bill] = []
        for k in keys! {
            let new = Bill(key: k)
            items.append(new)
        }
        return items
    }
    
    
}
    

