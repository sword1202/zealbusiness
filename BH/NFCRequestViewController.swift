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
let yourClientID = "sq0idp-EGZH_3HkuU5djPZvFoJJyw"

// let yourClientID = "sandbox-sq0idp-EGZH_3HkuU5djPZvFoJJyw" // commerce-v2
// FIXME: Replace with your app's callback URL as set in the Square Application Dashboard [https://connect.squareup.com/apps]
// You must also declare this URL scheme in HelloCharge-Swift-Info.plist, under URL types.
let yourCallbackURL = URL(string: "bhdesign://callback")!

let allTenderTypes: [SCCAPIRequestTenderTypes] = [.card, .cash, .other, .squareGiftCard, .cardOnFile]


class NFCRequestViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var supportedTenderTypes: SCCAPIRequestTenderTypes = .card
    var clearsDefaultFees = false
    var returnAutomaticallyAfterPayment = true
    var transactions = [Transaction]()
    var ordersArray = NSArray()
    var orderPickerData = NSMutableArray()
    var selectedOrderRow = Int(0)
    var isSelectedBank = Bool()
    var customerid     = String()
    var cardid         = String()
    var isExistCard    = Bool()
    
    var customerArr = NSArray()
    var customerID = String()
    var cardID = String()

    @IBOutlet weak var signoutbtn: UIButton!

    @IBOutlet weak var orderPicker: UIPickerView!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var homebtn: UIButton!
    @IBOutlet weak var requestbtn: UIButton!
    @IBOutlet weak var uv_instruction: UIView!
    @IBOutlet weak var uv_mainView: UIView!
    @IBOutlet weak var label_clickstart: UILabel!
    @IBOutlet weak var pickercontainer: UIView!
    @IBOutlet weak var done_pickerviewbtn: UIButton!
    @IBOutlet weak var selectedBankLabel: UILabel!
    @IBOutlet weak var selectedOrderLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uv_instruction.isHidden = true
        signoutbtn.layer.cornerRadius=5
        requestbtn.layer.cornerRadius=5
        homebtn.layer.cornerRadius=5
        
        self.picker.delegate = self
        self.picker.dataSource = self
        
        SCCAPIRequest.setClientID(yourClientID)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDone), name: NSNotification.Name(rawValue: "TransactionDone"), object: nil)
//        guard let uid = FIRAuth.auth()?.currentUser?.uid, let email = FIRAuth.auth()?.currentUser?.email else {
//            return
//        }
        showPOSLoginAlertIfFirstLogin()
        
//        getTransactions(for: User(uid: uid, emailId: email))
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        requestbtn.isEnabled = false
        requestbtn.alpha = 0.3
        label_clickstart.isHidden = true
        pickercontainer.isHidden = true
        orderPicker.isHidden = true
        picker.isHidden = false
        
        selectedBankLabel.text = ""
        selectedOrderLabel.text = ""
        
        let cardsRef = Database.database().reference(withPath: "cards").child(deviceuidString)
        
        cardsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.requestbtn.isEnabled = true
            self.requestbtn.alpha = 1.0
            self.label_clickstart.isHidden = false
            
            if !snapshot.exists() {
                return
            }
            
            cardsForThisDevice = (snapshot.value as? NSMutableArray)!
            self.picker.reloadAllComponents()
            
        }) { (error) in print(error.localizedDescription) }
    }
    
    @objc func transactionDone(){
        afterTransaction()
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
        
        if cardsForThisDevice.count > 0 {
            // select cards
            isSelectedBank = false
            pickercontainer.isHidden = false
            selectedBankLabel.text = cardsForThisDevice[0] as? String
            
            done_pickerviewbtn.setTitle("Continue", for: .normal)
            
        } else
        {
            // make test charge
            let when = DispatchTime.now() + 4
            DispatchQueue.main.asyncAfter(deadline: when) {
                
                // process of squareup transaction here
                
                self.charge();
            }
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
        let notes: String? = "Test Charge"//notesField.text?.nilIfEmpty
        
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
    
    //MARK:- UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 2 {
            return orderPickerData.count
        }
        return cardsForThisDevice.count
    }
    
    //MARK:- UIPickerViewDelegates methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if pickerView.tag == 2
        {
            return orderPickerData[row] as? String
        } else {
            return cardsForThisDevice[row] as? String
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 2
        {
            selectedOrderLabel.text = orderPickerData[row] as? String
            selectedOrderRow = row
            
        } else {
            selectedBankLabel.text = cardsForThisDevice[row] as? String
        }
//        print(cardsForThisDevice.object(at: row))
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "Courier New", size: 50)
            pickerLabel?.textAlignment = .center
