//
//  GarageControl.swift
//  GarageControl
//
//  Created by Mathieu Clement on 10/5/15.
//  Copyright © 2015 Mathieu Clement. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class GarageControl {
    
    let WEBAPP_URL = "https://YOUR-SERVER/garage/"
    
    func sendCmd(cmd:String, onSuccess: (() -> Void)? = nil, onFailure: (() -> Void)? = nil) {
        Alamofire.request(.GET, self.WEBAPP_URL,
            headers: [
                "Authorization": "Basic XXXXXX==",
                "User-Agent": "GarageControl 0.1 for iOS"
            ],
            parameters: [
                "command": cmd,
                "phone": "+41791234567",
                "account": "email@here.com"
            ])
            .validate()
            .responseJSON { (request,response,result) in
                if result.isSuccess {
                    if onSuccess != nil {
                        onSuccess!()
                    }
                } else {
                    if onFailure != nil {
                        onFailure!()
                    }
                }
        }
    }
    
    func askIfDoorOpened(onSuccess: ((Bool) -> Void), onFailure: (()-> Void)? = nil) {
        Alamofire.request(.GET, self.WEBAPP_URL + "status.php",
            headers: [
                "Authorization": "Basic XXXXXXXXx==",
                "User-Agent": "GarageControl 0.1 for iOS"
            ])
            .validate()
            .responseJSON { (request,response,result) in
                if result.isSuccess {
                    let json = JSON(result.value!)
                    let isOpened = json["opened"].boolValue
                    onSuccess(isOpened)
                } else {
                    if onFailure != nil {
                        onFailure!()
                    }
                }
        }
    }
}
