//
//  DefaultOps.swift
//  accountabill
//
//  Created by Tiffany Madruga on 8/3/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth



class DefaultOps {
    
    static var bills: [Bill] = []
    static var users: [User] = []
    static var groups: [Group] = []
    
    static var currentUser: User?
    
    static func userLoggedIn() -> Bool {
        return false
    }
    
    static func initialize() {
        // Users
        var users: [User] = []
        users.append(User(uid: "mqGIu1HV6PVjElJiWUkEu1jPX803", name: "Michael", email: "mwornow@fb.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User(uid: "qbcBuWBrr1O29qn3PjMWuHX3Ton1", name: "Tiffany", email: "tmadruga@fb.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User(uid: "afmbOc5VmpMc5caEiAwlPj4AMNz2", name: "Xueying", email: "xwang@fb.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User(uid: "matthew", name: "Matthew", email: "matthew@fb.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User.init(uid: "zach", name: "Zach", email: "zach@gmail.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User.init(uid: "alex", name: "Alex", email: "alex@gmail.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User.init(uid: "damian", name: "Damian", email: "damian@gmail.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        users.append(User.init(uid: "jonah", name: "Jonah", email: "jonah@gmail.com", photoURL: "fbu", heroBills: [], moocherBills: [], groups: []))
        DefaultOps.users = users
        
        // Current user
        DefaultOps.currentUser = DefaultOps.users[0]
        DefaultOps.currentUser?.facebookAuthenticationToken = "EAAFHKLYAREsBAJW2QvmTfCIZCFiBPcZCn55PVNTpEpZB0iab9a1gcRlE7RehdFplc8YdpGMm0kAURAJj8qFdp3ochaHlELf8wjiP6NBsuEB8nNKZCHlJv6n8aOtnMYiQzUcZBxx5aIU1f5Ahya3CoVZAgZAFWLCqc31WjHNZBLXCYc6COZAdKRxtZCcZB1nbFNEB5uJYduubWnBVAa52ZBWE6GAfRSmZC959WKYNK1U2bEHEh2XBrGpsurW8t"
        DefaultOps.currentUser?.facebookID = "2313035938922454"

        // Groups
        let FBUgroupUsers = [ DefaultOps.users[0], DefaultOps.users[1], DefaultOps.users[2] ]
        let FBUgroup = Group(key: "fbu", name: "FBU Team", author: DefaultOps.currentUser!, users: FBUgroupUsers, bills: [], createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-24T15:47:11-07:00"))
        let friendsGroupUsers = [ DefaultOps.currentUser!, DefaultOps.users[4], DefaultOps.users[5], DefaultOps.users[6], DefaultOps.users[7] ]
        let friendsGroup = Group(key: "friends", name: "Roommates", author: DefaultOps.currentUser!, users: friendsGroupUsers, bills: [], createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-21T11:47:11-07:00"))
        let groupGroupUsers = [ DefaultOps.users[0], DefaultOps.users[1], DefaultOps.users[2], DefaultOps.users[3] ]
        let groupGroup = Group(key: "group", name: "Best Group Ever", author: DefaultOps.currentUser!, users: groupGroupUsers, bills: [], createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-08-03T19:22:11-07:00"))

        DefaultOps.groups.append(FBUgroup)
        DefaultOps.groups.append(friendsGroup)
        DefaultOps.groups.append(groupGroup)
        
        // Bills and Bill Items
        var bills: [Bill] = []
        var items: [BillItem] = []
        //// Kitchen
        items.append(BillItem(key: "kitchen1", name: "24 Hrs Beef Noodle Soup", price: 41.90, quantity: 2, unitPrice: 20.95))
        items.append(BillItem(key: "kitchen2", name: "Coke", price: 2.95, quantity: 1, unitPrice: 2.95))
        items.append(BillItem(key: "kitchen3", name: "Crispy Calamari", price: 14.00, quantity: 1, unitPrice: 14.00))
        items.append(BillItem(key: "kitchen4", name: "Panag Neua", price: 25.50, quantity: 1, unitPrice: 25.50))
        bills.append(Bill(key: "kitchen", name: "Farmhouse", author: DefaultOps.currentUser!, completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-08-09T12:47:11-07:00"), location: "Menlo Park, CA", items: items, receiptImage: "", tax: 7.17, tip: 0.00, subtotal: 84.35, total: 91.52, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Safeway
        items = []
        items.append(BillItem(key: "safeway1", name: "Jello Chseck", price: 2.99, quantity: 1, unitPrice: 2.99))
        items.append(BillItem(key: "safeway2", name: "Lucerne Creamer", price: 3.99, quantity: 1, unitPrice: 2.95))
        items.append(BillItem(key: "safeway3", name: "Cantaloupe Melon", price: 2.00, quantity: 1, unitPrice: 14.00))
        items.append(BillItem(key: "safeway4", name: "Yellow Corn", price: 2.00, quantity: 1, unitPrice: 25.50))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "safeway", name: "Safeway", author: DefaultOps.users[1], completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-08-06T12:41:54-07:00"), location: "San Francisco, CA", items: items, receiptImage: "", tax: 0.00, tip: 0.00, subtotal: 10.98, total: 10.98, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Din
        items = []
        items.append(BillItem.init(key: "din1", name: "Fried Pork Chop", price: 6.50, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "din2", name: "Shrimp Shanghai Rice Cake", price: 11.75, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "din3", name: "Pork Xiao Long Bao", price: 16.00, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "din4", name: "Shrimp Pork Pot Stickers", price: 9.50, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "din5", name: "Jasmine Tea", price: 3.50, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "din6", name: "Shrimp & Pork ShaoMai", price: 11.00, quantity: 1, unitPrice: 6.50))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "din", name: "Din Tai Fung", author: DefaultOps.users[0], completed: true, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-29T19:14:05-07:00"), location: "Santa Clara, CA", items: items, receiptImage: "", tax: 5.39, tip: 11.65, subtotal: 58.25, total: 75.29, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Pret
        items = []
        items.append(BillItem.init(key: "pret1", name: "Original Pretzel", price: 3.69, quantity: 1, unitPrice: 20.95))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "pret", name: "Wetzel's Pretzels", author: DefaultOps.currentUser!, completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-26T15:47:11-07:00"), location: "San Jose, CA", items: items, receiptImage: "", tax: 0.33, tip: 0.00, subtotal: 3.69, total: 4.02, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Costco
        items = []
        items.append(BillItem.init(key: "costco1", name: "Activa Yog", price: 9.99, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "costco2", name: "Cherries", price: 8.99, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "costco3", name: "Lemon Mousse", price: 8.99, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "costco4", name: "Seaweed Sld", price: 10.69, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "costco5", name: "St. Louis", price: 14.02, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "costco6", name: "Shrimp Cktl", price: 11.99, quantity: 1, unitPrice: 20.95))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "costco", name: "Costco", author: DefaultOps.users[0], completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-22T13:23:11-07:00"), location: "Redwood City, CA", items: items, receiptImage: "", tax: 0.00, tip: 0.00, subtotal: 63.67, total: 63.67, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Cheese
        items = []
        items.append(BillItem.init(key: "cheese1", name: "Soda", price: 3.50, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "cheese2", name: "Fried Mac & Cheese", price: 11.95, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "cheese3", name: "Pasta w/Shrimp Sausage", price: 17.95, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "cheese4", name: "Fried Shrimp Platter", price: 17.95, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "cheese5", name: "Original Cheesecake", price: 6.95, quantity: 1, unitPrice: 20.95))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "cheese", name: "Cheesecake Factory", author: DefaultOps.users[1], completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-21T19:41:11-07:00"), location: "Hillsdale, CA", items: items, receiptImage: "", tax: 5.25, tip: 12.00, subtotal: 58.30, total: 75.55, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Ramen
        items = []
        items.append(BillItem.init(key: "ramen1", name: "Cmb B-Shoyu [Dinner]", price: 12.48, quantity: 1, unitPrice: 20.95))
        items.append(BillItem.init(key: "ramen2", name: "Cmb B-Miso [Dinner]", price: 12.48, quantity: 1, unitPrice: 20.95))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "ramen", name: "Maruichi", author: DefaultOps.users[2], completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-19T10:03:43-07:00"), location: "Mountain View, CA", items: items, receiptImage: "", tax: 2.25, tip: 5.00, subtotal: 24.96, total: 32.21, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Yokohama
        items = []
        items.append(BillItem.init(key: "yokohama1", name: "Soft Drinks", price: 1.85, quantity: 1, unitPrice: 2.99))
        items.append(BillItem.init(key: "yokohama2", name: "Sashimi DE", price: 26.95, quantity: 1, unitPrice: 2.95))
        items.append(BillItem.init(key: "yokohama3", name: "Dinner Combination", price: 14.95, quantity: 1, unitPrice: 14.00))
        items.append(BillItem.init(key: "yokohama4", name: "Playboy", price: 13.95, quantity: 1, unitPrice: 25.50))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "yokohama", name: "Yokohama", author: DefaultOps.currentUser!, completed: false, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-16T12:57:31-07:00"), location: "Redwood City, CA", items: items, receiptImage: "", tax: 5.21, tip: 9.44, subtotal: 57.70, total: 72.35, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))
        //// Ranch
        items = []
        items.append(BillItem.init(key: "ranch1", name: "Glico Pocky Matcha", price: 1.69, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch2", name: "Glico Pocky Strawberry", price: 1.69, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch3", name: "Glico Pocky Pejoy Matcha", price: 1.69, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch4", name: "Glico Pocky Cookies n Cream", price: 1.69, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch5", name: "Jia Duo Bao Herbal Tea", price: 17.50, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch6", name: "Juice/water crv 6-pk", price: 1.50, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch7", name: "Vitasoy Lemon Tea", price: 12.00, quantity: 1, unitPrice: 6.50))
        items.append(BillItem.init(key: "ranch8", name: "Guangxi Instant Rice Noodle", price: 79.80, quantity: 1, unitPrice: 6.50))
        for i in items {
            i.setParticipants(participants: DefaultOps.groups[0].users)
        }
        bills.append(Bill(key: "ranch", name: "99 Ranch Market", author: DefaultOps.users[2], completed: true, modifiedDate: nil, createdDate: Base.convertDateFromFirebaseToString(dateString: "2017-07-15T15:31:15-07:00"), location: "Foster City, CA", items: items, receiptImage: "", tax: 0.00, tip: 0.00, subtotal: 117.56, total: 117.56, participants: DefaultOps.groups[0].users, group: DefaultOps.groups[0]))

        DefaultOps.bills = bills
        DefaultOps.groups[0].bills = bills
    }
    
    static func pictures(user: User) -> UIImage{
        if user.uid == "zach" {
            return #imageLiteral(resourceName: "zach_profile")
        }
        else if user.uid == "alex" {
            return #imageLiteral(resourceName: "alex_profile")
        }
        else if user.uid == "damian" {
            return #imageLiteral(resourceName: "damian_profile")
        }
        else if user.uid == "jonah" {
            return #imageLiteral(resourceName: "jonah_profile")
        }
        else if user.uid == "matthew" {
            return #imageLiteral(resourceName: "matthew")
        }
        else if user.uid == "qbcBuWBrr1O29qn3PjMWuHX3Ton1"{
            return #imageLiteral(resourceName: "tiffany")
        }
        else if user.uid == "afmbOc5VmpMc5caEiAwlPj4AMNz2" {
            return #imageLiteral(resourceName: "xueying")
        }
        else if user.uid == "mqGIu1HV6PVjElJiWUkEu1jPX803" {
            return #imageLiteral(resourceName: "michael")
        }
        else {
            return #imageLiteral(resourceName: "profile_icon")
        }
    }
    
    static func billPicture(bill: Bill) -> UIImage{
        if bill.key == "kitchen"{
            return #imageLiteral(resourceName: "kitchen")
        }
        else if bill.key == "safeway"{
            return #imageLiteral(resourceName: "safeway")
        }
        else if bill.key == "din"{
            return #imageLiteral(resourceName: "din")
        }
        else if bill.key == "ranch" {
            return #imageLiteral(resourceName: "dahua")
        }
        else if bill.key == "costco" {
            return #imageLiteral(resourceName: "costco2")
        }
        else if bill.key == "pret"{
            return #imageLiteral(resourceName: "pret")
        }
        else if bill.key == "ramen"{
            return #imageLiteral(resourceName: "maruichi2")
        }
        else if bill.key == "cheese"{
            return #imageLiteral(resourceName: "hillsdale")
        }
        else {
            return #imageLiteral(resourceName: "yokohama")
        }
    }
    
    static func userLogin(credential: AuthCredential, completion: @escaping (_ success: Bool) -> Void) {
        DefaultOps.currentUser = DefaultOps.users[0]
    }
    
    
    static func userLogout(completion: @escaping (_ success: Bool) -> Void) {
        DefaultOps.currentUser = nil
        completion(true)
    }

    
    static func getBillItems(bill: Bill, completion: @escaping ([BillItem]?, Error?) -> ()){
        for b in DefaultOps.bills {
            if b.key == bill.key {
                completion(b.items, nil)
            }
        }
        completion(nil, nil)
    }
    
    static func getBillItemUsers(item: BillItem, completion: @escaping ([User]?, Error?) -> ()){
        for b in DefaultOps.bills {
            for i in b.items {
                if i.key == item.key {
                    completion(i.participants, nil)
                }
            }
        }
        completion(nil, nil)
    }
    
    static func getBillUsers(bill: Bill, completion: @escaping ([User]?, Error?) -> ()){
        for b in DefaultOps.bills {
            if b.key == bill.key {
                completion(b.participants, nil)
            }
        }
        completion(nil, nil)
    }
    
    static func getGroupUsers(group: Group, completion: @escaping ([User]?, Error?) -> ()) {
        for g in DefaultOps.groups {
            if g.key == group.key {
                completion(g.users, nil)
            }
        }
        completion(nil, nil)
    }
    
    static func getUser(user: User, completion: @escaping (User?, Error?) -> ()){
        for u in DefaultOps.users {
            if u.uid == user.uid {
                completion(u, nil)
            }
        }
        completion(nil, nil)
    }
    
    static func getGroup(group: Group, completion: @escaping (Group?, Error?) -> ()) {
        for g in DefaultOps.groups {
            if g.key == group.key {
                completion(g, nil)
            }
        }
        completion(nil, nil)
    }
    
    static func getBillItem(item: BillItem, completion: @escaping (BillItem?, Error?) -> ()){
        for b in DefaultOps.bills {
            for i in b.items {
                if i.key == item.key {
                    completion(i, nil)
                }
            }
        }
        completion(nil, nil)
    }
    
    static func getBill(bill: Bill, completion: @escaping (Bill?, Error?) -> ()) {
        for b in DefaultOps.bills {
            if b.key == bill.key {
                completion(b, nil)
            }
        }
    }
    
    static func getGroupBills(group:Group, completion: @escaping ([Bill]?, Error?) -> ()){
       completion(DefaultOps.bills,nil)
    }
    
    static func getUserGroups(user: User, completion: @escaping([Group]?, Error?) -> () ){
        completion(DefaultOps.groups,nil)
    }
    
    static func getUserMoocherBills(user: User, completion: @escaping ([Bill]?, Error?)-> ()){
        var bills: [Bill] = []
        for b in DefaultOps.bills {
            if !User.checkSameUser(user1: b.author!, user2: DefaultOps.currentUser!) {
                bills.append(b)
            }
        }
        completion(bills, nil)
    }
    
    static func getUserHeroBills(user: User, completion: @escaping ([Bill]?, Error?)-> ()){
        var bills: [Bill] = []
        for b in DefaultOps.bills {
            if User.checkSameUser(user1: b.author!, user2: DefaultOps.currentUser!) {
                bills.append(b)
            }
        }
        completion(bills, nil)
    }
    
    static func updateSingleItem(billKey: String, itemKey: String){
    }
    
    static func payBill(bill: Bill, user: User) {
        for p in bill.participants {
            if User.checkSameUser(user1: p, user2: user) {
                for b in DefaultOps.bills {
                    if b.key == bill.key {
                        b.paid = true
                    }
                }
            }
        }
    }
    
    static func getUsersPaymentStatusForBill(bill:Bill, completion: @escaping (_ statuses: [String: Any]?, _ error: Error?) -> ()){
        var userStatuses: [String: [String: Any]] = [:]
        if bill.key == "kitchen" {
            userStatuses[DefaultOps.users[0].uid!] = ["paid": false, "amount": 30.51, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 30.51, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 30.51, "timeTaken": 0]
        }
        else if bill.key == "safeway" {
            userStatuses[DefaultOps.users[0].uid!] = ["paid": false, "amount": 3.67, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 5.33, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 1.00, "timeTaken": 0]
        }
        else if bill.key == "din"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": true, "amount": 25.09, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": true, "amount": 25.09, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": true, "amount": 25.09, "timeTaken": 0]
        }
        else if bill.key == "yokohama"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": false, "amount": 24.12, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 24.12, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": true, "amount": 24.12, "timeTaken": 0]
        }
        else if bill.key == "pret"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": true, "amount": 1.34, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 1.34, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 1.34, "timeTaken": 0]
        }
        else if bill.key == "costco"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": false, "amount": 21.22, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 21.22, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": true, "amount": 21.22, "timeTaken": 0]
        }
        else if bill.key == "cheese"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": false, "amount": 25.18, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": true, "amount": 25.18, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 25.18, "timeTaken": 0]
        }
        else if bill.key == "ramen"{
            userStatuses[DefaultOps.users[0].uid!] = ["paid": true, "amount": 10.74, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 10.74, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 10.74, "timeTaken": 0]
        }
        else if bill.key == "ranch" {
            userStatuses[DefaultOps.users[0].uid!] = ["paid": true, "amount": 39.19, "timeTaken": 0]
            userStatuses[DefaultOps.users[1].uid!] = ["paid": false, "amount": 39.19, "timeTaken": 0]
            userStatuses[DefaultOps.users[2].uid!] = ["paid": false, "amount": 39.19, "timeTaken": 0]
        }
        
        for b in DefaultOps.bills {
            if b.key == bill.key {
                userStatuses[DefaultOps.currentUser!.uid!]?["paid"] = (userStatuses[DefaultOps.currentUser!.uid!]?["paid"] as? Bool ?? false) || bill.paid
            }
        }
        
        completion(userStatuses,nil)
    }
    
    static func searchUserGroups(query: String, user: User, completion: @escaping ([Group]?, Error?) -> ()) {
        completion(DefaultOps.groups,nil)
    }
    
    static func searchUsers(query: String, completion: @escaping([User]?, Error?) -> Void) {
        completion(DefaultOps.users,nil)
    }
    
    static func createBillItem(item: BillItem, completion: @escaping (_ error: Error?, _ newBillItem: BillItem?) -> Void){
        completion(nil, item)
    }
    
    static func sendBill(bill: Bill, completion: @escaping (_ error: Error?) -> Void){
        completion(nil)
    }
    
    static func createGroup(group: Group, completion: @escaping (_ error: Error?, _ newGroup: Group?) -> Void) {
        completion(nil, group)
    }
    
    static func createBill(bill: Bill, completion: @escaping (_ error: Error?, _ newBill: Bill?) -> Void){
        completion(nil, bill)
    }
    
    static func createUser(user: User, completion: @escaping (_ error: Error?, _ newUser: User?) -> Void){
        completion(nil, user)
    }

}
