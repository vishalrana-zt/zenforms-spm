//
//  EndPointType.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation

protocol FPEndPointType {
    var baseURL: URL { get }
    var path: String { get }
    var httpMethod: FPHTTPMethod { get }
    var task: FPHTTPTask { get }
    var headers: FPHTTPHeaders? { get }
    var fpLoggerModal: FPLoggerModal? { get }
}


