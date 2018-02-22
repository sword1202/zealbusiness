//
//  AppDelegate.swift
//  BH
//
//  Created by Tafveez Mehdi on 29/01/2017.
//  Copyright © 2017 BH. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth
import SquarePointOfSaleSDK
import SwiftSpinner
import Alamofire

let locationID = "F3EX7FBKDMY0E" // there is an id at the moment
let accessToken = "sq0atp-wXX9R-mHWTTSQtcLhwKQbw"
let headerStr = "Bearer " + accessToken
let headers: HTTPHeaders = [
    "Authorization": headerStr,
    "Accept": "application/json"
]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance().delegate = self
        
        // test Creating Customer in SquareUp
//        self.grabDetailsByLast4Digits(last4digits: "1006")
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        guard let sourceApplication = options[.sourceApplication] as? String else { return false }
        
        guard sourceApplication.hasPrefix("com.squareup.square") else {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
            }
        
        guard let window = window, let rootViewController = window.rootViewController else { return false }
        
        let message: String
        let title: String
        do {
            let response = try SCCAPIResponse(responseURL: url)
            if response.isSuccessResponse {
                title = "Success!"
                message = "Request succeeded: \(response)"
                //

                completedTransactionWithSuccess(transactionId: response.transactionID)
                
                return true
            } else if let errorToPresent = response.error {
                title = "Error!"
                message = "Request failed: \(errorToPresent.localizedDescription)"
            } else {
                fatalError("We should never have received a response with neither a successful status nor an error message.")
            }
        } catch let error as NSError {
            title = "Error!"
            message = "Request failed: \(error.localizedDescription)"
        }
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        rootViewController.present(alertView, animated: true, completion: nil)
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                    sourceApplication: sourceApplication,
                                                    annotation: annotation)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...        
        SwiftSpinner.show("Signing In")
        if let error = error {
            print(error.localizedDescription)
            SwiftSpinner.hide()
            return
        }
        guard let email = user.profile.email else {
                return
        }
        print(email)
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                SwiftSpinner.hide()
                return
            }
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "SignedIn"), object: nil, userInfo: nil))
            
            guard let uid = Auth.auth().currentUser?.uid else {
                    return
            }
            let usersRef = Database.database().reference(withPath: uid)
            usersRef.child("email").setValue(email)
     
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!,
                withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

    func completedTransactionWithSuccess(transactionId: String?){
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "TransactionDone"), object: nil, userInfo: nil))
        
        guard let transactionId = transactionId else {
            return
        }
        
        // find last 4 and store
        
        let urlForTransactionDetails = "https://connect.squareup.com/v2/locations/" + locationID + "/transactions/" + transactionId
        
        Alamofire.request(urlForTransactionDetails, headers: headers).responseJSON { response in
            guard (response.error == nil) else {
//                print(response.error?.localizedDescription)
                return
            }
            let responseObj = response.value as! [String:Any]
            let transaction = responseObj["transaction"] as! NSDictionary
            let tenders = transaction["tenders"] as! NSArray
            let cardDetails = tenders.object(at: 0) as! NSDictionary
            let cardDetail = cardDetails["card_details"] as! NSDictionary
            let card = cardDetail["card"] as! NSDictionary
            let last4 = card["last_4"] as! String
            
            // store
            let startIndex = transactionId.index(transactionId.startIndex, offsetBy: 4)
            let str = String(transactionId[...startIndex])
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd" // 04-22
            let stringFromDate = dateFormatter.string(from: Date())
            let transaction_ = Transaction(transactionId: str, timeStamp: stringFromDate)
            transaction_.addTransactionToFireBase(with: User(uid: "", nameId: last4, emailId: "" ))
            
            // search customer details in database by last4 and create or update customer on Squareup
            self.grabDetailsByLast4Digits(last4digits: last4)
        }
        
    }
    
    func grabDetailsByLast4Digits(last4digits: String?) {
        let databaseReference = Database.database().reference()
        databaseReference.child("consumers").observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.childrenCount > 0 else {
                return
            }
            var userName:String=""
            var userEmail:String=""
            for child in snapshot.children  {
                let snap = child as! DataSnapshot
                let userObj = snap.value as! [String:Any]
                let financialDB = userObj["financial_db"] as? NSDictionary
                for (_, values) in financialDB! {
                    let bankDetailsDic = values as! NSDictionary
                    let accounts = bankDetailsDic["accounts"] as? NSArray
                    let account = accounts?.object(at: 0) as? NSDictionary
                    let consumerCardNumber = account!["mask"] as? String
                    if last4digits == consumerCardNumber {
                        userName = userObj["name"] as! String
                        userEmail = userObj["email"] as! String
                        break
                    }
                }
                
            }
            print(userName, userEmail)
            if userName.elementsEqual("") {
               return
            }
            let fullNameArr = userName.components(separatedBy: " ")
            let firstName: String = fullNameArr[0]
            let lastName: String? = fullNameArr.count > 1 ? fullNameArr[1] : nil
            var param: Parameters? = nil
            param =
                ["given_name"   : firstName,
                 "family_name"  : lastName!,
                 "email_address": userEmail,
                 "note"         : last4digits!]
            
            // check customers from Squareup
            let urlForCustomers = "https://connect.squareup.com/v2/customers"
            
            Alamofire.request(urlForCustomers, headers: headers).responseJSON { response in
                guard (response.error == nil) else {
                    return
                }
                
                let responseObj = response.value as! [String:Any]
                let customers = responseObj["customers"] as! NSArray
                var isExist = false
                for (_, element) in customers.enumerated() {
                    let customer           = element                    as? NSDictionary
                    let customer_firstName = customer!["given_name"]    as? String
                    let customer_lastName  = customer!["family_name"]   as? String
                    let customer_email     = customer!["email_address"] as? String
                    let customer_id        = customer!["id"]            as? String
                    
                    if firstName == customer_firstName && lastName == customer_lastName &&
                        userEmail == customer_email {
                        isExist = true
                        
                        self.handleCustomerWithSquareup(isExist: true, param: param!, customerID: customer_id!)
                        break
                    }
                }
                
                if !isExist {
                    self.self.handleCustomerWithSquareup(isExist: false, param: param!, customerID: "")
                }
            }
            
        }
    }
    
    func handleCustomerWithSquareup(isExist: Bool, param: Parameters, customerID: String)
    {
        let url = isExist ? "https://connect.squareup.com/v2/customers/" + customerID: "https://connect.squareup.com/v2/customers"
        let httpmethod:HTTPMethod? = isExist ? .put : .post
        Alamofire.request(url, method: httpmethod!, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            guard (response.error == nil) else {
                return
            }

            if isExist {
                print("updated successfully.")
            } else
            {
                print("created successfully.")
            }
            
        }
        
    }
}

