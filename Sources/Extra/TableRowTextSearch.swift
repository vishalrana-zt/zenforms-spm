//
//  TableRowTextSearch.swift
//  ZenForms
//

import Foundation

enum TableRowTextSearch {
    /// Returns 0-based indices into `rows` that match `query` (case-insensitive substring).
    /// - Parameters:
    ///   - columnKeys: When non-empty, only these column `key` values are searched; when empty, all non-hidden columns are searched.
    static func matchingRowIndices(
        rows: [Rows],
        query: String,
        columnKeys: Set<String>
    ) -> [Int] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Array(rows.indices)
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        var result: [Int] = []
        result.reserveCapacity(rows.count)
        for (idx, row) in rows.enumerated() {
            let columns = row.columns.filter { $0.getUIType() != .HIDDEN }
            let keysToSearch: [ColumnData]
            if columnKeys.isEmpty {
                keysToSearch = columns
            } else {
                keysToSearch = columns.filter { columnKeys.contains($0.key) }
            }
            var matched = false
            for col in keysToSearch {
                if searchableText(for: col).range(of: trimmed, options: options) != nil {
                    matched = true
                    break
                }
            }
            if matched {
                result.append(idx)
            }
        }
        return result
    }

    static func searchableText(for column: ColumnData) -> String {
        var parts: [String] = []
        let value = FPUtility().getSQLiteSpecialCharsCompatibleString(value: column.value, isForLocal: false) ?? column.value
        if !value.isEmpty {
            parts.append(value)
        }
        parts.append(column.key)
        if let opts = column.dropDownOptions {
            for o in opts {
                parts.append(o.label.stringValue())
                parts.append(o.value.stringValue())
                parts.append(o.key.stringValue())
            }
        }
        return parts.joined(separator: " ")
    }
}
