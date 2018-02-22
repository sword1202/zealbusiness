//
//  ViewController.swift
//  BH
//
//  Created by Tafveez Mehdi on 29/01/2017.
//  Copyright © 2017 BH. All rights reserved.
//

import UIKit
import SquarePointOfSaleSDK
import Firebase
import GoogleSignIn
import FirebaseDatabase
import SwiftSpinner

//let yourClientID = "sq0idp-EGZH_3HkuU5djPZvFoJJyw"
//let yourClientID = "sandbox-sq0idp-EGZH_3HkuU5djPZvFoJJyw"
//let yourCallbackURL = URL(string: "bhdesign://callback")!
//
//let allTenderTypes: [SCCAPIRequestTenderTypes] = [.card, .cash, .other, .squareGiftCard, .cardOnFile]


class ViewController: UIViewController {

    var supportedTenderTypes: SCCAPIRequestTenderTypes = .card
    var clearsDefaultFees = false
    var returnAutomaticallyAfterPayment = true
    var transactions = [Transaction]()
    
    
    @IBAction func signoutDidClick(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func requestDidClick(_ sender: Any) {
        charge()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        SCCAPIRequest.setClientID(yourClientID)
   
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDone), name: NSNotification.Name(rawValue: "TransactionDone"), object: nil)

        showPOSLoginAlertIfFirstLogin()
//        getTransactions(for: User(uid: uid, emailId: email))
   
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func transactionDone(){
        
    }
    
    func addTransactionToDatabase(with user: User, transaction: Transaction){
        transaction.addTransactionToFireBase(with: user)
    }
    
   
  
    func oAuth(){
        guard let oauthURL = URL(string: "https://squareup.com/oauth2/authorize?client_id=\(yourClientID)&scope=PAYMENTS_WRITE&response_type=token") else {
            return
        }
        
       
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(oauthURL, options: [:]) { (result) in
                print(result)}
        } else {
            // Fallback on earlier versions
        }
        
    }


    func charge() {
        
        let amount: SCCMoney
        guard let amountCents = Int("100") else {
//            showErrorMessage(title: "Invalid Amount", message: "\(amountString) is not a valid amount.")
            return
        }
        
        do {
            amount = try SCCMoney(amountCents: amountCents, currencyCode: "USD")
        } catch let error as NSError {
            showErrorMessage(title: "Invalid Amount", error: error)
            return
        }
        
        let userInfoString: String? = nil//userInfoStringField.text?.nilIfEmpty
        let merchantID: String? = nil//merchantIDField.text?.nilIfEmpty
        let customerID: String? = nil//customerIDField.text?.nilIfEmpty
        let notes: String? = nil//notesField.text?.nilIfEmpty
        
        let request: SCCAPIRequest
        do {
            request = try SCCAPIRequest(callbackURL: yourCallbackURL,
                                        amount: amount,
                                        userInfoString: userInfoString,
                                        merchantID: merchantID,
                                        notes: notes,
                                        customerID: customerID,
                                        supportedTenderTypes: supportedTenderTypes,
                                        clearsDefaultFees: clearsDefaultFees,
                                        returnAutomaticallyAfterPayment: returnAutomaticallyAfterPayment)
        } catch let error as NSError {
            showErrorMessage(title: "Invalid Amount", error: error)
            return
        }
        
        do {
            try SCCAPIConnection.perform(request)
        } catch let error as NSError {
            showErrorMessage(title: "Cannot Perform Request", error: error)
            return
        }
    }
    
    private func showErrorMessage(title: String, error: NSError) {
        showErrorMessage(title: title, message: error.localizedDescription)
    }
    
    private func showErrorMessage(title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alertView, animated: true, completion: nil)
    }

    private func showPOSLoginAlertIfFirstLogin() {
        let hasFirstLoggedIn = UserDefaults.standard.bool(forKey: "hasFirstLoggedIn")
        if !hasFirstLoggedIn {
            UserDefaults.standard.set(true, forKey: "hasFirstLoggedIn")
            let alertController = UIAlertController(title: "Important!",
                                                   message: "Please install Square POS app from App Store and sign in using Square Account, before requesting any transaction using this app!",
                                                   preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Got it!", style: .default, handler: { (action) in
                //
            })
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func getTransactions(for user: User){
        let usersRef = Database.database().reference(withPath: "users")
        guard let uid = user.uid else {
            return
        }
        SwiftSpinner.show("Loading...")
        usersRef.child(uid).child("transactions").observe(.value, with: { (snapshot) in
            var transactions = [Transaction]()
            for transactionSnapshot in snapshot.children {
                let transaction = Transaction(transactionSnapshot: transactionSnapshot as! DataSnapshot)
                transactions.append(transaction)
            }
            self.transactions = transactions
       
            SwiftSpinner.hide()
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell")!
        let nameLabel = cell.viewWithTag(1122) as! UILabel
        let timeLabel = cell.viewWithTag(2244) as! UILabel
        nameLabel.text = self.transactions[indexPath.row].transactionId
        timeLabel.text = self.transactions[indexPath.row].timeStamp
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = UIColor(hex: "#e3e3e3")
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")!
        return headerCell
    }
}




