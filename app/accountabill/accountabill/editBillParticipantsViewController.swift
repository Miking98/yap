//
//  editBillParticipantsViewController.swift
//  accountabill
//
//  Created by Michael Wornow on 7/24/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import UIKit
import SCLAlertView

class editBillParticipantsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, UIScrollViewDelegate, editBillParticipantsAddedDelegate {
    
    @IBOutlet weak var searchFriendsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var searchSearchBar: UISearchBar!
    @IBOutlet weak var addedParticipantsCollectionView: UICollectionView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    
    var bill: Bill!
    var participants: [User] = []
    var userGroups: [Group] = []
    var facebookFriends: [User] = []
    var searchResults = [("Yap Users", []), ("Groups", []), ("Facebook", [])]
    let RESULTS_ACCOUNTABILL_INDEX = 0
    let RESULTS_FACEBOOK_INDEX = 2
    let RESULTS_GROUPS_INDEX = 1
    var searchLastRequest: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchFriendsSegmentedControl.layer.cornerRadius = 4.0
        searchFriendsSegmentedControl.clipsToBounds = true
        
        // Initialize participants as bill's current participants
        participants = bill.participants
        
        // Set up Collection View of participants
        addedParticipantsCollectionView.delegate = self
        addedParticipantsCollectionView.dataSource = self
        
        // Search bar
        searchSearchBar.delegate = self
        
