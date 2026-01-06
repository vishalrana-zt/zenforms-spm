//
//  AdditionalTableCollectionViewCell.swift
//  crm
//
//  Created by Mayur on 15/02/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import UIKit

class FPTableCollectionViewCell: UITableViewCell {
    
    @IBOutlet weak var btnAddRow: UIButton!
    @IBOutlet weak var collMain: UICollectionView!
    @IBOutlet weak var tableName: UILabel!

    var delegate: FPCollectionCellDelegate!
    var fpViewController:FPFormViewController?
    var isShowAddRow = true
    var titleText:String?
    var isNew: Bool = true
    var tableIndexPath:IndexPath?
    var fieldDetails:FPFieldDetails?
    var sectionDetails:FPSectionDetails?
    var zenFormsDelegate: ZenFormsDelegate?

    var cellItem: TableComponent? {
        didSet {
            if let cellItem = cellItem,let index = tableIndexPath {
                FPFormDataHolder.shared.addTableComponentAt(index: index, component: cellItem)
            }
        }
    }
    
    var viewModel: FPQueAnsCollectionViewModel? {
        didSet {
            guard let layout = collMain.collectionViewLayout as? FPQueAnsCollectionViewLayout else {
                assertionFailure("Expected a SpreadsheetLayout")
                return
            }
            viewModel?.dataSource = self
            viewModel?.parentIndexPath = tableIndexPath
            collMain.dataSource = viewModel
            collMain.delegate = viewModel
            layout.isNew = true
            layout.delegate = viewModel
            collMain.reloadData()
        }
    }
    
    private let headerCellReuseIdentifier = "TableHeaderCollectionViewCell"
    private let contentCellReuseIdentifier = "TableContentCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let bundle = ZenFormsBundle.bundle

        collMain?.register(
            UINib(nibName: headerCellReuseIdentifier, bundle: bundle),
            forCellWithReuseIdentifier: headerCellReuseIdentifier
        )
        collMain?.register(
            UINib(nibName: contentCellReuseIdentifier, bundle: bundle),
            forCellWithReuseIdentifier: contentCellReuseIdentifier
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.viewModel = nil
        self.viewModel = FPQueAnsCollectionViewModel()
    }

    
    func configureCell(with item: FPFieldDetails, sectionDetail:FPSectionDetails?, indexPath: IndexPath, customForm:FPForms) {
        let displayName = item.displayName?.handleAndDisplayApostrophe() ?? ""
        self.fieldDetails  = item
        self.sectionDetails = sectionDetail
        self.tableName.text = displayName
        self.titleText = displayName
        self.tableIndexPath = indexPath
        self.btnAddRow.isHidden = !isShowAddRow
        self.viewModel?.widthQuesColumn = self.fieldDetails?.getUIType() == .TABLE ? WIDTH_CONTENT : WIDTH_QUES_COLUMN
        if let component = FPFormDataHolder.shared.getTableComponentAt(index: indexPath){
            self.cellItem = component
        }else{
            let tableOptions = item.getTableOptions(strJson: item.options ?? "")
            self.cellItem = TableComponent().prepareData(item: tableOptions ?? TableOptions(), values: item.value,index: indexPath,fieldDetails: item, customForm: customForm)
            FPFormDataHolder.shared.addTableComponentAt(index: indexPath, component: self.cellItem!)
        }
    }
    
    @IBAction func didAddRowTapped(_ sender: Any) {
        if self.fieldDetails?.getUIType() == .TABLE{
            self.openNormalTable()
        }else{
            self.openRestrictedTable()
        }
    }
    
