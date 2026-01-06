//
//  FPFieldDetailsTemplateDatabaseManager.swift
//  crm
//
//  Created by Apple on 07/01/21.
//  Copyright © 2021 SmartServ. All rights reserved.
//

import Foundation
struct FPFieldDetailsTemplateDatabaseManager: FPDataBaseQueries {
    typealias successCompletionHandler = (_ success: Bool)->()
    typealias completionHandler = ()->()

    var fpLoggerModal: FPLoggerModal? {
        let ddLoggerModal = FPLoggerModal()
        return ddLoggerModal
    }
    static func getTableName() -> String {
        return FPTableName.fieldDetailsTemplate
    }
    
    static func getCreateQuery() -> String {
        return """
        CREATE TABLE IF NOT EXISTS \(self.getTableName()) (
        \(FPColumn.sqliteId)              \(FPDataTypes.integer) PRIMARY KEY AUTOINCREMENT,
        \(FPColumn.id)                    \(FPDataTypes.var100) UNIQUE,
        \(FPColumn.name)                  \(FPDataTypes.var100),
        \(FPColumn.displayName)           \(FPDataTypes.var100),
        \(FPColumn.uiType)             \(FPDataTypes.var100),
        \(FPColumn.dataType)             \(FPDataTypes.var100),
        \(FPColumn.mandatory)             \(FPDataTypes.bool0),
        \(FPColumn.max)             \(FPDataTypes.int),
        \(FPColumn.min)             \(FPDataTypes.int),
        \(FPColumn.defaultValue)             \(FPDataTypes.text),
        \(FPColumn.readOnly)             \(FPDataTypes.bool0),
        \(FPColumn.options)             \(FPDataTypes.text),
        \(FPColumn.layout)                     \(FPDataTypes.text),
        \(FPColumn.sectionId)              \(FPDataTypes.var100),
        \(FPColumn.sortPosition)           \(FPDataTypes.var100),
        \(FPColumn.isDeleted)             \(FPDataTypes.bool0),
        \(FPColumn.isActive)              \(FPDataTypes.bool1),
        \(FPColumn.createdAt)             \(FPDataTypes.date),
        \(FPColumn.updatedAt)             \(FPDataTypes.date),
        \(FPColumn.locallyUpdatedAt)      \(FPDataTypes.date),
        \(FPColumn.isSyncedToServer)      \(FPDataTypes.bool1),
        \(FPColumn.value)                 \(FPDataTypes.text),
        \(FPColumn.reasons)               \(FPDataTypes.text),
        \(FPColumn.scannable)              \(FPDataTypes.bool0)
        );
        """
    }
    func getDeleteQuery() -> String {
        return """
            DELETE FROM \(FPFieldDetailsTemplateDatabaseManager.getTableName())\n
            """
    }
    
    func getDeleteQuery(_ sectionId:String) -> String {
        return """
        \(getDeleteQuery())
        WHERE \(FPColumn.sectionId) = '\(sectionId)'
        """
    }
    func getLastInsertQuery() -> String {
        return ""
    }
    func getInsertQuery() -> String {
        return """
        INSERT INTO \(FPFieldDetailsTemplateDatabaseManager.getTableName()) (
        """
    }
    func getInsertBaseQuery(_ item: FPFieldDetails) -> String {
        var insertQuery = self.getInsertQuery()
        if item.objectStringId != nil {
            insertQuery += "\(FPColumn.id),"
        }
        if item.name != nil {
            insertQuery += "\(FPColumn.name),"
        }
        if item.displayName != nil {
            insertQuery += "\(FPColumn.displayName),"
        }
        if item.uiType != nil {
            insertQuery += "\(FPColumn.uiType),"
        }
        if item.dataType != nil {
            insertQuery += "\(FPColumn.dataType),"
        }
        if item.max != nil {
            insertQuery += "\(FPColumn.max),"
        }
        if item.min != nil {
            insertQuery += "\(FPColumn.min),"
        }
        if item.defaultValue != nil {
            insertQuery += "\(FPColumn.defaultValue),"
        }
        if item.sortPosition != nil {
            insertQuery += "\(FPColumn.sortPosition),"
        }
        if item.options != nil {
            insertQuery += "\(FPColumn.options),"
        }
        if item.layout != nil {
            insertQuery += "\(FPColumn.layout),"
        }
        if item.sectionStringId != nil {
            insertQuery += "\(FPColumn.sectionId),"
        }        
        if item.createdAt != nil {
            insertQuery += "\(FPColumn.createdAt),"
        }
        if item.updatedAt != nil {
            insertQuery += "\(FPColumn.updatedAt),"
        }
        if item.locallyUpdatedAt != nil {
            insertQuery += "\(FPColumn.locallyUpdatedAt),"
        }
        if item.value != nil {
            insertQuery += "\(FPColumn.value),"
        }
        if item.reasons != nil {
            insertQuery += "\(FPColumn.reasons),"
        }
        insertQuery += """
        \(FPColumn.mandatory),
        \(FPColumn.readOnly),
        \(FPColumn.isActive),
        \(FPColumn.isDeleted),
        \(FPColumn.isSyncedToServer),
        \(FPColumn.scannable)
        )
        VALUES
        (
        """
        return insertQuery
    }
    