        // Set up Table View of participants
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "editBillParticipantsSearchHeaderView")
        
        // Preload search results
        //// Facebook Friends
        FacebookOps.searchFriends(query: "") { (success: Bool, users: [User]?, next: String?) in
            if success {
                print("Done getting Facebook friends")
                self.facebookFriends = users!
            }
        }
    }
    
    //
    // Participant collection view
    //
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editBillParticipantsAddedCollectionViewCell", for: indexPath) as! editBillParticipantsAddedCollectionViewCell
        cell.user = participants[indexPath.row]
        cell.delegate = self
        return cell
    }
    // Participant collection cell delegate functions
    func removeParticipant(user: User) {
        for i in 0..<participants.count {
            if User.checkSameUser(user1: user, user2: participants[i]) {
                removeParticipant(index: i)
                return
            }
        }
    }
    func removeParticipant(index: Int) {
        let user = participants[index]
        // If removed user should be in search results, re-add him
        if checkUserMatchesQuery(user: participants[index], query: searchSearchBar.text!) {
            print("Add back participant "+participants[index].name!)
            addParticipantToSearchResults(user: participants[index])
        }
        // Remove user from participants
        participants.remove(at: index)
        // Reload collection view
        addedParticipantsCollectionView.reloadData()
        print("Removed participant "+user.name!)
    }
    func addParticipant(user: User) {
        var insertIndex = participants.count
        for i in 0..<participants.count {
            if (participants[i].name?.localizedCaseInsensitiveCompare(user.name!) == ComparisonResult.orderedDescending) {
                insertIndex = i
            }
        }
        if insertIndex == participants.count {
            participants.append(user)
        }
        else {
            participants.insert(user, at: insertIndex)
        }
    }
    func addParticipantToSearchResults(user: User) {
        // Determine how we got this user
        var resultIndex = RESULTS_ACCOUNTABILL_INDEX
        if user.uid != nil {
            resultIndex = RESULTS_ACCOUNTABILL_INDEX
        }
        else if user.facebookID != nil {
            resultIndex = RESULTS_FACEBOOK_INDEX
        }
        else if user.facebookTaggableID != nil {
            resultIndex = RESULTS_FACEBOOK_INDEX
        }
        var results = searchResults[resultIndex].1
        var insertIndex = results.count
        for i in 0..<results.count {
            let resultUser = results[i] as! User
            if (resultUser.name!.localizedCaseInsensitiveCompare(user.name!) == ComparisonResult.orderedDescending) {
                insertIndex = i
                break
            }
        }
        if insertIndex == results.count {
            searchResults[RESULTS_FACEBOOK_INDEX].1.append(user)
        }
        else {
            searchResults[RESULTS_FACEBOOK_INDEX].1.insert(user, at: insertIndex)
        }
        // Reload table view
        searchResultsTableView.reloadData()
    }
    
    //
    // Search results table view
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchResults.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults[section].1.count
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "editBillParticipantsSearchHeaderView")
        header?.textLabel?.text = searchResults[section].0
        return header
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "editBillParticipantsSearchTableViewCell", for: indexPath) as! editBillParticipantsSearchTableViewCell
        let results = searchResults[indexPath.section].1
        cell.result = results[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selection = searchResults[indexPath.section].1[indexPath.row]
        if let user = selection as? User {
            // Insert user in alphabetical order
            addParticipant(user: user)
        }
        else if let group = selection as? Group {
            for user in group.users {
                // Check that user isn't already added
                var alreadyAdded = false
                for p in participants {
                    if User.checkSameUser(user1: user, user2: p) {
                        alreadyAdded = true
                    }
                }
                if !alreadyAdded {
                    addParticipant(user: user)
                }
            }
            userGroups.append(group)
        }
        // Reload participants collection view with new users
        addedParticipantsCollectionView.reloadData()
        // Reload table view with selected item removed
        searchResults[indexPath.section].1.remove(at: indexPath.row)
        searchBar(searchSearchBar, textDidChange: searchSearchBar.text!)
    }
    
    // Search Filters
    // All/Friends only segmented control
    @IBAction func searchFriendsSegmentedControlValueChanged(_ sender: Any) {
        // Reload search results with updated filter
        searchBar(searchSearchBar, textDidChange: searchSearchBar.text!)
    }
    // Search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults[RESULTS_ACCOUNTABILL_INDEX].1 = []
        searchResults[RESULTS_FACEBOOK_INDEX].1 = []
        searchResults[RESULTS_GROUPS_INDEX].1 = []
        searchResultsTableView.reloadData()
        // Make sure only the most recent search result is returned
        let thisSearchRequest = Date()
        searchLastRequest = thisSearchRequest
        // Empty results if empty search
        if searchText == "" {
            return
        }
        
        // 1. Get Groups
        FirebaseOps.getUserGroups(user: FirebaseOps.currentUser!) { (groups, error) in
            if self.searchLastRequest == thisSearchRequest {
                if error == nil {
                    print("Done getting groups")
                    var validGroups: [Group] = []
                    for g in groups! {
                        if self.checkGroupMatchesQuery(group: g, query: searchText) {
                            if !self.userGroups.contains(where: { $0.key == g.key }) {
                                validGroups.append(g)
                            }
                        }
                    }
                    self.searchResults[self.RESULTS_GROUPS_INDEX].1 = validGroups
                    self.searchResultsTableView.reloadData()
                }
            }
        }
        
        // 2. Get Facebook users
        if searchFriendsSegmentedControl.selectedSegmentIndex==1 {
            FacebookOps.searchAll(query: searchText) { (success: Bool, users: [User]?, next: String?) in
                if self.searchLastRequest == thisSearchRequest {
                    if success {
                        print("Done getting Facebook users")
                        var users = users!
                        var i = 0
                        var usersCount = users.count // Need to store usersCount in var b/c we are removing elements from it, so we must update the length of users dynamically
                        while i<usersCount  {
                            if self.participants.contains(where: { $0.facebookID == users[i].facebookID }) {
                                users.remove(at: i)
                                usersCount -= 1
                            }
                            else {
                                i += 1
                            }
                        }
                        self.searchResults[self.RESULTS_FACEBOOK_INDEX].1 = users
                        self.searchResultsTableView.reloadData()
                    }
                }
            }
        }
        else {
            if self.searchLastRequest == thisSearchRequest {
                var users: [User] = []
                for f in facebookFriends  {
                    if checkUserMatchesQuery(user: f, query: searchText) {
                        if !self.participants.contains(where: { $0.facebookID != nil && f.facebookID != nil && $0.facebookID == f.facebookID || $0.facebookTaggableID != nil && f.facebookTaggableID != nil && $0.facebookTaggableID == f.facebookTaggableID}) {
                            users.append(f)
                        }
                    }
                }
                self.searchResults[RESULTS_FACEBOOK_INDEX].1 = users.sorted(by: { (user1: User, user2: User) -> Bool in
                    user1.name! < user2.name!
                })
                self.searchResultsTableView.reloadData()
            }
        }
        
        // 3. Get Accountabill users
        FirebaseOps.searchUsers(query: searchText) { (users: [User]?, error: Error?) in
            if error == nil {
                print("Done getting Yap users")
                var users = users!
                var i = 0
                var usersCount = users.count // Need to store usersCount in var b/c we are removing elements from it, so we must update the length of users dynamically
                while i<usersCount  {
                    if self.participants.contains(where: { $0.uid == users[i].uid }) {
                        users.remove(at: i)
                        usersCount -= 1
                    }
                    else if !self.checkUserMatchesQuery(user: users[i], query: searchText) {
                        users.remove(at: i)
                        usersCount -= 1
                    }
                    else {
                        i += 1
                    }
                }
                self.searchResults[self.RESULTS_ACCOUNTABILL_INDEX].1 = users
                self.searchResultsTableView.reloadData()
            }
        }
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchSearchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchSearchBar.showsCancelButton = false
        searchSearchBar.text = ""
        searchSearchBar.resignFirstResponder()
    }
    func checkUserMatchesQuery(user: User, query: String) -> Bool {
        return user.name!.lowercased().range(of: query.lowercased()) != nil
    }
    func checkGroupMatchesQuery(group: Group, query: String) -> Bool {
        return group.name!.lowercased().range(of: query.lowercased()) != nil
    }
    
    // Main tap gesture, hide keyboard
    @IBAction func mainTapGestureAction(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Scrolling action, hide keyboard
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    // Top menu buttons
    @IBAction func cancelButtonTouch(_ sender: Any) {
        navigationController?.popViewController(animated:true)
    }
    @IBAction func confirmButtonTouch(_ sender: Any) {
        // Save participants in Bill
        bill.setParticipants(participants: participants)
        let group: Group? = findGroupMatchesUsers(participants: participants, groups: self.userGroups)
        bill.group = group
        performSegue(withIdentifier: "editBillParticipantsToAssignBillParticipants", sender: self)
    }
    
    // Create group
    @IBAction func createGroupButtonTouch(_ sender: Any) {
        showCreateGroupAlert()
    }
    
    func showCreateGroupAlert() {
        if participants.count == 0 {
            return
        }
        
        // Create alert
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "Avenir", size: 20)!,
            kTextFont: UIFont(name: "Avenir", size: 14)!,
            kButtonFont: UIFont(name: "Avenir-Medium", size: 20)!,
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        
        // Create text fields
        let nameTextField = alert.addTextField()
        nameTextField.layer.borderColor = UIColor.black.cgColor
        nameTextField.placeholder = "Group name"
        nameTextField.returnKeyType = UIReturnKeyType.done
        nameTextField.delegate = self
        
        // Buttons
        alert.addButton("Create", backgroundColor: UIColor.green, textColor: UIColor.white) {
            let groupName = nameTextField.text ?? ""
            let group = Group(key: nil, name: groupName, author: FirebaseOps.currentUser!, users: self.participants, bills: [], createdDate: Date())
            FirebaseOps.createGroup(group: group) { (error: Error?, newGroup: Group?) in
                if let error = error {
                    print("Error creating group")
                    print(error)
                }
                else {
                    print("Success creating group ")
                }
            }
        }
        alert.addButton("Cancel", backgroundColor: UIColor.red, textColor: UIColor.white) {
            print("Canceled item add")
        }
        alert.showEdit("Create Group", subTitle: "")
        
    }
    
    //
    // Determine if participants match a group
    //
    func findGroupMatchesUsers(participants: [User], groups: [Group]) -> Group? {
        for group in groups {
            let allmembers = group.users
            if allmembers.count != participants.count {
                continue
            }
            else {
                var match = true
                for participant in participants {
                    if !allmembers.contains(where: {$0.uid == participant.uid}) {
                        match = false
                    }
                }
                if match {
                    return group
                }
            }
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editBillParticipantsToAssignBillParticipants" {
            let vc = segue.destination as! assignBillParticipantsViewController
            vc.bill = bill
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
