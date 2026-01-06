//
//  URLParameterEncoder.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation

struct FPURLParameterEncoder: FPParameterEncoder {
    func setContentType(urlRequest: inout URLRequest) {
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
    }

    public func encode(urlRequest: inout URLRequest, with parameters: FPParameters) throws {
        guard let url = urlRequest.url else { throw FPNetworkError.missingURL }
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            urlComponents.queryItems = [URLQueryItem]()
            for (key, value) in parameters {
                if let array = value as? [String] {
                    for item in array {
                        let queryItem = URLQueryItem(name: key, value: item)
                        urlComponents.queryItems?.append(queryItem)
                    }
                } else {
                    let queryItem = URLQueryItem(name: key, value: "\(value)")
                    urlComponents.queryItems?.append(queryItem)
                }
            }
            urlRequest.url = urlComponents.url
        }
    }
}
