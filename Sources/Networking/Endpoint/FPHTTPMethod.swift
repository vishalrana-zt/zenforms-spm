//
//  HTTPMethod.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation


enum FPHTTPMethod: Int {
    case post = 0
    case get
    case put
    case delete
    func name() -> String {
        switch self {
        case .post: return "POST"
        case .get: return "GET"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
}

