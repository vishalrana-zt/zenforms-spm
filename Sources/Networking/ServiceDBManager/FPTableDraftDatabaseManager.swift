//
//  FPTableDraftDatabaseManager.swift
//  crm
//
//  Copyright © 2026 SmartServ. All rights reserved.
//

import Foundation
internal import GRDB

struct FPTableDraftDatabaseManager: FPDataBaseQueries {
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
        return FPLoggerModal()
    }
    
    static func getTableName() -> String {
        return FPTableName.tableDraftData
    }
    
    static func getCreateQuery() -> String {
        return """
        CREATE TABLE IF NOT EXISTS \(self.getTableName()) (
        \(FPColumn.draftKey)      \(FPDataTypes.text) PRIMARY KEY,
        \(FPColumn.fieldLocalId)  \(FPDataTypes.integer),
        \(FPColumn.fieldId)       \(FPDataTypes.text),
        \(FPColumn.value)         \(FPDataTypes.text),
        \(FPColumn.updatedAt)     \(FPDataTypes.date)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS idx_table_draft_key ON \(self.getTableName())(\(FPColumn.draftKey));
        """
    }

    func getDeleteQuery() -> String {
        return "DELETE FROM \(FPTableDraftDatabaseManager.getTableName())"
    }



    // MARK: - Draft Operations (Key-centric)

    private func getInsertQuery(key: String, sqliteId: Int64?, objectId: String?, value: String) -> String {
        let safeKey   = key.processApostrophe()
        let safeValue = value.processApostrophe()
        let now       = ISO8601DateFormatter().string(from: Date())
        
        let sidStr = sqliteId != nil ? "\(sqliteId!)" : "NULL"
        let oidStr = objectId != nil ? "'\(objectId!.processApostrophe())'" : "NULL"

        return """
        INSERT OR REPLACE INTO \(FPTableDraftDatabaseManager.getTableName())
        (\(FPColumn.draftKey), \(FPColumn.fieldLocalId), \(FPColumn.fieldId), \(FPColumn.value), \(FPColumn.updatedAt))
        VALUES ('\(safeKey)', \(sidStr), \(oidStr), '\(safeValue)', '\(now)')
        """
    }

    func saveDraft(key: String, sqliteId: Int64?, objectId: String?, value: String) {
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery(
            [getInsertQuery(key: key, sqliteId: sqliteId, objectId: objectId, value: value)],
            dbManager: self
        )
    }

    func deleteDraft(draftKey: String) {
        let safeKey = draftKey.processApostrophe()
        let query = """
            DELETE FROM \(FPTableDraftDatabaseManager.getTableName())
            WHERE \(FPColumn.draftKey) = '\(safeKey)'
            """
        FPLocalDatabaseManager.shared.executeInsertUpdateDeleteQuery([query], dbManager: self)
    }

    func fetchDraft(draftKey: String, completion: @escaping (String?) -> Void) {
        let safeKey = draftKey.processApostrophe()
        let query = """
            SELECT \(FPColumn.value)
            FROM \(FPTableDraftDatabaseManager.getTableName())
            WHERE \(FPColumn.draftKey) = '\(safeKey)'
            LIMIT 1
            """
        FPLocalDatabaseManager.shared.executeQuery(query, dbManager: self) { results in
            if let first = results.first,
               let value = first[FPColumn.value] as? String,
               !value.isEmpty {
                completion(value)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Install scope ID (namespaces fallback keys per device)

    /// Stable per-install UUID. Generated once, persisted in UserDefaults.
    /// Prevents fallback key collisions across unrelated fields that share
    /// the same templateId + indexPath (e.g. after restore or reinstall).
    static func installScopeId() -> String {
        let udKey = "FPTableDraft.installScopeId"
        if let existing = UserDefaults.standard.string(forKey: udKey) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: udKey)
        return new
    }
}