    func getInsertQuery(for item: FPFieldDetails) -> String {
        var insertQuery = self.getInsertBaseQuery(item)
        if let value = item.objectStringId  {
            insertQuery += "'\(value)',"
        }
        if let value = item.name {
            insertQuery += "'\(value.processApostrophe())',"
        }
        if let value = item.displayName {
            insertQuery += "'\(value.processApostrophe())',"
        }
       
        if let value = item.uiType {
            insertQuery += "'\(value)',"
        }
        if let value = item.dataType {
            insertQuery += "'\(value)',"
        }
        if let value = item.max {
            insertQuery += "'\(value)',"
        }
        if let value = item.min {
            insertQuery += "'\(value)',"
        }
        if let value = item.defaultValue {
            insertQuery += "'\(value.processApostrophe())',"
        }
        if let value = item.sortPosition {
            insertQuery += "'\(value)',"
        }
        if let value = item.options {
            insertQuery += "'\(value.processApostrophe())',"
        }
        if let value = item.layout {
            insertQuery += "'\(value)',"
        }
        if let value = item.sectionStringId {
            insertQuery += "'\(value)',"
        }
        if let value = item.createdAt {
            insertQuery += "'\(value)',"
        }
        if let value = item.updatedAt {
            insertQuery += "'\(value)',"
        }
        if let value = item.locallyUpdatedAt {
            insertQuery += "'\(value)',"
        }
        if let value = item.value {
            insertQuery += "'\(value)',"
        }
        if let value = item.reasons {
            insertQuery += "'\(value)',"
        }
        insertQuery += """
        '\(item.mandatory ? 1 : 0)',
        '\(item.readOnly ? 1 : 0)',
        '\(item.isActive ? 1 : 0)',
        '\(item.isDeleted ? 1 : 0)',
        '\(item.isSyncedToServer ? 1 : 0)',
        '\(item.scannable ? 1 : 0)'
        )
        """
        return insertQuery
    }
    func insertFieldDetails(_ fieldDetails: [FPFieldDetails], _ sectionId:String, completion: @escaping completionHandler) {
        let queryArray = fieldDetails.map { (value) -> String in
//            value.sectionStringId = sectionId
            return self.getInsertQuery(for: value)
        }
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery(queryArray, dbManager: self) { success in
            completion()
        }
    }
    func updateFieldDetail(_ fieldDetail: FPFieldDetails, completion: @escaping successCompletionHandler) {
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery([self.getUpdateQuery(item: fieldDetail)], dbManager: self) { success in
            completion(success)
        }
    }
    func getDeleteQuery(for sectionId: String) -> String {
        var deleteQuery = self.getDeleteQuery()
        deleteQuery += """
        
        WHERE
        \(FPColumn.sectionId) = '\(sectionId)'
        """
        return deleteQuery
    }
    func getDeleteQuery(sectionIdCSV:String) -> String {
        var deleteQuery = self.getDeleteQuery()
        deleteQuery += """
        
        WHERE
        \(FPColumn.sectionId) IN (\(sectionIdCSV))
        """
        return deleteQuery
    }
    func deleteFieldDetailFor(sectionIds: [String], completionHandler: @escaping successCompletionHandler) {
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery([self.getDeleteQuery(sectionIdCSV:  sectionIds.joined(separator: ","))], dbManager: self) { success in
            completionHandler(success)
        }
       
    }
    func deleteFieldDetailFor(sectionId: String, completionHandler: @escaping successCompletionHandler) {
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery([self.getDeleteQuery(for:sectionId)], dbManager: self) { success in
            completionHandler(success)
        }
    }
    func fetchFieldDetails(for sectionId: String) -> [FPFieldDetails] {
        var array = [FPFieldDetails]()
        FPLocalDatabaseManager.shared.executeQuery(self.getFetchQuery(sectionId), dbManager: self) { results in
            for dict in results {
                let item = FPFieldDetails(json: dict, isForLocal: false)
                array.append(item)
            }
        }
        return array
    }
    func getFetchQuery(_ sectionId:String) -> String {
        return """
        SELECT * FROM \(FPFieldDetailsTemplateDatabaseManager.getTableName())
        WHERE \(FPColumn.sectionId) = '\(sectionId)' AND
        \(FPColumn.isActive) = 1 AND
        \(FPColumn.isDeleted) = 0
        """
    }
    
