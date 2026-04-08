//
//  TableRowTextSearch.swift
//  ZenForms
//

import Foundation

enum TableRowTextSearch {
    /// UserDefaults key; persisted from `DuplicateRowPrefrenceViewController` (table settings).
    static let caseSensitiveSearchUserDefaultsKey = "ZenForms.TableTextSearch.caseSensitive"

    static var userPrefersCaseSensitiveSearch: Bool {
        UserDefaults.standard.bool(forKey: caseSensitiveSearchUserDefaultsKey)
    }

    /// Returns 0-based indices into `rows` that match `query` (substring).
    /// - Parameters:
    ///   - columnKeys: When non-empty, only these column `key` values are searched; when empty, all non-hidden columns are searched.
    ///   - caseSensitive: When false (default), matching is case- and diacritic-insensitive.
    static func matchingRowIndices(
        rows: [Rows],
        query: String,
        columnKeys: Set<String>,
        caseSensitive: Bool = false
    ) -> [Int] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Array(rows.indices)
        }
        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive, .diacriticInsensitive]
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
                let haystack = searchableText(for: col)
                if containsWordBoundedSubstring(haystack, trimmed, options: options) {
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

    /// Substring must be bordered by non‑word chars (or string start/end), so e.g. `No` does not match inside `None`.
    static func containsWordBoundedSubstring(_ haystack: String, _ needle: String, options: String.CompareOptions) -> Bool {
        guard !needle.isEmpty else { return true }
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let r = haystack.range(of: needle, options: options, range: searchRange, locale: nil) {
            if isWordBoundedRange(full: haystack, range: r) { return true }
            searchRange = r.upperBound..<haystack.endIndex
        }
        return false
    }

    /// Ranges of `needle` in `haystack` that are word-boundary safe (for highlighting).
    static func wordBoundedRanges(of needle: String, in haystack: String, options: String.CompareOptions) -> [Range<String.Index>] {
        guard !needle.isEmpty else { return [] }
        var found: [Range<String.Index>] = []
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let r = haystack.range(of: needle, options: options, range: searchRange, locale: nil) {
            if isWordBoundedRange(full: haystack, range: r) { found.append(r) }
            searchRange = r.upperBound..<haystack.endIndex
        }
        return found
    }

    private static func isWordChar(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "_"
    }

    private static func isWordBoundedRange(full: String, range: Range<String.Index>) -> Bool {
        if range.lowerBound > full.startIndex {
            let before = full.index(before: range.lowerBound)
            if isWordChar(full[before]) { return false }
        }
        if range.upperBound < full.endIndex, isWordChar(full[range.upperBound]) {
            return false
        }
        return true
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
                let label = o.label.stringValue()
                let val = o.value.stringValue()
                let key = o.key.stringValue()
                parts.append(label)
                parts.append(val)
                parts.append(key)
                if value.caseInsensitiveCompare(val) == .orderedSame || value.caseInsensitiveCompare(key) == .orderedSame || value.caseInsensitiveCompare(label) == .orderedSame {
                    parts.append(label)
                    parts.append(val)
                    parts.append(key)
                }
            }
        }

        if column.uiType == "DEFICIENCY" {
            let lower = value.lowercased()
            if ["1", "true", "yes"].contains(lower) {
                parts.append(FPLocalizationHelper.localize("Yes"))
            } else if ["0", "false", "no"].contains(lower) {
                parts.append(FPLocalizationHelper.localize("No"))
            } else if ["na", "n/a"].contains(lower) {
                parts.append("NA")
            }
        }
        return parts.joined(separator: " ")
    }
}
