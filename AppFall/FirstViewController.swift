//
//  FirstViewController.swift
//  AppFall
//
//  Created by Adrian Baumgart on 10.11.18.
//  Copyright © 2018 Adrian Baumgart. All rights reserved.
//

import UIKit
import Firebase


class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var DetailText: UILabel!
    @IBOutlet weak var EinkaufBeendenOut: UIButton!
    @IBOutlet weak var EinkaufenGehenOut: UIButton!
    @IBAction func EinkaufenGehen(_ sender: Any)
    {
        let ref: DatabaseReference
        ref = Database.database().reference()
        ref.child("einkaufen").setValue(1) //Changes Database Value
        UserDefaults.standard.set("YES", forKey: "BUYER") //Changes Local Value
        viewDidLoad()
    }
    @IBAction func EinkaufenBeenden(_ sender: Any)
    {
        let ref: DatabaseReference
        ref = Database.database().reference()
        ref.child("einkaufen").setValue(0) //Changes Database Value
        UserDefaults.standard.set("NO", forKey: "BUYER") //Changes Local Value
        EndEinkaufen(title: "Einkauf beenden und Liste löschen", message: "Möchtest du die Liste löschen und den Einkauf beenden?") //WARNING
        viewDidLoad() //Reload
    }
    @IBOutlet weak var AddItemBtnOut: UIButton!
    @IBAction func AddItemBtn(_ sender: Any)
    {
        self.AddITEM(title: "Hinzufügen", message: "") //Alert with TextField and Button
    }
    @IBOutlet weak var ItemList: UITableView!
    var itemNames:[String] = [] //Array for all Names
    var itemMenge:[String] = [] //Array for all Amounts
    var databasekeys: [String] = [] //Array for all References in the Database
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemNames.count //Rows in UITableView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "listcell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        //if itemNames.count != 0 {
       // let cell = UITableViewCell(style: .default, reuseIdentifier: "listcell")
        cell!.textLabel?.text = itemNames[indexPath.row]
        cell!.detailTextLabel?.text = itemMenge[indexPath.row]
       // }
        return cell!
    }
    
    func loadData() { //Downloads all Data
        let ref: DatabaseReference
        ref = Database.database().reference()
        ref.child("list").observe(.value) { (snapshot) in //Download Data
            self.itemNames.removeAll() //Clear Array for Names
            self.itemMenge.removeAll() //Clear Array for Amounts
          //  ref.child("list").removeAllObservers()
            if let item = snapshot.value as? [String:AnyObject]{
                self.databasekeys = Array(item.keys) //Download members of List
               // print(self.databasekeys)
                for key in self.databasekeys {
                        var iN = item[key]!["Name"] as? String
                        var iM = item[key]!["Menge"] as? Int
                    var iMString = String(iM ?? 0)
                    self.itemNames.append(iN ?? "")
                    self.itemMenge.append(iMString)
                    
                }
                self.ItemList.reloadData()
            }
        }
        ref.child("list").observe(.childRemoved) { (snapshot) in //Download removed Data
            self.itemNames.removeAll() //Clear Array for Names
            self.itemMenge.removeAll() //Clear Array for Amounts
            self.ItemList.reloadData()
        }
    }
    @IBOutlet weak var ListTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        EinkaufenGehenOut.isEnabled = false
        EinkaufBeendenOut.isEnabled = false
        let ref: DatabaseReference
        ref = Database.database().reference()
        ref.child("einkaufen").observe(.value) { (EinkaufenAccessable) in // If somebody buy things
            let EinkaufenAccess = EinkaufenAccessable.value as? Int
            if EinkaufenAccess == 1 { //Check database value
                self.EinkaufenGehenOut.isEnabled = false
                self.AddItemBtnOut.isEnabled = false
                
            }
            else {
                self.EinkaufenGehenOut.isEnabled = true
                self.AddItemBtnOut.isEnabled = true
            }
            if UserDefaults.standard.string(forKey: "BUYER") == "YES" { //Check UserDefaults String
                self.EinkaufBeendenOut.isEnabled = true
            }
            else {
                self.EinkaufBeendenOut.isEnabled = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewDidLoad()
        loadData()
    }
     func randomString(length: Int) -> String { //USELESS - Generates random Number
       let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String((0...length-1).map{_ in letters.randomElement()!})
    }
    func EndEinkaufen (title: String, message: String) {
        let EE = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        //Delete List (154)
        EE.addAction(UIAlertAction(title: "Ja, Liste löschen", style: UIAlertAction.Style.default, handler:  { (EEDelete) in //Removes whole list
            let ref: DatabaseReference
            ref = Database.database().reference()
            ref.child("list").removeValue()
        }))
        EE.addAction(UIAlertAction(title: "Abbrechen", style: UIAlertAction.Style.default, handler: { (EECancel) in //Abort Action
            EE.dismiss(animated: true, completion: nil)
        }))
         self.present(EE, animated: true, completion: nil)
    }
    func AddITEM (title: String, message: String) { //Adds a item
        let AI = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        AI.addTextField(
            configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "Name"
        })
        AI.addTextField(
            configurationHandler: {(textField: UITextField!) in
                textField.keyboardType = .numberPad
                textField.placeholder = "Menge"
        })
        AI.addAction(UIAlertAction(title: "Hinzufügen", style: UIAlertAction.Style.default, handler: { (AIAdd) in //Adds new item to list
            if let textFields = AI.textFields {
                let theTextFields = textFields as [UITextField]
                var enteredText = theTextFields[0].text
                let enteredAmount = theTextFields[1].text
                let amount = Int(enteredAmount!)
                if enteredText != "" && enteredAmount != "" {
                let ref: DatabaseReference
                ref = Database.database().reference()
                    ref.child("list").observeSingleEvent(of: .value, with: { (IfExistSnapshot) in
                        if IfExistSnapshot.hasChild(enteredText!) {
                        ref.child("list").child(enteredText!).child("Menge").observeSingleEvent(of: .value, with: { (MengeSnap) in
                                let MSLE = MengeSnap.value as! Int
                                let FullMenge = MSLE + amount! //If Entry exists -> Databasevalue + Local value
                                ref.child("list").child(enteredText!).child("Name").setValue(enteredText)
                                ref.child("list").child(enteredText!).child("Menge").setValue(FullMenge){
                                    (error:Error?, ref:DatabaseReference) in
                                    if let error = error {
                                        print("Data could not be saved: \(error).")
                                    } else {
                                        print("Data saved successfully!")
                                    }
                                }
                            
                            
                            })
                        }
                        else {
                            ref.child("list").child(enteredText!).child("Name").setValue(enteredText)
                            ref.child("list").child(enteredText!).child("Menge").setValue(amount){
                                (error:Error?, ref:DatabaseReference) in
                                if let error = error {
                                    print("Data could not be saved: \(error).")
                                } else {
                                   // self.itemNames.removeAll()
                                   // self.itemMenge.removeAll()
                                    //self.ItemList.reloadData()
                                    // ItemList.
                                    //sleep(1)
                                   // self.loadData()
                                    print("Data saved successfully!")
                                }
                            }
                        }
                    })
                    
                    AI.dismiss(animated: true, completion: nil)
                }
            }
            
        }))
        AI.addAction(UIAlertAction(title: "Abbrechen", style: UIAlertAction.Style.default, handler: { (AIdismiss) in //Cancel action and dismiss alert
            AI.dismiss(animated: true, completion: nil)
        }))
        self.present(AI, animated: true, completion: nil)
    }
}
