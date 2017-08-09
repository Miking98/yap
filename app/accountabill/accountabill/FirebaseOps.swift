//
//  FirebaseOps.swift
//  accountabill
//
//  Created by Michael Wornow on 7/17/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class FirebaseOps {
    
    static var shared: FirebaseOps = FirebaseOps()
    static var ref = Database.database().reference()
    static var currentUser: User?
    
    static func userLoggedIn() -> Bool {
        if Auth.auth().currentUser != nil {
            return FirebaseOps.setCurrentUser()
        }
        return false
    }
    
    static func userLogin(credential: AuthCredential, completion: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signIn(with: credential) { (authUser, error) in
            if let error = error {
                print(error)
                completion(false)
            }
            else if let authUser = authUser {
                print("Logged into Firebase")
                // Check if user already exists
                FirebaseOps.ref.child("user").child(authUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    let userAlreadyExists = !(snapshot.value == nil)
                    if userAlreadyExists {
                        print("User already exists")
                        completion(FirebaseOps.setCurrentUser())
                    }
                    else {
                        print("User doesn't already exist")
                        // Create user in Firebase database
                        let newUser = User(uid: authUser.uid)
                        newUser.name = authUser.displayName
                        newUser.email = authUser.email
                        newUser.photoURL = authUser.photoURL?.absoluteString
                        authUser.providerData.forEach({ (profile) in
                            // Facebook
                            if profile.providerID == "facebook.com" {
                                newUser.facebookID = profile.uid
                            }
                        })
                        FirebaseOps.createUser(user: newUser, completion: { (error: Error?, updatedUser: User?) in
                            if let error = error {
                                print("Error creating user in database")
                                print(error)
                                completion(false)
                            }
                            else {
                                completion(FirebaseOps.setCurrentUser())
                            }
                        })
                        
                    }
                })
            }
            else {
                completion(false)
            }
        }
    }
    
    static func userLogout(completion: @escaping (_ success: Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            // Nullify current user object
            FirebaseOps.currentUser = nil
            // Reset cookies
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "facebookAuthenticationToken")
            defaults.removeObject(forKey: "facebookUserID")
            print("Logged out of Firebase")
            completion(true)
        }
        catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            completion(false)
        }
    }
    
    static func setCurrentUser() -> Bool {
        if let authUser = Auth.auth().currentUser {
            let uid = authUser.uid
            FirebaseOps.currentUser = User(uid: uid)
            FirebaseOps.currentUser?.email = authUser.email
            FirebaseOps.currentUser?.name = authUser.displayName
            FirebaseOps.currentUser?.photoURL = authUser.photoURL?.absoluteString
            // Get cookies
            let defaults = UserDefaults.standard
            if let f_userID = defaults.string(forKey: "facebookUserID") {
                FirebaseOps.currentUser?.facebookID = f_userID
            }
            if let f_token = defaults.string(forKey: "facebookAuthenticationToken") {
                FirebaseOps.currentUser?.facebookAuthenticationToken = f_token
            }
            return true
        }
        else {
            return false
        }
    }
    
    static func createUser(user: User, completion: @escaping (_ error: Error?, _ newUser: User?) -> Void) {
        let serialization = user.serializeForFirebase()
        FirebaseOps.ref.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error creating user "+user.name!)
                completion(error, nil)
            }
            else {
                print("Successfully created user "+user.name!)
                user.uid = dbRef.key
                completion(nil, user)
            }
        })
    }
    
    static func createBill(bill: Bill, completion: @escaping (_ error: Error?, _ newBill: Bill?) -> Void) {
        // 1. Create bill items
        print("Creating bill...")
        for i in 0 ..< bill.items.count {
            createBillItem(item: bill.items[i], completion: { (error: Error?, t: BillItem?) in
                if i == bill.items.count-1 {
                    // 2. Create actual bill
                    let reference  = FirebaseOps.ref.child("bill").childByAutoId()
                    let serialization = bill.serializeForFirebase()
                    reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
                        if let error = error {
                            print("Error creating bill "+bill.name!)
                            print(error.localizedDescription)
                            completion(error, nil)
                        }
                        else {
                            print("Successfully created bill "+bill.name!)
                            bill.key = dbRef.key
                            if bill.participants.count == 0 {
                                completion(nil, bill)
                            }
                            else {
                                // Add this bill to each participant's node in Firebase
                                for j in 0 ..< bill.participants.count {
                                    let user = bill.participants[j]
                                    if user.uid == nil {
                                        continue
                                    }
                                    if User.checkSameUser(user1: user, user2: bill.author!) {
                                        FirebaseOps.addHeroBillToUser(bill: bill, user: user, completion: { (error: Error?) in
                                            if let error = error {
                                                print("Error adding user "+user.name!+" as hero to bill")
                                                print(error.localizedDescription)
                                                completion(error, nil)
                                            }
                                            if j == bill.participants.count-1 {
                                                if bill.group != nil {
                                                    FirebaseOps.addBillToGroup(bill: bill, group: bill.group!, completion: { (error: Error?) in
                                                        if let error = error {
                                                            print(error)
                                                            completion(error, nil)
                                                        }
                                                        else {
                                                            completion(nil, bill)
                                                        }
                                                    })
                                                }
                                                else {
                                                    completion(nil, bill)
                                                }
                                            }
                                        })
                                    }
                                    else {
                                        FirebaseOps.addMoocherBillToUser(bill: bill, user: user, completion: { (error: Error?) in
                                            if let error = error {
                                                print("Error adding user "+user.name!+" as moocher to bill")
                                                print(error.localizedDescription)
                                                completion(error, nil)
                                            }
                                            if j == bill.participants.count-1 {
                                                if bill.group != nil {
                                                    FirebaseOps.addBillToGroup(bill: bill, group: bill.group!, completion: { (error: Error?) in
                                                        if let error = error {
                                                            print(error)
                                                            completion(error, nil)
                                                        }
                                                        else {
                                                            completion(nil, bill)
                                                        }
                                                    })
                                                }
                                                else {
                                                    completion(nil, bill)
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    static func addHeroBillToUser(bill: Bill, user: User, completion: @escaping (_ error: Error?) -> Void) {
        let reference = FirebaseOps.ref.child("user").child(user.uid!).child("herobills").child(bill.key!)
        let serialization: Bool = true
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error linking user "+user.name!+" to bill "+bill.name!)
                completion(error)
            }
            else {
                print("Successfully linked user and bill")
                completion(nil)
            }
        })
    }
    static func addMoocherBillToUser(bill: Bill, user: User, completion: @escaping (_ error: Error?) -> Void) {
        let reference = FirebaseOps.ref.child("user").child(user.uid!).child("moocherbills").child(bill.key!)
        let serialization: Bool = true
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error linking user "+user.name!+" to bill "+bill.name!)
                completion(error)
            }
            else {
                print("Successfully linked user and bill")
                completion(nil)
            }
        })
    }
    static func addBillToGroup(bill: Bill, group: Group, completion: @escaping (_ error: Error?) -> Void) {
        let reference = FirebaseOps.ref.child("group").child(group.key!).child("bills").child(bill.key!)
        let serialization: Bool = false
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error linking group "+group.name!+" to bill "+bill.name!)
                completion(error)
            }
            else {
                print("Successfully linked group and bill")
                completion(nil)
            }
        })
    }
    
    static func createGroup(group: Group, completion: @escaping (_ error: Error?, _ newGroup: Group?) -> Void) {
        let reference  = FirebaseOps.ref.child("group").childByAutoId()
        let serialization = group.serializeForFirebase()
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error creating group "+group.name!)
                completion(error, nil)
            }
            else {
                print("Successfully created group "+group.name!)
                group.key = dbRef.key
                if group.users.count == 0 {
                    completion(nil, group)
                }
                else {
                    // Add this group to each user in the group
                    var i = 0
                    var groupUsersCount = group.users.count
                    while i<groupUsersCount {
                        FirebaseOps.addGroupToUser(group: group, user: group.users[i], completion: { (error: Error?) in
                            if let error = error {
                                group.users.remove(at: i)
                                groupUsersCount -= 1
                                print("Error adding user "+group.users[i].name!+" to group")
                                print(error)
                            }
                            if i == groupUsersCount-1 {
                                completion(nil, group)
                            }
                        })
                        i += 1
                    }
                }
            }
        })
    }
    
    static func addGroupToUser(group: Group, user: User, completion: @escaping (_ error: Error?) -> Void) {
        let reference = FirebaseOps.ref.child("user").child(user.uid!).child("groups").child(group.key!)
        let serialization: Bool = true
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error linking user "+user.name!+" to group "+group.name!)
                completion(error)
            }
            else {
                print("Successfully linked user and group")
                completion(nil)
            }
        })
    }
    
    static func createBillItem(item: BillItem, completion: @escaping (_ error: Error?, _ newBillItem: BillItem?) -> Void) {
        let reference  = FirebaseOps.ref.child("item").childByAutoId()
        let serialization = item.serializeForFirebase()
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error creating BillItem "+item.name!)
                completion(error, nil)
            }
            else {
                print("Successfully created BillItem "+item.name!)
                item.key = dbRef.key
                completion(nil, item)
            }
        })
    }
    
    static func sendBill(bill: Bill, completion: @escaping (_ error: Error?) -> Void) {
        completion(nil)
    }
    
    static func searchUsers(query: String, completion: @escaping ([User]?, Error?) -> Void) {
        let reference = FirebaseOps.ref.child("user")
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            var users: [User] = []
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? DataSnapshot {
                let newUser = User(snapshot: data)
                users.append(newUser)
            }
            completion(users, nil)
        }) { (error) in
            print("Error searching Yap users")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func searchUserGroups(query: String, user: User, completion: @escaping ([Group]?, Error?) -> ()) {
        let userKey = user.uid!
        FirebaseOps.ref.child("user").child(userKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let groupKeys = snapshotValue["groups"] as? [String: Any] {
                    var groups : [Group] = Group.createKeyOnly(keys: Array(groupKeys.keys))
                    var validGroups: [Group] = []
                    for i in 0 ..< groups.count {
                        self.getGroup(group: groups[i], completion: { (g: Group?, error: Error?) in
                            if let g = g {
                                validGroups.append(g)
                            }
                            if i == groups.count-1 {
                                completion(validGroups, nil)
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No groups exist for this user")
                completion([], nil)
            }
        }) { (error) in
            print("Error searching user groups")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    // Get HeroBills associated with user
    static func getUserHeroBills(user: User, completion: @escaping ([Bill]?, Error?) -> ()) {
        let userKey = user.uid!
        FirebaseOps.ref.child("user").child(userKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let heroKeys = snapshotValue["herobills"] as? [String: Any] {
                    var bills : [Bill] = Bill.createKeyOnly(keys: Array(heroKeys.keys))
                    for i in 0 ..< bills.count {
                        self.getBill(bill: bills[i], completion: { (b, error) in
                            if let b = b {
                                user.heroBills.append(b)
                                if i == bills.count-1 {
                                    bills.sort{ $0.createdDate ?? Date() > $1.createdDate ?? Date() }
                                    completion(bills, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No hero bills exist for this user")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting user hero bills")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    // Get MoocherBills associated with user
    static func getUserMoocherBills(user: User, completion: @escaping ([Bill]?, Error?) -> ()) {
        let userKey = user.uid!
        FirebaseOps.ref.child("user").child(userKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let moocherKeys = snapshotValue["moocherbills"] as? [String: Any] {
                    var bills : [Bill] = Bill.createKeyOnly(keys: Array(moocherKeys.keys))
                    for i in 0 ..< bills.count {
                        self.getBill(bill: bills[i], completion: { (b, error) in
                            if let b = b {
                                user.moocherBills.append(b)
                                if i == bills.count-1 {
                                    bills.sort{ $0.createdDate! > $1.createdDate! }
                                    completion(bills, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No moocher bills exist for this user")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting user moocher bills")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    // Get groups associated with user
    static func getUserGroups(user: User, completion: @escaping ([Group]?, Error?) -> ()) {
        let userKey = user.uid!
        FirebaseOps.ref.child("user").child(userKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let groupKeys = snapshotValue["groups"] as? [String: Any] {
                    var groups : [Group] = Group.createKeyOnly(keys: Array(groupKeys.keys))
                    for i in 0 ..< groups.count {
                        self.getGroup(group: groups[i], completion: { (g: Group?, error: Error?) in
                            if let g = g {
                                user.groups.append(g)
                                if i == groups.count-1 {
                                    completion(groups, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No groups exist with this user")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting user groups")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    // Get bills associated with group
    static func getGroupBills(group: Group, completion: @escaping ([Bill]?, Error?) -> ()) {
        let groupKey = group.key!
        FirebaseOps.ref.child("group").child(groupKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let billKeys = snapshotValue["bills"] as? [String: Any] {
                    var bills : [Bill] = Bill.createKeyOnly(keys: Array(billKeys.keys))
                    for i in 0 ..< bills.count {
                        self.getBill(bill: bills[i], completion: { (b, error) in
                            if let b = b {
                                group.bills.append(b)
                                if i == bills.count-1 {
                                    bills.sort{ $0.createdDate ?? Date() > $1.createdDate ?? Date() }
                                    completion(bills, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No bills exist for this user")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting group bills")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    // Get users payment statuses for a bill
    static func getUsersPaymentStatusForBill(bill: Bill, completion: @escaping (_ statuses: [String: Any]?, _ error: Error?) -> ()) {
        let billKey = bill.key!
        FirebaseOps.ref.child("bill").child(billKey).child("participants").observeSingleEvent(of: .value, with: { (snapshot) in
            var userStatuses: [String: Any] = [:]
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? DataSnapshot {
                if let snapshotValue = data.value as? [String: Any] {
                    let uid = data.key
                    let paid = snapshotValue["paid"] as? Bool
                    let amount = snapshotValue["amount"] as? Double
                    let timeTaken = snapshotValue["timeTaken"] as? Int
                    let status: [String : Any] = [ "paid" : paid, "amount" : amount, "timeTaken" : timeTaken ]
                    userStatuses[uid] = status
                }
            }
            completion(userStatuses, nil)
        }) { (error) in
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    
    // Update single item status
    static func updateSingleItem(billKey: String, itemKey: String) {
        let uid = FirebaseOps.currentUser?.uid!
        FirebaseOps.ref.child("item").child(itemKey).observeSingleEvent(of: .value, with:{(snapshot) in
            if snapshot.hasChild("participants/\(uid!)") {
                // Update user status under item
                let childUpdate = ["/item/\(itemKey)/participants/\(uid!)": true]
                FirebaseOps.ref.updateChildValues(childUpdate)
                // Check if item status needs to be updated under bill
                let snapshotValue = snapshot.value as! [String: AnyObject]
                let users = snapshotValue["participants"] as! [String:Bool]
                var completed = true
                for userKey in Array(users.keys){
                    if userKey == uid {
                        continue // skip current user
                    }
                    if users[userKey] == false {
                        completed = false
                    }
                }
                if completed {
                    // Update item status under bill
                    let update = ["/bill/\(billKey)/items/\(itemKey)": true]
                    FirebaseOps.ref.updateChildValues(update)
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    
    // Get info on bill
    static func getBill(bill: Bill, completion: @escaping (Bill?, Error?) -> ()) {
        let key = bill.key!
        FirebaseOps.ref.child("bill").child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value as? [String: AnyObject]) != nil {
                bill.update(snapshot: snapshot)
                completion(bill, nil)
            }
            else {
                print("No bill exists with this key")
                completion(nil, nil)
            }
        }) { (error) in
            print("Error getting bill")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    
    // Get info on BillItem
    static func getBillItem(item: BillItem, completion: @escaping (BillItem?, Error?) -> ()) {
        let key = item.key!
        FirebaseOps.ref.child("item").child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value as? [String: AnyObject]) != nil {
                item.update(snapshot: snapshot)
                item.resetPerPersonPrice()
                completion(item, nil)
            }
            else {
                print("No bill item exists with this key")
                completion(nil, nil)
            }
        }) { (error) in
            print("Error getting bill item")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func getGroup(group: Group, completion: @escaping (Group?, Error?) -> ()) {
        let groupKey = group.key!
        FirebaseOps.ref.child("group").child(groupKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value as? [String: AnyObject]) != nil {
                group.update(snapshot: snapshot)
                self.getGroupUsers(group: group, completion: { (groupUsers: [User]?, groupUsersError: Error?) in
                    if groupUsersError == nil {
                        group.users = groupUsers!
                    }
                    completion(group, nil)
                })
            }
            else {
                print("No bill item exists with this key")
                completion(nil, nil)
            }
        }) { (error) in
            print("Error getting group")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func getUser(user: User, completion: @escaping (User?, Error?) -> ()) {
        let userKey = user.uid!
        FirebaseOps.ref.child("user").child(userKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value as? [String: AnyObject]) != nil {
                user.update(snapshot: snapshot)
                completion(user, nil)
            }
            else {
                print("No user exists with this key")
                completion(nil, nil)
            }
        }) { (error) in
            print("Error getting user")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func getGroupUsers(group: Group, completion: @escaping ([User]?, Error?) -> ()) {
        let groupKey = group.key!
        FirebaseOps.ref.child("group").child(groupKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let userKeys = snapshotValue["users"] as? [String:Bool] {
                    var users : [User] = User.createKeyOnly(keys: Array(userKeys.keys))
                    group.users = []
                    for i in 0 ..< users.count {
                        self.getUser(user: users[i], completion: { (u, error) in
                            if let u = u {
                                group.users.append(u)
                                if i == users.count-1 {
                                    completion(users, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No users belong to this group")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting group users")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func getBillUsers(bill: Bill, completion: @escaping ([User]?, Error?) -> ()) {
        let billKey = bill.key!
        FirebaseOps.ref.child("bill").child(billKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let users = snapshotValue["participants"] as? [String: Any] {
                    let userKeys = Array(users.keys)
                    var users : [User] = User.createKeyOnly(keys: userKeys)
                    bill.participants = []
                    for i in 0 ..< users.count {
                        self.getUser(user: users[i], completion: { (u, error) in
                            if let u = u {
                                bill.participants.append(u)
                                if i == users.count-1 {
                                    completion(users, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No users belong to this bill")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting bill users")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func getBillItemUsers(item: BillItem, completion: @escaping ([User]?, Error?) -> ()) {
        let billItemKey = item.key!
        FirebaseOps.ref.child("billitem").child(billItemKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let userKeys = snapshotValue["participants"] as? [String] {
                    var users : [User] = User.createKeyOnly(keys: userKeys)
                    item.participants = []
                    for i in 0 ..< users.count {
                        self.getUser(user: users[i], completion: { (u, error) in
                            if let u = u {
                                item.participants.append(u)
                                if i == users.count-1 {
                                    completion(users, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No users belong to this bill item")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting bill item users")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    static func payBill(bill: Bill, user: User, completion: @escaping (Error?) -> ()) {
        let billKey = bill.key!
        let userKey = user.uid!
        let reference = FirebaseOps.ref.child("bill").child(billKey).child("participants").child(userKey).child("paid")
        let serialization = true
        reference.setValue(serialization, withCompletionBlock: { (error: Error?, dbRef: DatabaseReference) in
            if let error = error {
                print("Error creating bill "+bill.name!)
                print(error.localizedDescription)
                completion(error)
            }
            else {
                print("Paid bill")
                completion(nil)
            }
        })
    }
    
    static func updateBillData(bill: Bill){
        let billKey = bill.key
        let uid = FirebaseOps.currentUser?.uid
        // Update user status under bill and bill status under user
        let childUpdates = ["/bill/\(billKey!)/participants/\(uid!)/paid": true,
                            "/user/\(uid!)/moocherbills/\(billKey!)": true]
        FirebaseOps.ref.updateChildValues(childUpdates)
        FirebaseOps.ref.child("bill").child(billKey!).observeSingleEvent(of: .value, with:
            {(snapshot) in
                let snapshotValue = snapshot.value as! [String: AnyObject]
                let authorKey = snapshotValue["author"] as! String
                let users = snapshotValue["participants"] as! [String:Any]
                var completed = true
                for userKey in Array(users.keys) {
                    if userKey == uid {
                        continue // skip current user
                    }
                    let userstatus = users[userKey] as! [String: AnyObject]
                    let userpaid = userstatus["paid"] as! Bool
                    if !userpaid {
                        completed = false
                    }
                }
                if completed {
                    // Update bill as completed both under bill and under bill author if everyone has paid
                    let updates = ["/bill/\(billKey!)/completed": true,
                                   "/user/\(authorKey)/herobills/\(billKey!)": true]
                    ref.updateChildValues(updates)
                }
                // Update bill items status
                let items = snapshotValue["items"] as! [String: Bool]
                for itemKey in Array(items.keys){
                    FirebaseOps.updateSingleItem(billKey: billKey!, itemKey: itemKey)
                }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    static func getBillItems(bill: Bill, completion: @escaping ([BillItem]?, Error?) -> ()) {
        let billKey = bill.key!
        FirebaseOps.ref.child("bill").child(billKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
                if let itemKeys = snapshotValue["items"] as? [String] {
                    var items : [BillItem] = BillItem.createKeyOnly(keys: itemKeys)
                    bill.items = []
                    for i in 0 ..< items.count {
                        self.getBillItem(item: items[i], completion: { (t, error) in
                            if let t = t {
                                bill.items.append(t)
                                if i == items.count-1 {
                                    completion(items, nil)
                                }
                            }
                        })
                    }
                }
                else {
                    completion([], nil)
                }
            }
            else {
                print("No bill item exists with this key")
                completion([], nil)
            }
        }) { (error) in
            print("Error getting bill items")
            print(error.localizedDescription)
            completion(nil, error)
        }
    }
    
    
}
