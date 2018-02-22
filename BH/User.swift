//
//  User.swift
//  BH
//
//  Created by Tafveez Mehdi on 05/03/2017.
//  Copyright © 2017 BH. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class User {
    
    var uid: String?
    var nameId: String?
    var emailId: String?
    var transactions: [Transaction]?
    
    init(uid: String, nameId: String, emailId: String){
        self.uid = uid
        self.nameId = nameId
        self.emailId = emailId
    }
    
    class func addUserToFirebase(with user: User) {
        let usersRef = Database.database().reference(withPath: "users")
        usersRef.child(user.uid!).child("uid").setValue(user.uid)
        usersRef.child(user.uid!).child("name").setValue(user.nameId)
        usersRef.child(user.uid!).child("email").setValue(user.emailId)
    }
}
