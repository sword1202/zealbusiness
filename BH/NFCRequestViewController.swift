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
import Alamofire

//// FIXME: Replace this with the Application ID found in the Square Application Dashboard [https://connect.squareup.com/apps].
let client_id = "sq0idp-EGZH_3HkuU5djPZvFoJJyw"
let callback_url = URL(string: "bhdesign://callback")!

let allTenderTypes: [SCCAPIRequestTenderTypes] = [.card, .cash, .other, .squareGiftCard, .cardOnFile]


class NFCRequestViewController: UIViewController {
    
    
    var supportedTenderTypes: SCCAPIRequestTenderTypes = .card
    var clearsDefaultFees = false
    var returnAutomaticallyAfterPayment = true
    var transactions = [Transaction]()
    var ordersArray = NSMutableArray()
    var failedCount = Int()
    var customerid     = String()
    var cardid         = String()
    var isExistCard    = Bool()
    var isSuccess      = Bool()
    let myGroup = DispatchGroup()
    
    var successMsg = String()
    
    var customerArr = NSArray()
    var customerID = String()
    var cardID = String()
    
    var totalAmount = Int(0)

    @IBOutlet weak var signoutbtn: UIButton!

    @IBOutlet weak var homebtn: UIButton!
    @IBOutlet weak var requestbtn: UIButton!
    @IBOutlet weak var uv_instruction: UIView!
    @IBOutlet weak var uv_mainView: UIView!
    @IBOutlet weak var label_clickstart: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uv_instruction.isHidden = true
        signoutbtn.layer.cornerRadius=5
        requestbtn.layer.cornerRadius=5
        homebtn.layer.cornerRadius=5
        
        
        SCCAPIRequest.setClientID(client_id)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDone), name: NSNotification.Name(rawValue: "TransactionDone"), object: nil)

        showPOSLoginAlertIfFirstLogin()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isSuccess = false
        
        // test
