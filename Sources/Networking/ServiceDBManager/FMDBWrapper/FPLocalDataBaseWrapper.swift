//
//  LocalDataBaseWrapper.swift
//  crm
//
//  Created by Mayur on 27/04/20.
//  Copyright © 2020 SmartServ. All rights reserved.
//

import Foundation
internal import GRDB
internal import DatadogCore
internal import DatadogLogs
internal import FMDB

let dbName = "fpform_db.sqlite"

@objc class FPDataStore: NSObject {

    let databaseFileName = dbName
    var database: FMDatabase!
    let serialDBQueue = DispatchQueue(label: "serialDatabaseQueue")
    static let shared = FPDataStore()
    
    private override init() {
        super.init()
        self.database = FMDatabase(path:FPUtility.getDatabasePath(databaseFileName))
    }
    func getConfiguration() -> Configuration {
        var configuration = Configuration()
        configuration.maximumReaderCount = 5
//        configuration.defaultTransactionKind = .deferred
        return configuration
    }
    @discardableResult func executeInsertUpdateDeleteQuery(_ strQuery : String, tableName: String) -> Bool {
        var isSuccess = false
        serialDBQueue.sync {
            self.executeCRUDQuery(FPQuery.getCreateTableQuery(tableName))
            isSuccess = self.executeCRUDQuery(strQuery)
        }
        return isSuccess
    }
    
    @discardableResult private func executeCRUDQuery(_ strQuery : String) -> Bool {

        if self.database.open() {
            let result = self.database.executeUpdate(strQuery, withArgumentsIn: [])
            if !result {
                print("Error: \(self.database.lastErrorMessage() )")
            }
            self.database.close()
            print("Query: \(strQuery) got success = \(result)")
            return result
        } else {
            print("Error: \(self.database.lastErrorMessage() )")
            return false
        }
    }
  
    func executeSelectQuery(_ strQuery : String) -> NSMutableArray {
        let arryToReturn : NSMutableArray = []
        serialDBQueue.sync {
            if self.database.open() {
                print("Query: \(strQuery)")
                if let results:FMResultSet = self.database.executeQuery(strQuery, withArgumentsIn: []) {
                    while results.next() == true {
                        arryToReturn.add(results.resultDictionary as Any)
                    }
                    results.close()
                }
                print("DBResult: \(arryToReturn)")
                self.database.close()
            } else {
                print("Error: \(self.database.lastErrorMessage() )")
            }
        }
        return arryToReturn
    }
    
    func isTableExist(_ strTableName: String) -> Bool {
        let query = "SELECT name FROM sqlite_master WHERE type = table AND name = \(strTableName);"
        let results:FMResultSet? = self.database.executeQuery(query, withArgumentsIn: [])
        let isExist:Bool = results?.next() ?? false
        results?.close()
        return isExist
    }
    
    func getDatabase() -> FMDatabase {
        return self.database
    }
}
extension FPDataStore: FPDataBaseQueries {
    static func getTableName() -> String {
        return ""
    }
    
    static func getCreateQuery() -> String {
        return ""
    }
    
    func getDeleteQuery() -> String {
        return ""
    }
    
    func getInsertQuery() -> String {
        return ""
    }
    
    func getLastInsertQuery() -> String {
        return ""
    }
    
    func getUpdateQuery() -> String {
        return ""
    }
    
    var fpLoggerModal: FPLoggerModal? {
        let ddLogerModal = FPLoggerModal()
        ddLogerModal.loggerName = FPLoggerNames.dbManager
        return ddLogerModal
    }
}

