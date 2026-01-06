//
//  ReasonsCustomTableModel.swift
//  crm
//
//  Created by Mayur on 24/02/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import Foundation

class FPReasonsComponent {
    
    var rows: [FPReasonsRow]?
    var customReason: FPReasonsRow?
    var value: String?
    var fieldTemplateId: String?
    
    func preparedData(_ reasons: [FPReasons], value: String?, templateId: String) -> FPReasonsComponent {
        self.value = value ?? ""
        self.fieldTemplateId = templateId
        self.rows = [FPReasonsRow]()
        reasons.forEach { reason in
            var value = reason.stringObjectId?.associatedValue() as? String;
            if(value == nil){
                value = String(reason.stringObjectId?.associatedValue() as? Int ?? 0);
            }
            if let templateId = reason.reasonTemplateId, templateId.contains("custom") {
                self.customReason = FPReasonsRow(objectID:value ?? "",displayName: reason.displayName ?? "", name: reason.name ?? "", reasonTemplateId: (reason.reasonTemplateId ?? value) ?? "" , description: reason.shortDescription ?? "", isSelected: true,recommendations: reason.recommendations, severity: reason.severity,dueDate: (reason.dueDate?.associatedValue() as? Int ?? nil))
            } else {
                let objectId = FPUtility.getSQLiteCompatibleStringValue(value, isForLocal: false)
                var isSelectedValue = false
                if let strValue = reason.isSelected?.associatedValue() as? String{
                    isSelectedValue = (strValue as NSString).boolValue
                }else if let blValue = reason.isSelected?.associatedValue() as? Bool{
                    isSelectedValue = blValue
                }
                self.rows?.append(FPReasonsRow(objectID:objectId ?? "", displayName: reason.displayName ?? "", name: reason.name ?? "", reasonTemplateId: (reason.reasonTemplateId ?? objectId) ?? "", description: reason.shortDescription ?? "", isSelected: isSelectedValue,recommendations: reason.recommendations, severity: reason.severity,dueDate: (reason.dueDate?.associatedValue() as? Int ?? nil)))
            }
        }
        return self
    }
    
    func getReasonsArray() -> [[String: Any]] {
        var reasons = [[String: Any]]()
        rows?.forEach { item in
            var reason = [String: Any]()
            reason["id"] = item.objectID
            reason["displayName"] = item.description
            reason["name"] = item.name
            reason["description"] = item.description
            reason["isSelected"] = item.isSelected
            reason["reasonTemplateId"] = "\(item.reasonTemplateId)"
            reason["recommendations"] = convertToDictionaryArray(array: item.recommendations ?? [FPRecommendation]()) ?? [:]
            reason["dueDate"] = item.dueDate ?? nil
            reason["severity"] = item.severity ?? ""
            reasons.append(reason)
        }
        let customReason = getCustomReasonJson(customReason, filedTemplateId: fieldTemplateId!)
        reasons.append(customReason)
        return reasons
    }
    
    func getCustomReasonJson(_ customReason: FPReasonsRow?, filedTemplateId: String) -> [String: Any] {
        var reason = [String: Any]()
        if let templateId = customReason?.reasonTemplateId {
            reason["reasonTemplateId"] = templateId
            reason["displayName"] = customReason?.displayName ?? "custom_\(templateId)"
            reason["name"] = customReason?.name ?? "custom_\(templateId)"
        } else {
            reason["reasonTemplateId"] = "custom_\(filedTemplateId)"
            reason["displayName"] = customReason?.displayName ?? "custom_\(filedTemplateId)"
            reason["name"] = customReason?.name ?? "custom_\(filedTemplateId)"
        }
        reason["id"] = customReason?.objectID ?? ""
        reason["description"] = customReason?.description ?? ""
        reason["isSelected"] = customReason?.isSelected ?? false
        reason["recommendations"] = convertToDictionaryArray(array: customReason?.recommendations ?? [FPRecommendation]()) ?? [:]
        reason["dueDate"] = customReason?.dueDate ?? nil
        reason["severity"] = customReason?.severity ?? ""
        return reason
    }
    
    func getCustomReason(_ description: String, templateId: String, objectId: String,severity:String,dueDate:Int?,recommendation:String,recommendationID:Int?) -> FPReasonsRow {
        let recommendation = FPRecommendation(id: recommendationID, name:  "custom_\(templateId)", nfpaCitation: "", note: recommendation, displayName: recommendation, description: recommendation)
        return FPReasonsRow(objectID: objectId, displayName: "custom_\(templateId)", name: "custom_\(templateId)", reasonTemplateId: "custom_\(templateId)", description: description, isSelected: true,recommendations: [recommendation], severity: severity,dueDate: dueDate)
    }
    
    // Convert to [[String: Any]]
    func convertToDictionaryArray<T: Encodable>(array: [T]) -> [[String: Any]]? {
        do {
            let data = try JSONEncoder().encode(array)
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            return jsonArray
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
}

struct FPReasonsRow {
    var objectID:String
    var displayName: String
    var name: String
    var reasonTemplateId: String
    var description: String
    var isSelected: Bool
    var recommendations:[FPRecommendation]?
    var severity:String?
    var dueDate:Int?
}

struct FPRecommendation : Codable {
    var id:Int?
    var name:String?
    var nfpaCitation: String?
    var note: String?
    var displayName: String?
    var description: String?
}