//        if currentCardsNum != "" {
//            // select cards
//
//            findOrdersByCardNumber()
//
//        }
    }
    
    @objc func transactionDone(){
        if currentCardsNum != "" {
            // select cards
            
            findOrdersByCardNumber()
            
        } else{
            afterTransaction()
        }
    }
    
    func afterTransaction() {
        requestbtn.isEnabled = true
        requestbtn.alpha = 1.0
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "checkinViewController") as! checkinViewController
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        
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
        
        // make test charge
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
        
        currentCardsNum = ""
        
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
//        let merchantID: String? = location_ID//merchantIDField.text?.nilIfEmpty
        let customerID: String? = nil//customerIDField.text?.nilIfEmpty
        let notes: String? = "Test Charge"//notesField.text?.nilIfEmpty
        
        var request: SCCAPIRequest
        do {
            request = try SCCAPIRequest(callbackURL                    : callback_url,
                                        amount                         : amount,
                                        userInfoString                 : userInfoString,
                                        locationID                     : location_ID,
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
    
    func findOrdersByCardNumber() {
        // find orders for selected card number
        
        let ordersRef = Database.database().reference(withPath: "orders").child(currentCardsNum)
        
        ordersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if !snapshot.exists() {
                // no orders yet
                self.showToast(message: "There is no orders for \(currentCardsNum) yet.")
                return
            }
            
            self.ordersArray = (snapshot.value as? NSMutableArray)!
            
            self.findCustomerbyCard()
            
        }) { (error) in print(error.localizedDescription) }
    }
    
    func findCustomerbyCard() {
        isExistCard = false
        
        let customersRef = Database.database().reference(withPath: "customers")
        customersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                self.customerArr = (snapshot.value as? NSArray)!
                self.handleCustomers()
                if !self.isExistCard {
                    self.noCard()
                } else
                {
                    self.chargeForOder()
                    self.isExistCard = false
                }
                
            } else
            {
                self.noCard()
            }
        })
    }
    
    func noCard() {
        showToast(message: "There is no card resource in Customers.")
        requestbtn.isEnabled = true
        requestbtn.alpha = 1.0
        return
    }
    
    func handleCustomers() {
        // find customerid and card id for selectedbank last 4 digits
        for i in 0 ..< customerArr.count {
            let everyCustomerDic = customerArr.object(at: i) as? NSDictionary
            
            if let cardsArr = everyCustomerDic?.object(forKey: "cards") as? NSArray {
                customerID = everyCustomerDic?.object(forKey: "id") as! String
                for j in 0 ..< cardsArr.count {
                    let everyCard = cardsArr.object(at: j) as? NSDictionary
                    cardid = everyCard?.object(forKey: "id") as! String
                    let last4digits = everyCard?.object(forKey: "last_4") as? String
                    if last4digits == currentCardsNum {
                        // charge
                        print("Cardid: \(cardid) Customerid: \(customerID)")
                        
                        isExistCard = true
                        break
                    }
                }
            }
        }
    }
    
    func chargeForOder() {
        // start charge with the order
        
        let msg = ordersArray.count > 1 ? "Charging Orders ..." : "Charging Order ..."
        SwiftSpinner.show(msg)
        
        failedCount = 0
        
        for i in 0 ..< ordersArray.count {
            
            let selectedOrderDic = ordersArray[i] as? NSDictionary
            
            let orderId = selectedOrderDic!["id"] as! String
//            let locationid = selectedOrderDic!["location_id"] as! String
            let amountMoneyDic = selectedOrderDic!["total_money"] as! NSDictionary
           
            let lineItems = selectedOrderDic!["line_items"] as? NSArray
            let lineItem0 = lineItems![0] as? NSDictionary
            let itemName = lineItem0!["name"] as? String
            
            let note = "\(itemName!)  Order"

            let params: [String:Any] = [
                "idempotency_key": randomString(length: 40),
                "order_id"       : orderId,
                "amount_money"   : amountMoneyDic,
                "customer_card_id": cardid,
                "customer_id"    : customerID,
                "note"           : note
            ]
            
            let urlStr = "https://connect.squareup.com/v2/locations/\(location_ID)/transactions"
       
            myGroup.enter()
            //
            // send request to make transaction
            self.sendRequest(urlStr: urlStr, params: params, atIndex: i)
            
        }
        
        myGroup.notify(queue: .main) {
            SwiftSpinner.hide()
            if self.isSuccess {
                self.showToast(message: self.successMsg)
                self.updateOrdersDB()
                self.afterTransaction()
            } else
            {
                self.showToast(message: "Something went wrong.")
                self.requestbtn.isEnabled = true
                self.requestbtn.alpha = 1.0
            }
            
        }
        
    }
    
    func sendRequest(urlStr: String, params: Parameters, atIndex: Int) {
        do {
            let postData = try JSONSerialization.data(withJSONObject: params, options: [])
            
            let request = NSMutableURLRequest(url: NSURL(string: urlStr)! as URL,
                                              cachePolicy: .useProtocolCachePolicy,
                                              timeoutInterval: 30.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData as Data
            
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    print(error ?? "")
                    self.failedCount += 1
                } else {
                    let httpResponse = response as? HTTPURLResponse
                    print(httpResponse ?? "")
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
                        print("---success \(atIndex)---")
                        self.ordersArray.removeObject(at: self.failedCount)
                        self.isSuccess = true
                        self.successMsg = "Success"
                        
                        print(json ?? "")
                        // store transaction in firebase
                        
                    }catch(let e){
                        print(e)
                    }
                }
                
                self.myGroup.leave()
            })
            
            dataTask.resume()            //
        }catch (let i) {
            print(i)
        }
    }
    
    func updateOrdersDB() {
        
        let ordersRef = Database.database().reference(withPath: "orders").child(currentCardsNum)
        ordersRef.setValue(ordersArray)
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: 100, y: self.view.frame.size.height-100, width: self.view.frame.size.width - 200, height: 80))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 30)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 20;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
