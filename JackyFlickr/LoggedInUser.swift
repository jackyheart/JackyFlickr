//
//  LoggedInUser.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 24/1/17.
//
//

import UIKit

class LoggedInUser: NSObject {

    static let shared = LoggedInUser()//singleton
    var oauthToken:String = ""
    var oauthTokenSecret:String = ""
    var userID:String = ""
    var username:String = ""
    var fullname:String = ""
    
    func clear() {
    
        LoggedInUser.shared.oauthToken = ""
        LoggedInUser.shared.oauthTokenSecret = ""
        LoggedInUser.shared.userID = ""
        LoggedInUser.shared.username = ""
        LoggedInUser.shared.fullname = ""
    }
}
