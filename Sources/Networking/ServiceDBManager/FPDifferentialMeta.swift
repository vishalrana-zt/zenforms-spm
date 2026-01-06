//
//  FPDifferentialMeta.swift
//  ZenFormsLib
//
//  Created by apple on 13/08/24.
//

import Foundation
@objcMembers class FPDifferentialMeta:NSObject {
    var apiName = ""
    var payload = ""
    var updatedAt = ""
    var isFetching : Bool = false
    var pageCount = ""
    override init() {
        
    }
    init(dict:[String:Any]) {
        self.apiName = FPUtility.getStringValue(dict["apiName"]) ?? ""
        self.payload = FPUtility.getStringValue(dict["payload"]) ?? ""
        self.updatedAt = FPUtility.getStringValue(dict["updatedAt"]) ?? ""
        self.isFetching = dict["isFetching"] as? Bool ?? false
        self.pageCount = FPUtility.getStringValue(dict["pageCount"]) ?? ""
    }
    
}
