//
//  Transaction.swift
//  BH
//
//  Created by Tafveez Mehdi on 05/03/2017.
//  Copyright © 2017 BH. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Transaction {
    
    var transactionId: String?
    var timeStamp: String?
    
    init(transactionId: String, timeStamp: String){
        
        self.transactionId = transactionId
        self.timeStamp = timeStamp
    }
    
    init(transactionSnapshot: DataSnapshot){
        self.transactionId = transactionSnapshot.key
        let timeStampDict = transactionSnapshot.value as! [String:Any]
        self.timeStamp = timeStampDict["timeStamp"] as? String
    }
    
    func addTransactionToFireBase(with user: User) {

        let usersRef = Database.database().reference(withPath: "business_transactions")
        let dateFormatter = DateFormatter()
        let card_number = user.nameId
        dateFormatter.dateFormat = "MM-dd"
        let stringFromDate = dateFormatter.string(from: Date())

        usersRef.child(self.transactionId!).child("timeStamp").setValue(stringFromDate)
        usersRef.child(self.transactionId!).child("card_number").setValue(card_number)
    }
    
}