//            print(UIFont.familyNames)
        }
        
        if pickerView.tag == 2 {
            pickerLabel?.text = orderPickerData[row] as? String
        } else {
            pickerLabel?.text = cardsForThisDevice[row] as? String
        }
        
        pickerLabel?.textColor = UIColor.white
        
        return pickerLabel!
    }
    
    @IBAction func didSelectDone(_ sender: Any) {
        if !isSelectedBank {
            
            // find orders for selected card number
            
            let ordersRef = Database.database().reference(withPath: "orders").child(selectedBankLabel.text!)
            
            ordersRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                if !snapshot.exists() {
                    // no orders yet
                    self.showToast(message: "There is no orders for " + self.selectedBankLabel.text! + " yet.")
                    return
                }
                
                self.ordersArray = (snapshot.value as? NSArray)!
                
                for i in 0 ..< self.ordersArray.count {
                    let everyOrderDic = self.ordersArray[i] as? NSDictionary
                    
                    let lineItems = everyOrderDic!["line_items"] as? NSArray
                    let lineItem0 = lineItems![0] as? NSDictionary
                    let itemName = lineItem0!["name"] as? String
                    self.orderPickerData.add(itemName ?? "")
                    
                }
                
                self.selectedOrderLabel.text = self.orderPickerData[0] as? String

                self.picker.isHidden = true
                
                self.orderPicker.delegate = self
                self.orderPicker.dataSource = self
                
                self.orderPicker.isHidden = false
                
                self.selectedOrderRow = 0
                
                self.done_pickerviewbtn.setTitle("Charge", for: .normal)
                self.isSelectedBank = true
                
                
            }) { (error) in print(error.localizedDescription) }
            
        } else
        {
            isExistCard = false
            
            let customersRef = Database.database().reference(withPath: "customers")
            customersRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        self.customerArr = (snapshot.value as? NSArray)!
                        self.handleCustomers()
                        if !self.isExistCard {
                            self.noCard()
                        }
                        
                        self.chargeForOder()
                        
                    } else
                    {
                        self.noCard()
                    }
                })
            
        }
    }
    
    func noCard() {
        showToast(message: "There is no card resource in Customers.")
        pickercontainer.isHidden = true
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
                    if last4digits == selectedBankLabel.text {
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
        let selectedOrderDic = ordersArray[selectedOrderRow] as? NSDictionary
        
        let orderId = selectedOrderDic!["id"] as! String
        let locationid = selectedOrderDic!["location_id"] as! String
        let amountMoneyArray = selectedOrderDic!["total_money"] as! NSDictionary
 
        let itemName = orderPickerData[selectedOrderRow] as! String
        let note = "\(itemName)  Order"
        
        // get customer_card_id and customer_id
        
        let parameters: Parameters = [
            "idempotency_key": randomString(length: 40),
            "order_id"       : orderId,
            "amount_money"   : amountMoneyArray,
            "customer_card_id": cardid,
            "customer_id"    : customerID,
            "note"           : note
        ]
        
        let urlForcharge = "https://connect.squareup.com/v2/locations/" + locationid + "/transactions"
        
        Alamofire.request(urlForcharge, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            guard (response.error == nil) else {
                self.showToast(message: (response.error?.localizedDescription)!)
                return
            }
            
            let responseObj = response.value as! [String:Any]
            self.showToast(message: "Charge Success!")
            self.afterTransaction()
            
        }
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
