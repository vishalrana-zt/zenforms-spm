//
//  SpreadsheetCollectionViewModel.swift
//  crm
//
//  Created by Apple on 07/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import Foundation
import UIKit
internal import SSMediaManager
let WIDTH_HEADER = 60
let WIDTH_CONTENT = 120

protocol FPSpreadsheetCollectionViewModelDataSource: AnyObject {
    func cellReuseIdentifier(for indexPath: IndexPath) -> String
    func configure(_ cell: UICollectionViewCell, with content: String , column:ColumnData?,indexPath: IndexPath, isHideMore:Bool, isHideCHeckBoxHeader:Bool)
    func getTableComponent()->TableComponent?
}

final class FPSpreadsheetCollectionViewModel: NSObject {
    weak var dataSource: FPSpreadsheetCollectionViewModelDataSource?

    private let HEIGHT_HEADER = 40
    private let HEIGHT_CONTENT = 75
    private let OFFSET = 20
    var parentIndexPath:IndexPath?
    var pickerArray: [DropdownOptions]?
    var pickerView: UIPickerView?

    /// When non-nil, only these indices into `getTableComponent()?.rows` are shown as data rows. `nil` = show every row.
    var textSearchVisibleRowIndices: [Int]?

    // MARK: - Cached values for performance
    /// Cached filtered columns to avoid repeated filtering
    private var cachedFilteredColumns: [ColumnData]?
    /// Cached column count
    private var cachedColumnCount: Int = 0
    /// Cache for filtered columns per row index (avoids repeated .filter() calls)
    private var cachedRowColumns: [Int: [ColumnData]] = [:]
    /// Maximum cache size to prevent memory bloat
    private let maxRowCacheSize = 100
    /// Cached table component reference to avoid repeated calls
    private weak var cachedTableComponent: TableComponent?

    /// Clear cached values when data changes
    func invalidateCache() {
        cachedFilteredColumns = nil
        cachedColumnCount = 0
        cachedRowColumns.removeAll()
        cachedTableComponent = nil
    }

    /// Get filtered columns with caching
    private func getFilteredColumns() -> [ColumnData]? {
        if let cached = cachedFilteredColumns {
            return cached
        }
        cachedFilteredColumns = dataSource?.getTableComponent()?.rows?.first?.columns.filter({ $0.getUIType() != .HIDDEN })
        cachedColumnCount = (cachedFilteredColumns?.count ?? 0) + 2
        return cachedFilteredColumns
    }

    /// Get filtered columns for a specific row with caching
    private func getFilteredColumnsForRow(_ rowIndex: Int, row: Rows) -> [ColumnData] {
        if let cached = cachedRowColumns[rowIndex] {
            return cached
        }
        // Clear oldest entries if cache is too large
        if cachedRowColumns.count >= maxRowCacheSize {
            cachedRowColumns.removeAll()
        }
        let filtered = row.columns.filter({ $0.getUIType() != .HIDDEN })
        cachedRowColumns[rowIndex] = filtered
        return filtered
    }
    var accessoryToolbar: UIToolbar {
        get {
            let toolbarFrame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH_S, height: 44)
            let accessoryToolbar = UIToolbar(frame: toolbarFrame)
            let doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(onDoneButtonTapped(sender:)))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            accessoryToolbar.items = [flexibleSpace, doneButton]
            accessoryToolbar.barTintColor = UIColor.white
            return accessoryToolbar
        }
    }
    
    override init() {
        super.init()
    }
    
    @objc func onDoneButtonTapped(sender: UIBarButtonItem) {
//        if self.textView.isFirstResponder {
//            self.textView.resignFirstResponder()
//        }
    }
}