    func getUpdateQuery() -> String {
        return """
        UPDATE \(FPFieldDetailsTemplateDatabaseManager.getTableName())
        SET
        
        """
    }
    func getUpdateQuery(item: FPFieldDetails) -> String {
        var updateQuery = self.getUpdateQuery()
        
        if let value = item.name {
            updateQuery += "\(FPColumn.name)='\(value.processApostrophe())',"
        }else {
            updateQuery += "\(FPColumn.name)= NULL,"
        }
        
        if let value = item.displayName {
            updateQuery += "\(FPColumn.displayName)='\(value.processApostrophe())',"
        }else {
            updateQuery += "\(FPColumn.displayName)= NULL,"
        }
                
        if let value = item.uiType {
            updateQuery += "\(FPColumn.uiType)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.uiType)= NULL,"
        }
        if let value = item.dataType {
            updateQuery += "\(FPColumn.dataType)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.dataType)= NULL,"
        }
        if let value = item.max {
            updateQuery += "\(FPColumn.max)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.max)= NULL,"
        }
        if let value = item.min {
            updateQuery += "\(FPColumn.min)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.min)= NULL,"
        }
        if let value = item.defaultValue {
            updateQuery += "\(FPColumn.defaultValue)='\(value.processApostrophe())',"
        }else {
            updateQuery += "\(FPColumn.defaultValue)= NULL,"
        }
        if let value = item.sortPosition {
            updateQuery += "\(FPColumn.sortPosition)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.sortPosition)= NULL,"
        }
        if let value = item.options {
            updateQuery += "\(FPColumn.options)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.options)= NULL,"
        }
        if let value = item.layout {
            updateQuery += "\(FPColumn.layout)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.layout)= NULL,"
        }
        if let value = item.sectionStringId {
            updateQuery += "\(FPColumn.sectionId)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.sectionId)= NULL,"
        }
        
        if let value = item.locallyUpdatedAt {
            updateQuery += "\(FPColumn.locallyUpdatedAt)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.locallyUpdatedAt)= NULL,"
        }
        
        if let value = item.updatedAt {
            updateQuery += "\(FPColumn.updatedAt)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.updatedAt)= NULL,"
        }
        
        if let value = item.value {
            updateQuery += "\(FPColumn.value)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.value)= NULL,"
        }
        
        if let value = item.reasons {
            updateQuery += "\(FPColumn.reasons)='\(value)',"
        }else {
            updateQuery += "\(FPColumn.reasons)= NULL,"
        }
        
        updateQuery += """
        \(FPColumn.isActive)='\(item.isActive ? 1 : 0)',
        \(FPColumn.isDeleted)='\(item.isDeleted ? 1 : 0)',
        \(FPColumn.mandatory)= '\(item.mandatory ? 1 : 0)',
        \(FPColumn.readOnly)= '\(item.readOnly ? 1 : 0)',
        \(FPColumn.isSyncedToServer)='\(item.isSyncedToServer ? 1 : 0)',
         \(FPColumn.scannable)='\(item.scannable ? 1 : 0)'
        WHERE
        \(FPColumn.id)= '\(item.objectStringId!)'
        """
        return updateQuery
    }
    func getDeleteModuleEntityIdCSVQuery(for moduleEntityIdCSV: String) -> String {
        var deleteQuery = self.getDeleteQuery()
        deleteQuery += """
        
        WHERE
        \(FPColumn.sectionId) IN (\(moduleEntityIdCSV))
        """
        return deleteQuery
    }
    func deleteFeildDetails(for moduleEntityIdCSV: String) {
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery([self.getDeleteModuleEntityIdCSVQuery(for: moduleEntityIdCSV)], dbManager: self)
    }
}
