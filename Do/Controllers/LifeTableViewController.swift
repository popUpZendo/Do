//
//  LifeTableViewController.swift
//  Do
//
//  Created by Joseph Hall on 4/5/19.
//  Copyright © 2019 Pop Up Zendo. All rights reserved.
//

import UIKit
import Firebase

class LifeTableViewController: UITableViewController {
    
    // MARK: Constants
    let listToUsers = "ListToUsers"
    
    // MARK: Properties
    var items: [LifeItem] = []
    var user: User!
    //var userCountBarButtonItem: UIBarButtonItem!
    let ref = Database.database().reference(withPath: "life-items")
    let usersRef = Database.database().reference(withPath: "online")
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = false
        
        
        ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            var newItems: [LifeItem] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let lifeItem = LifeItem(snapshot: snapshot) {
                    newItems.append(lifeItem)
                }
            }
            
            self.items = newItems
            self.tableView.reloadData()
        })
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            
            let currentUserRef = self.usersRef.child(self.user.uid)
            currentUserRef.setValue(self.user.email)
            currentUserRef.onDisconnectRemoveValue()
        }
        
    }
    
    // MARK: UITableView Delegate methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let lifeItem = items[indexPath.row]
        
        cell.textLabel?.text = lifeItem.name
        cell.detailTextLabel?.text = lifeItem.addedByUser
        
        toggleCellCheckbox(cell, isCompleted: lifeItem.completed)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let lifeItem = items[indexPath.row]
            lifeItem.ref?.removeValue()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let lifeItem = items[indexPath.row]
        let toggledCompletion = !lifeItem.completed
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        lifeItem.ref?.updateChildValues([
            "completed": toggledCompletion
            ])
    }
    
    
//    // Converted swipe cell to three choices
//    override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
//        let more = UITableViewRowAction(style: .normal, title: "More") { action, index in
//            print("more button tapped")
//        }
//        more.backgroundColor = .lightGray
//        
//        let favorite = UITableViewRowAction(style: .normal, title: "Favorite") { action, index in
//            print("favorite button tapped")
//        }
//        favorite.backgroundColor = .orange
//        
//        let share = UITableViewRowAction(style: .normal, title: "Share") { action, index in
//            print("share button tapped")
//        }
//        share.backgroundColor = .blue
//        
//        return [share, favorite, more]
//    }
    
    
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
    }
    
    // MARK: Add Item
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "This is Water",
                                      message: "Add a Task",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return }
            
            
            let lifeItem = LifeItem(name: text,
                                    addedByUser: self.user.email,
                                    completed: false)
            
            let sczcItemRef = self.ref.child(text.lowercased())
            
            sczcItemRef.setValue(lifeItem.toAnyObject())
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
}
