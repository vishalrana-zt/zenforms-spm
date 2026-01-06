//
//  ParameterEncoding.swift
//  crm
//
//  Created by Soumya on 29/11/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import Foundation

typealias FPParameters = [String:Any]

protocol FPParameterEncoder {
   func encode(urlRequest: inout URLRequest, with parameters: FPParameters) throws
   func setContentType(urlRequest: inout URLRequest)
}

enum FPParameterEncoding {
   
   case urlEncoding
   case jsonEncoding
//    case urlAndJsonEncoding

    func encode(urlRequest: inout URLRequest, parameters: FPParameters?, requestType: FPHTTPMethod) throws {
       do {
           switch self {
           case .urlEncoding:
               FPURLParameterEncoder().setContentType(urlRequest: &urlRequest)
               
           case .jsonEncoding:
               FPJSONParameterEncoder().setContentType(urlRequest: &urlRequest)
           }
         
           switch requestType {
           case .get:
               guard let urlParameters = parameters else { return }
               try FPURLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
           default:
               guard let bodyParameters = parameters else { break }
               try FPJSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
           }
       } catch {
           throw error
       }
   }
}

enum FPNetworkError: String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameter encoding failed."
    case missingURL = "URL is nil."
}
