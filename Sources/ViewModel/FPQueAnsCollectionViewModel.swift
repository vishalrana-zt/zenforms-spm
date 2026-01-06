//
//  FPQueAnsCollectionViewModel.swift
//  crm
//
//  Created by Apple on 07/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import Foundation
import UIKit
internal import SSMediaManager
let WIDTH_HEADER_QUE_ANS = 60
let WIDTH_CONTENT_QUE_ANS = 120
let WIDTH_QUES_COLUMN = 200

protocol FPQueAnsCollectionViewModelDataSource: AnyObject {
    func cellReuseIdentifier(for indexPath: IndexPath) -> String
    func configure(_ cell: UICollectionViewCell, with content: String , column:ColumnData?,indexPath: IndexPath, isHideMore:Bool, isHideCHeckBoxHeader:Bool)
    func getTableComponent()->TableComponent?
}

final class FPQueAnsCollectionViewModel: NSObject {
    weak var dataSource: FPQueAnsCollectionViewModelDataSource?

    private let HEIGHT_HEADER = 40
    private let HEIGHT_CONTENT = 75
    var parentIndexPath:IndexPath?
    var pickerArray: [DropdownOptions]?
    var pickerView: UIPickerView?
    var widthQuesColumn = WIDTH_QUES_COLUMN

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
extension FPQueAnsCollectionViewModel: UICollectionViewDataSource {
    // i.e. rows
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let tableComponent = dataSource?.getTableComponent()
        return (tableComponent?.rows?.count ?? 0 > 0 ? tableComponent!.rows!.count : 0)+1 // +1 headers
    }
    
    // i.e. number of columns
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return (dataSource?.getTableComponent()?.rows?.first?.columns.filter({$0.getUIType() != .HIDDEN}).count ?? 0)+1 // +2 > Sr No and Action
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var isHideMore = false
        var isHideCHeckBoxHeader = false
        let tableComponent = dataSource?.getTableComponent()
        let identifier = dataSource?.cellReuseIdentifier(for: indexPath) ?? ""
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier, for: indexPath
        )
        var cellContent = ""
        switch (column: indexPath.row, row: indexPath.section) {
            // Origin
        case (0, 0):
            cellContent = FPLocalizationHelper.localize("lbl_Sr_No")
            isHideMore = true
            isHideCHeckBoxHeader = true
            break
            
            // Top row - Header
        case (_, 0):
            isHideCHeckBoxHeader = true
            let columns = tableComponent?.rows?.first?.columns.filter({$0.getUIType() != .HIDDEN})
            cellContent = columns?[indexPath.row-1].key ?? ""
            if let column = columns?[indexPath.row-1]{
                isHideMore = column.uiType == "ATTACHMENT"
            }
            break
            
            // Left column -Sr number
        case (0, _):
            cellContent = "\(indexPath.section)"
            isHideMore = true
            isHideCHeckBoxHeader = true
            break
            
            // Inner-content
        default:
            let columns = tableComponent?.rows?[indexPath.section-1].columns.filter({$0.getUIType() != .HIDDEN})
            if let column = columns?[indexPath.row-1]{
                dataSource?.configure(cell, with: cellContent,column:column,indexPath:indexPath, isHideMore: isHideMore, isHideCHeckBoxHeader: isHideCHeckBoxHeader)
                return cell
            }
            
        }
        dataSource?.configure(cell, with: cellContent,column:nil, indexPath: indexPath, isHideMore: isHideMore, isHideCHeckBoxHeader: isHideCHeckBoxHeader)

        return cell

    }
}
// MARK: - UICollectionViewDelegate
extension FPQueAnsCollectionViewModel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}
}

// MARK: - SpreadsheetLayoutDelegate
extension FPQueAnsCollectionViewModel: SpreadsheetCollectionViewLayoutDelegate {
    func width(forColumn column: Int, collectionView: UICollectionView) -> CGFloat {
        if(column == 0){
            return CGFloat(WIDTH_HEADER_QUE_ANS)
        }else if(column == 1){
            return CGFloat(widthQuesColumn)
        }
        return CGFloat(WIDTH_CONTENT_QUE_ANS)
    }

    func height(forRow row: Int, collectionView: UICollectionView) -> CGFloat {
        if(row == 0){
            return CGFloat(HEIGHT_HEADER)
        }
        return CGFloat(HEIGHT_CONTENT)
    }
    func widthOffset() -> CGFloat {
        return CGFloat(WIDTH_CONTENT_QUE_ANS - widthQuesColumn)
    }
    func heightOffset() -> CGFloat {
        return CGFloat(HEIGHT_CONTENT-HEIGHT_HEADER)
    }
}

