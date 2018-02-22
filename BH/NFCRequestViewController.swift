//
//  signoutrequestViewController.swift
//  BH
//
//  Created by Rainbow on 4/11/17.
//  Copyright © 2017 BH. All rights reserved.
//

import UIKit
import SquarePointOfSaleSDK
import Firebase
import GoogleSignIn
import FirebaseDatabase
import SwiftSpinner

//// FIXME: Replace this with the Application ID found in the Square Application Dashboard [https://connect.squareup.com/apps].
let yourClientID = "sq0idp-EGZH_3HkuU5djPZvFoJJyw"

// let yourClientID = "sandbox-sq0idp-EGZH_3HkuU5djPZvFoJJyw" // commerce-v2
// FIXME: Replace with your app's callback URL as set in the Square Application Dashboard [https://connect.squareup.com/apps]
// You must also declare this URL scheme in HelloCharge-Swift-Info.plist, under URL types.
let yourCallbackURL = URL(string: "bhdesign://callback")!

let allTenderTypes: [SCCAPIRequestTenderTypes] = [.card, .cash, .other, .squareGiftCard, .cardOnFile]


class NFCRequestViewController: UIViewController {
    
    
    var supportedTenderTypes: SCCAPIRequestTenderTypes = .card
    var clearsDefaultFees = false
    var returnAutomaticallyAfterPayment = true
    var transactions = [Transaction]()

    @IBOutlet weak var signoutbtn: UIButton!

    @IBOutlet weak var homebtn: UIButton!
    @IBOutlet weak var requestbtn: UIButton!
    @IBOutlet weak var uv_instruction: UIView!
    @IBOutlet weak var uv_mainView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uv_instruction.isHidden = true;
        signoutbtn.layer.cornerRadius=5
        requestbtn.layer.cornerRadius=5
        homebtn.layer.cornerRadius=5
        
        
        SCCAPIRequest.setClientID(yourClientID)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDone), name: NSNotification.Name(rawValue: "TransactionDone"), object: nil)
//        guard let uid = FIRAuth.auth()?.currentUser?.uid, let email = FIRAuth.auth()?.currentUser?.email else {
//            return
//        }
        showPOSLoginAlertIfFirstLogin()
        
//        getTransactions(for: User(uid: uid, emailId: email))
        

        // Do any additional setup after loading the view.
    }
    
    @objc func transactionDone(){
        requestbtn.isEnabled = true
        requestbtn.alpha = 1.0
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "checkinViewController") as! checkinViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func homebtnclicked(_ sender: AnyObject) {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "checkinViewController") as! checkinViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    @IBAction func requestbtnClicked(_ sender: AnyObject) {
        
        uv_instruction.isHidden = false
        requestbtn.isEnabled = false
        requestbtn.alpha = 0.3
        let when = DispatchTime.now() + 4
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            // process of squareup transaction here
            
            self.charge();
        }
        
        
    }

    @IBAction func signoutbtnclicked(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    func charge() {
        
        let amount: SCCMoney
        guard let amountCents = Int("100") else {
            //            showErrorMessage(title: "Invalid Amount", message: "\(amountString) is not a valid amount.")
            requestbtn.isEnabled = true
            requestbtn.alpha = 1.0
            return
        }
        
        do {
            amount = try SCCMoney(amountCents: amountCents, currencyCode: "USD")
        } catch let error as NSError {
            showErrorMessage(title: "Invalid Amount", error: error)
            requestbtn.isEnabled = true
            requestbtn.alpha = 1.0
            return
        }
        
        let userInfoString: String? = "Useful information"//userInfoStringField.text?.nilIfEmpty
        let merchantID: String? = nil//merchantIDField.text?.nilIfEmpty
        let customerID: String? = nil//customerIDField.text?.nilIfEmpty
        let notes: String? = "Notes"//notesField.text?.nilIfEmpty
        
        var request: SCCAPIRequest
        do {
            request = try SCCAPIRequest(callbackURL                    : yourCallbackURL,
                                        amount                         : amount,
                                        userInfoString                 : userInfoString,
                                        locationID                     : merchantID,
                                        notes                          : notes,
                                        customerID                     : customerID,
                                        supportedTenderTypes           : supportedTenderTypes,
                                        clearsDefaultFees              : clearsDefaultFees,
                                        returnAutomaticallyAfterPayment: returnAutomaticallyAfterPayment)
        } catch let error as NSError {
            showErrorMessage(title: "Invalid Amount", error: error)
            requestbtn.isEnabled = true
            requestbtn.alpha = 1.0
            return
        }
        
        do {
            try SCCAPIConnection.perform(request)
        } catch let error as NSError {
            showErrorMessage(title: "Cannot Perform Request", error: error)
            requestbtn.isEnabled = true
            requestbtn.alpha = 1.0
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
