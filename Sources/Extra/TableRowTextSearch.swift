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
                if containsSearchSubstring(haystack, trimmed, options: options) {
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

    /// Search strategy: regular substring matching for all query lengths.
    static func containsSearchSubstring(_ haystack: String, _ needle: String, options: String.CompareOptions) -> Bool {
        return haystack.range(of: needle, options: options) != nil
    }

    /// Ranges for highlighting that mirror `containsSearchSubstring` (all substring hits).
    static func searchRanges(of needle: String, in haystack: String, options: String.CompareOptions) -> [Range<String.Index>] {
        return allRanges(of: needle, in: haystack, options: options)
    }

    private static func allRanges(of needle: String, in haystack: String, options: String.CompareOptions) -> [Range<String.Index>] {
        guard !needle.isEmpty else { return [] }
        var found: [Range<String.Index>] = []
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let r = haystack.range(of: needle, options: options, range: searchRange, locale: nil) {
            found.append(r)
            searchRange = r.upperBound..<haystack.endIndex
        }
        return found
    }


    static func searchableText(for column: ColumnData) -> String {
        var parts: [String] = []
        let value = FPUtility().getSQLiteSpecialCharsCompatibleString(value: column.value, isForLocal: false) ?? column.value
        if !value.isEmpty {
            parts.append(value)
        }
        if let displayValue = displayFormattedDateValueIfNeeded(for: column, rawValue: value),
           !displayValue.isEmpty,
           displayValue != value {
            parts.append(displayValue)
        }
        if let opts = column.dropDownOptions {
            for o in opts {
                let label = o.label.stringValue()
                let val = o.value.stringValue()
                let key = o.key.stringValue()
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

    private static func displayFormattedDateValueIfNeeded(for column: ColumnData, rawValue: String) -> String? {
        let dateTypes: Set<String> = ["DATE", "TIME", "DATE_TIME", "YEAR"]
        guard dateTypes.contains(column.dataType), !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let format = dateDisplayFormat(for: column)
        if let date = FPUtility.getOPDateFrom(rawValue) {
            return date.convertUTCToLocalInString(with: format)
        }
        if let date = fixDateFormat(rawValue) {
            return date.convertUTCToLocalInString(with: format)
        }
        return nil
    }

    private static func dateDisplayFormat(for column: ColumnData) -> String {
        switch column.dataType {
        case "TIME":
            return FPFORM_DATE_FORMAT.TIME.rawValue
        case "DATE_TIME":
            return FPFORM_DATE_FORMAT.DATE_TIME.rawValue
        case "YEAR":
            return FPFORM_DATE_FORMAT.YEAR.rawValue
        default:
            return FPFORM_DATE_FORMAT.DATE.rawValue
        }
    }

    private static func fixDateFormat(_ dateString: String, format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }
}
