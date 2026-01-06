//
//  HTTPTask.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation

typealias FPHTTPHeaders = [String: String]

enum FPHTTPTask {
    case request
    
    case requestParameters(parameters: FPParameters?,
        bodyEncoding: FPParameterEncoding)
    
    case requestParametersAndHeaders(parameters: FPParameters?,
        bodyEncoding: FPParameterEncoding,
        additionHeaders: FPHTTPHeaders?)
}
