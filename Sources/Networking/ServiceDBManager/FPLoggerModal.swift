//
//  FPLoggerModal.swift
//  crm
//
//  Created by SmartServ-Pooja on 8/3/21.
//  Copyright © 2021 SmartServ. All rights reserved.
//

import UIKit
struct FPMasker {
    let primaryKey:String!
    let secondaryKey:String!
}
class FPLoggerModal: NSObject {
    var serviceName: String = ""
    var loggerName: String = ""
    var message: String = ""
    var attributes: [String:Any]?
    
    var error: Error?
    func setLoger(_ loggerName: String) -> FPLoggerModal {
        self.loggerName = loggerName
        return self
    }
}
