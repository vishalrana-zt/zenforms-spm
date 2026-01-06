//
//  JSONParameterEncoder.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation

struct FPJSONParameterEncoder: FPParameterEncoder {

    func setContentType(urlRequest: inout URLRequest) {
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }

    func encode(urlRequest: inout URLRequest, with parameters: FPParameters) throws {
        do {
            let jsonAsData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = jsonAsData
        } catch {
            throw FPNetworkError.encodingFailed
        }
    }
}
