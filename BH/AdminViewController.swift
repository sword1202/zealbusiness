//
//  adminViewController.swift
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

class AdminViewController: UIViewController
{

    @IBOutlet weak var signoutbtn: UIButton!
    @IBOutlet weak var requestbtn: UIButton!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet var title_view: UIView!
    @IBOutlet var noTableViewLabel: UILabel!
    
    var supportedTenderTypes: SCCAPIRequestTenderTypes = .card
    var clearsDefaultFees = false
    var returnAutomaticallyAfterPayment = true
    var transactions=[Transaction]()
    var everyUser:User?
    var userNameArray:NSMutableArray = NSMutableArray()
    var userEmailArray:NSMutableArray = NSMutableArray()
    var u_id: String?
    var uid: String?
    var userName: String?
    var userEmail: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SCCAPIRequest.setClientID(client_id)
        tableview.delegate = self
        tableview.dataSource = self
        
        SwiftSpinner.show("Loading...")
        
        getFirebase()

    }
    
    func getFirebase()
    {
        guard (Auth.auth().currentUser?.uid) != nil else {
            return
        }
        uid = Auth.auth().currentUser?.uid
//        uid = "EGSKXZWM3COl253jke9bi5eCzSI3" // test mode
        Database.database().reference(withPath: uid!).observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                
                let userId = snapshot.value as! [String:Any]
                //                    self.userEmail = userId["email"] as? String
                self.userName = userId["name"] as? String
                self.userEmail = userId["email"] as? String
                self.everyUser = User(uid: self.uid!, nameId: self.userName!, emailId: self.userEmail!)
                let dicTransaction = userId["business_transactions"] as! NSDictionary
                for transactionkey in dicTransaction.allKeys {
                    let transactionValue = dicTransaction[transactionkey] as! NSDictionary
                    let timeStamp:String! = transactionValue["timeStamp"] as! String
                    let transaction = Transaction(transactionId: transactionkey as! String, timeStamp: timeStamp)
                    self.transactions.append(transaction)
                    self.userNameArray.add(self.everyUser?.nameId as Any)
                    self.userEmailArray.add(self.everyUser?.emailId as Any)
                }
                
                if self.transactions.count == 0
                {
                    self.tableview.isHidden = true
                    self.title_view.isHidden = true
                    self.noTableViewLabel.isHidden = false
                    SwiftSpinner.hide()
                } else
                {
                    self.tableview.isHidden = false
                    self.title_view.isHidden = false
                    self.noTableViewLabel.isHidden = true
                    DispatchQueue.main.async {
                        self.tableview.reloadData()
                        SwiftSpinner.hide()
                    }
                }
                
                
            } else {
                print("no results")
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func signoutclicked(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.navigationController?.popToRootViewController(animated: true)

    }
    @IBAction func requestbtnclicked(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func showErrorMessage(title: String, error: NSError) {
        showErrorMessage(title: title, message: error.localizedDescription)
    }
    
    private func showErrorMessage(title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alertView, animated: true, completion: nil)
    }
    
    func addTransactionToDatabase(with user: User, transaction: Transaction){
        transaction.addTransactionToFireBase(with: user)
    }
    
    func oAuth(){
        guard let oauthURL = URL(string: "https://squareup.com/oauth2/authorize?client_id=\(client_id)&scope=PAYMENTS_WRITE&response_type=token") else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(oauthURL, options: [:]) { (result) in
                print(result)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
}
extension AdminViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "customcell")! as! TableViewCell
        
        cell.transactionid.text = self.transactions[indexPath.row].transactionId
        cell.date.text = self.transactions[indexPath.row].timeStamp
        cell.name.text = self.userNameArray.object(at: indexPath.row) as? String
        cell.mail.text = self.userEmailArray.object(at: indexPath.row) as! String
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = UIColor(hex: "#e3e3e3")
        }
        return cell
    }
    
  
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
    
  
}