    func openNormalTable(){
        let viewController =  FPTableEditViewController(nibName: "FPTableEditViewController", bundle: ZenFormsBundle.bundle)
        viewController.fieldDetails =  fieldDetails
        viewController.sectionDetails = sectionDetails
        viewController.fpFormViewController =  fpViewController
        viewController.zenFormsDelegate = zenFormsDelegate
        let component = TableComponent()
        component.headers = cellItem?.headers
        component.rows = cellItem?.rows
        component.tableOptions = cellItem?.tableOptions
        component.values = cellItem?.values
        viewController.tableComponent = component
        viewController.titleText = self.titleText
        viewController.tableIndexPath = tableIndexPath
        viewController.isNew  = self.isNew
        viewController.isAnalysed = fpViewController?.isAnalysed ?? false
        viewController.isFromHistory = fpViewController?.isFromHistory ?? false
        viewController.isAssetEnabled = fpViewController?.isAssetEnabled ?? false
        viewController.didCompletedEdit = { tableComponent in
            self.cellItem = tableComponent
            if let index = self.tableIndexPath {
                FPFormDataHolder.shared.addTableComponentAt(index: index, component: tableComponent)
            }
            self.updateTableData()
            self.collMain.reloadData()
            self.collMain.layoutIfNeeded()
        }
        self.fpViewController?.navigationController?.pushViewController(viewController, animated: true)
        return
    }
    
    func openRestrictedTable(){
        let viewController =  FPQueAnsTableEditViewController(nibName: "FPQueAnsTableEditViewController", bundle: ZenFormsBundle.bundle)
        viewController.fieldDetails =  fieldDetails
        viewController.sectionDetails = sectionDetails
        viewController.fpFormViewController =  fpViewController
        let component = TableComponent()
        component.headers = cellItem?.headers
        component.rows = cellItem?.rows
        component.tableOptions = cellItem?.tableOptions
        component.values = cellItem?.values
        viewController.tableComponent = component
        viewController.titleText = self.titleText
        viewController.tableIndexPath = tableIndexPath
        viewController.isNew  = self.isNew
        viewController.isAnalysed = fpViewController?.isAnalysed ?? false
        viewController.isFromHistory = fpViewController?.isFromHistory ?? false
        viewController.didCompletedEdit = { tableComponent in
            self.cellItem = tableComponent
            if let index = self.tableIndexPath {
                FPFormDataHolder.shared.addTableComponentAt(index: index, component: tableComponent)
            }
            self.updateTableData()
            self.collMain.reloadData()
            self.collMain.layoutIfNeeded()
        }
        self.fpViewController?.navigationController?.pushViewController(viewController, animated: true)
        return
    }
    
    fileprivate func updateTableData() {
        if let values = self.cellItem?.getValuesObject(){
            var tempValues:[[String:Any]] = []
            if(!(values.isEmpty)){
                for (index, element) in values.enumerated() {
                    let value = values[index]
                    if (value.keys.contains(where: {$0 == "__id__"})){
                        var tempValue = element
                        tempValue["__id__"] = value["__id__"]
                        tempValues.append(tempValue)
                    }else{
                        tempValues.append(element)
                    }
                }
            }else{
                tempValues = values
            }
            FPFormDataHolder.shared.updateRowWith(value:tempValues.getJson(), inSection:tableIndexPath!.section, atIndex: tableIndexPath!.row) { _ in }
        }
    }
  
}


extension FPTableCollectionViewCell: FPQueAnsCollectionViewModelDataSource {
    func configure(_ cell: UICollectionViewCell, with content: String, column: ColumnData?, indexPath: IndexPath, isHideMore: Bool, isHideCHeckBoxHeader:Bool) {
        if let contentcell = cell as? TableContentCollectionViewCell {
            contentcell.parentTableIndex = tableIndexPath
            contentcell.childTableIndex = indexPath
            contentcell.data = column
            contentcell.viewBarcode.isHidden = true
            contentcell.isUserInteractionEnabled = false
            contentcell.btnAddAttachment.isEnabled = false
        }else if let headerCell = cell as? TableHeaderCollectionViewCell {
            headerCell.text = content
            headerCell.viewBtn.isHidden = true
            headerCell.btnActions.isHidden = true
            headerCell.title.isHidden = !isHideCHeckBoxHeader
            headerCell.isUserInteractionEnabled = false
        }
    }

    
    func cellReuseIdentifier(for indexPath: IndexPath) -> String {
        switch (column: indexPath.row, row: indexPath.section) {
            // Origin
        case (0, 0):
            return headerCellReuseIdentifier
            
            // Top row
        case (_, 0):
            return headerCellReuseIdentifier
            
            // Left column
        case (0, _):
            return headerCellReuseIdentifier
            
            // Inner-content
        default:
            return contentCellReuseIdentifier
        }
    }
    
    func getTableComponent()->TableComponent?{
        return self.cellItem
    }
  
}