// MARK: - UICollectionViewDataSource
extension FPSpreadsheetCollectionViewModel: UICollectionViewDataSource {
    // i.e. rows
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let startTime = CFAbsoluteTimeGetCurrent()
        let tableComponent = dataSource?.getTableComponent()
        let baseCount = tableComponent?.rows?.count ?? 0
        let dataRows = textSearchVisibleRowIndices?.count ?? baseCount
        let result = (baseCount > 0 ? dataRows : 0) + 1 // +1 header when there is at least one underlying row
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("📊 [TableUI] numberOfSections: \(result) (baseRows: \(baseCount), elapsed: \(String(format: "%.2f", elapsed))ms)")
        return result
    }

    private func resolvedDataRowIndex(forSection section: Int) -> Int? {
        guard section >= 1 else { return nil }
        if let map = textSearchVisibleRowIndices {
            let i = section - 1
            guard i >= 0, i < map.count else { return nil }
            return map[i]
        }
        let rc = dataSource?.getTableComponent()?.rows?.count ?? 0
        let r = section - 1
        guard r >= 0, r < rc else { return nil }
        return r
    }
    
    // i.e. number of columns
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Use cached column count for better performance
        if cachedColumnCount > 0 {
            if section == 0 {
                print("📊 [TableUI] numberOfItemsInSection[\(section)]: \(cachedColumnCount) (cached)")
            }
            return cachedColumnCount
        }
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = getFilteredColumns()
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("📊 [TableUI] numberOfItemsInSection[\(section)]: \(cachedColumnCount) (computed in \(String(format: "%.2f", elapsed))ms)")
        return cachedColumnCount // +2 for Sr No and Action already included
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let startTime = CFAbsoluteTimeGetCurrent()
        var isHideMore = false
        var isHideCHeckBoxHeader = false

        // Cache table component reference to avoid repeated delegate calls
        let tableComponent: TableComponent?
        if let cached = cachedTableComponent {
            tableComponent = cached
        } else {
            tableComponent = dataSource?.getTableComponent()
            cachedTableComponent = tableComponent
        }

        let identifier = dataSource?.cellReuseIdentifier(for: indexPath) ?? ""
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier, for: indexPath
        )
        var cellContent = ""

        // Use cached filtered columns for header row
        let cachedColumns = getFilteredColumns()

        // Log only for first column of each row to reduce noise
        let shouldLog = indexPath.row == 0 && (indexPath.section <= 5 || indexPath.section % 50 == 0)

        switch (column: indexPath.row, row: indexPath.section) {
            // Origin
        case (0, 0):
            cellContent = FPLocalizationHelper.localize("lbl_Sr_No")
            isHideMore = true
            isHideCHeckBoxHeader = true
            break

        case (1, 0):
            cellContent = ""
            isHideMore = true
            isHideCHeckBoxHeader = false
            break

            //Action column
        case (1, _):
            cellContent = ""
            let column = ColumnData(key: "action-checkbox", value: "", uiType: "CHECKBOX", dataType: "",dropDownOptions: nil)
            dataSource?.configure(cell, with: cellContent,column:column,indexPath:indexPath, isHideMore: isHideMore, isHideCHeckBoxHeader: isHideCHeckBoxHeader)
            return cell

            // Top row - Header
        case (_, 0):
            isHideCHeckBoxHeader = true
            // Use cached columns instead of filtering every time
            cellContent = cachedColumns?[safe: indexPath.row-2]?.key ?? ""
            if let column = cachedColumns?[safe: indexPath.row-2] {
                isHideMore = column.uiType == "ATTACHMENT"
            }
            break

            // Left column - Sr number
        case (0, _):
            cellContent = "\(indexPath.section)"
            isHideMore = true
            isHideCHeckBoxHeader = true
            break

            // Inner-content
        default:
            guard let rowIdx = resolvedDataRowIndex(forSection: indexPath.section),
                  let row = tableComponent?.rows?[safe: rowIdx] else { break }
            // Use cached filtered columns for this row
            let columns = getFilteredColumnsForRow(rowIdx, row: row)
            let columnIndex = indexPath.row - 2
            if let column = columns[safe: columnIndex] {
                dataSource?.configure(cell, with: cellContent, column: column, indexPath: indexPath, isHideMore: isHideMore, isHideCHeckBoxHeader: isHideCHeckBoxHeader)
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                if shouldLog {
                    print("📊 [TableUI] cellForItemAt[\(indexPath.section),\(indexPath.row)]: content cell (cached), elapsed: \(String(format: "%.2f", elapsed))ms")
                }
                return cell
            }

        }
        dataSource?.configure(cell, with: cellContent, column: nil, indexPath: indexPath, isHideMore: isHideMore, isHideCHeckBoxHeader: isHideCHeckBoxHeader)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        if shouldLog {
            print("📊 [TableUI] cellForItemAt[\(indexPath.section),\(indexPath.row)]: header/empty cell, elapsed: \(String(format: "%.2f", elapsed))ms")
        }
        return cell

    }
}
// MARK: - UICollectionViewDelegate
extension FPSpreadsheetCollectionViewModel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}
}

// MARK: - UICollectionViewDataSourcePrefetching
extension FPSpreadsheetCollectionViewModel: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Pre-cache filtered columns if not already cached
        _ = getFilteredColumns()
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // No action needed for cancellation
    }
}

// MARK: - SpreadsheetLayoutDelegate
extension FPSpreadsheetCollectionViewModel: SpreadsheetCollectionViewLayoutDelegate {
    func width(forColumn column: Int, collectionView: UICollectionView) -> CGFloat {
        if(column == 0 || column == 1  ){
            return CGFloat(WIDTH_HEADER)
        }
        return CGFloat(WIDTH_CONTENT)
    }

    func height(forRow row: Int, collectionView: UICollectionView) -> CGFloat {
        if(row == 0){
            return CGFloat(HEIGHT_HEADER)
        }
        return CGFloat(HEIGHT_CONTENT)
    }
    func widthOffset() -> CGFloat {
        return CGFloat(WIDTH_CONTENT-WIDTH_HEADER)
    }
    func heightOffset() -> CGFloat {
        return CGFloat(HEIGHT_CONTENT-HEIGHT_HEADER)
    }
}
