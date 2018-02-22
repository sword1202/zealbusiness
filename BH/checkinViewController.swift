//
//  checkinViewController.swift
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
class checkinViewController: UIViewController {

    @IBOutlet weak var requestbtn: UIButton!
    @IBOutlet weak var signoutbtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        signoutbtn.layer.cornerRadius=5
        requestbtn.layer.cornerRadius=5
        // Do any additional setup after loading the view.
        
        // take me to StartScreen after 10s
        let when = DispatchTime.now() + 10 
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            self.navigationController?.popViewController(animated: false)
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


    
}
