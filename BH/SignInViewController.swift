//
//  SignInViewController.swift
//  BH
//
//  Created by Tafveez Mehdi on 13/02/2017.
//  Copyright © 2017 BH. All rights reserved.
//

import UIKit
import GoogleSignIn
import SwiftSpinner

class SignInViewController: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var gmailSignInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        gmailSignInButton.addTarget(self, action: #selector(didClickSignInButton(sender:)), for: .touchUpInside)

        NotificationCenter.default.addObserver(self, selector: #selector(didSignIn), name: NSNotification.Name(rawValue: "SignedIn"), object: nil)
    }

    @objc func didSignIn(){
        SwiftSpinner.hide()
//        performSegue(withIdentifier: "ListVCSegue", sender: self)
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "signoutrequestViewController") as! NFCRequestViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func didClickSignInButton(sender: UIButton){
        
        GIDSignIn.sharedInstance().signIn()
    }
}
