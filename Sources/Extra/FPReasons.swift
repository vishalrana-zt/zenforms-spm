//
//  FPReasons.swift
//  crm
//
//  Created by Mayur on 24/02/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import Foundation

class FPReasons: Codable {
    var stringObjectId: FPStringBoolIntValue?
    var reasonTemplateId: String?
    var name: String?
    var displayName: String?
    var shortDescription: String?
    var isSelected: FPStringBoolIntValue?
    var recommendations:[FPRecommendation]?
    var severity:String?
    var dueDate:FPStringBoolIntValue?
    enum CodingKeys: String, CodingKey {
        case stringObjectId = "id"
        case reasonTemplateId = "reasonTemplateId"
        case name = "name"
        case displayName = "displayName"
        case shortDescription = "description"
        case isSelected = "isSelected"
        case recommendations = "recommendations"
        case severity = "severity"
        case dueDate = "dueDate"
    }
}

enum FPStringBoolIntValue: Codable {
    case string(String)
    case integer(Int)
    case bool(Bool)

    func associatedValue() -> Any {
      switch self {
      case .string(let value):
        return value
      case .integer(let value):
        return value
      case .bool(let value):
        return value
      }
    }
    
    func stringValue() -> String {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return "\(value)"
        case .bool(let value):
            return ""
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        
        throw DecodingError.typeMismatch(FPStringBoolIntValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ObjectId"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .bool(let x):
            try container.encode(x)
        }
    }
}
