//
//  FPTableEditViewController.swift
//  crm
//
//  Created by Apple on 03/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit
internal import SSMediaManager
internal import RSSelectionMenu
internal import IQKeyboardManagerSwift
internal import IQKeyboardToolbar
internal import IQKeyboardToolbarManager

enum SortColumnOption: Int {
    case ascending
    case descending
    case filter
}

struct SortFilter{
    let uuid = UUID().uuidString
    let indPath: IndexPath
    let option: SortColumnOption
    let filterItems:[String]?
}

let fileterBlankOptionKey = FPLocalizationHelper.localize("lbl_Empty")
let checkBoxCollectionRow = 1

class FPTableEditViewController: UIViewController {
    var rowCount = 1
    var MAX_ADD_ROW_COUNT  = 10
    
    private let headerCellReuseIdentifier = "TableHeaderCollectionViewCell"
    private let contentCellReuseIdentifier = "TableContentCollectionViewCell"
    
    @IBOutlet weak var txtRowCount: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewAddRow: UIView!
    
    @IBOutlet weak var mainBottomStk: UIStackView!
    @IBOutlet weak var stkOptions: UIStackView!
    
    @IBOutlet weak var btnAssetLink: UIButton!
    @IBOutlet weak var btnDuplicate: UIButton!
    @IBOutlet weak var btnMultipleDeleteRows: UIButton!
    
    @IBOutlet weak var btnAddMultipleRows: UIButton!
    @IBOutlet weak var btnOpenClose: UIButton!
    @IBOutlet weak var constLeading: NSLayoutConstraint!
    
    var tableIndexPath:IndexPath?
    var tableComponent:TableComponent?
    var sortFilteredTableComponent:TableComponent?
    var titleText: String?
    var attachmentIndex:IndexPath?
    var attachmentColumnData: ColumnData?
    var isAnalysed = false
    var isFromHistory = false
    var isNew: Bool = true
    var isAssetEnabled:Bool = false
    var didCompletedEdit:((_ tableComponent:TableComponent)->())?
    
    var sortFilterColumnIndexPath:IndexPath?
    var sortFilterColumn:Columns?
    var isSortFilterApplied:Bool = false
    var zenFormsDelegate: ZenFormsDelegate?

    
    var arrAppliedFilters = [SortFilter]()
    var arrSelectedIndexes = [IndexPath]()
    var arrSelectedRows = [Rows]()
    var isSelectedAll = false
    var viewModel: FPSpreadsheetCollectionViewModel? {
        didSet {
            guard let layout = collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout else {
                assertionFailure("Expected a SpreadsheetLayout")
                return
            }
            viewModel?.dataSource = self
            viewModel?.parentIndexPath = tableIndexPath
            collectionView.dataSource = viewModel
            collectionView.delegate = viewModel
            layout.delegate = viewModel
            collectionView!.reloadData()
        }
    }
    
    var accessoryToolbar: UIToolbar {
        get {
            let toolbarFrame = CGRect(x: 0, y: 0, width: SCREEN_SIZE.width, height: 44)
            let accessoryToolbar = UIToolbar(frame: toolbarFrame)
            let doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(onDoneButtonTapped(sender:)))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            accessoryToolbar.items = [flexibleSpace, doneButton]
            accessoryToolbar.barTintColor = UIColor.white
            return accessoryToolbar
        }
    }
    
    var assetLinkIndexPath:IndexPath?
    var fieldDetails:FPFieldDetails?
    var sectionDetails:FPSectionDetails?
    var fpFormViewController:FPFormViewController?
    var linkedAssets:[[String:NSNumber?]]{
        var arrResult = [[String:NSNumber?]]()
        if FPFormDataHolder.shared.customForm?.objectId == nil, FPFormDataHolder.shared.customForm?.sqliteId == nil{
            arrResult = [[String:NSNumber?]]()
            for linking in FPFormDataHolder.shared.arrLinkingDB{
                if linking.addLinking == true, linking.formTemplateId == FPFormDataHolder.shared.customForm?.templateId {
                    var dictAsset = [String:NSNumber?]()
                    dictAsset["assetId"] = linking.assetId
                    dictAsset["assetLocalId"] = linking.assetLocalId
                    arrResult.append(dictAsset)
                }
            }
        }else{
            arrResult = AssetFormLinkingDatabaseManager().fetchAssetLinkedToForm(FPFormDataHolder.shared.customForm)
        }
        return arrResult
    }
    
    var arrTblFormulas = [ColumnFormula]()
    var isAutoCalculateEnabled: Bool = false
    
    var isDuplicateRowAddedEndOFTable:Bool{
        if let preference = UserDefaults.standard.object(forKey: "DuplicateRowPreference") as? String {
            return preference == "lbl_End_Table"
        }else{
            return false
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        rowCount = 1
        txtRowCount.text = "\(rowCount)"
        txtRowCount.inputAccessoryView = self.accessoryToolbar
        stkOptions.isHidden = true
        
        var arrBtns = [UIBarButtonItem]()
        let saveButton = UIBarButtonItem(title:FPLocalizationHelper.localize("SAVE"), style:.plain, target: self, action: #selector(saveButtonAction))
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(settingsButtonAction))
        if !self.isAnalysed && !self.isFromHistory {
            arrBtns.append(saveButton)
        }
        arrBtns.append(settingsButton)
        self.navigationItem.rightBarButtonItems = arrBtns
        
        let customCancelButton = UIButton(type: .custom)
        customCancelButton.setTitleColor(UIColor(named: "BT-Primary"), for: .normal)
        customCancelButton.tintColor = UIColor(named: "BT-Primary")
        customCancelButton.setTitle(FPLocalizationHelper.localize("Cancel"), for: .normal)
        customCancelButton.sizeToFit()
        customCancelButton.addTarget(self, action: #selector(cancelButtonClicked(button:)), for:.touchUpInside)
        let cancelButton = UIBarButtonItem(customView:customCancelButton)
        self.navigationItem.leftBarButtonItem = cancelButton
        let bundle = ZenFormsBundle.bundle
        
        collectionView?.register(
            UINib(nibName: headerCellReuseIdentifier, bundle: bundle),
            forCellWithReuseIdentifier: headerCellReuseIdentifier
        )
        collectionView?.register(
            UINib(nibName: contentCellReuseIdentifier, bundle: bundle),
            forCellWithReuseIdentifier: contentCellReuseIdentifier
        )
        viewModel = FPSpreadsheetCollectionViewModel()
        if let formulas = self.tableComponent?.tableOptions?.formulas as? [ColumnFormula], !formulas.isEmpty{
            arrTblFormulas = []
            arrTblFormulas.append(contentsOf: formulas)
        }
        isAutoCalculateEnabled = arrTblFormulas.count > 0
        self.title  = titleText
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerAssetObservers()
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.toolbarConfiguration.previousBarButtonConfiguration = IQBarButtonItemConfiguration(image: UIImage(named: "ic_left_arrow", in: ZenFormsBundle.bundle, compatibleWith: nil) ?? UIImage())
        IQKeyboardManager.shared.toolbarConfiguration.nextBarButtonConfiguration = IQBarButtonItemConfiguration(image: UIImage(named: "ic_right_arrow", in: ZenFormsBundle.bundle, compatibleWith: nil) ?? UIImage())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        IQKeyboardManager.shared.isEnabled = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.toolbarConfiguration.previousBarButtonConfiguration = IQBarButtonItemConfiguration(image: UIImage())
        IQKeyboardManager.shared.toolbarConfiguration.nextBarButtonConfiguration = IQBarButtonItemConfiguration(image: UIImage())
    }
    
    func registerAssetObservers(){
        NotificationCenter.default.addObserver(self, selector:#selector(clearAssetLinkingIndex), name:NSNotification.ClearAssetLinkSelected, object:nil)
    }
    
    @objc func clearAssetLinkingIndex(){
        self.assetLinkIndexPath = nil
        self.resetMultipleSeletion()
    }

    
    @objc func onDoneButtonTapped(sender: UIBarButtonItem) {
        if self.txtRowCount.isFirstResponder {
            self.txtRowCount.resignFirstResponder()
        }
    }
    
    
    //MARK: Actions
    
    @IBAction func btnOpenClonseDidTap(_ sender: UIButton) {
        self.constLeading.constant = sender.isSelected ? -120.0 : 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        sender.isSelected = !sender.isSelected
    }
    
    @objc func settingsButtonAction(){
        let settingVC =  DuplicateRowPrefrenceViewController(nibName: "DuplicateRowPrefrenceViewController", bundle: ZenFormsBundle.bundle)
                let navController = UINavigationController(rootViewController: settingVC)
        if UIDevice.current.userInterfaceIdiom == .pad{
            navController.presentAsPopoverFP(self.view, rect: CGRectMake(CGRectGetMidX(self.view.bounds), 80,0,0), permittedArrowDirections: UIPopoverArrowDirection(), preferredContentSize: CGSize(width: 300, height: 500), base: self)
        } else {
            present(navController, animated: true)
        }
    }
    
    @objc func saveButtonAction(){
        view.endEditing(true)
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            if let tableComponent = self.tableComponent,let index = self.tableIndexPath{
                FPFormDataHolder.shared.addTableComponentAt(index: index, component: tableComponent)
                self.didCompletedEdit?(tableComponent)
            }
            let snapshot = FPFormDataHolder.shared.tableMediaCache
            snapshot.forEach { tableMedia in
                DispatchQueue.main.async {
                    FPFormDataHolder.shared.updateTableFieldValue(media: tableMedia)
                }
            }
            FPFormDataHolder.shared.tableMediaCache = []
            
            if self.isAssetEnabled, let isAssetTable = self.tableComponent?.tableOptions?.isAssetTable, isAssetTable{
                var arrLocalLinkings = [AssetFormMappingData]()
                arrLocalLinkings.append(contentsOf: FPFormDataHolder.shared.arrLinkingDB)
                arrLocalLinkings.forEach { linking in
                    linking.isTableSaved = true
                }
                FPFormDataHolder.shared.arrLinkingDB = []
                FPFormDataHolder.shared.arrLinkingDB.append(contentsOf: arrLocalLinkings)
            }
            self.navigationController?.popViewController(animated: false)
            
        })
    }
    
    @objc func cancelButtonClicked(button:UIButton) {
        view.endEditing(true)
        if self.isAssetEnabled, let isAssetTable = self.tableComponent?.tableOptions?.isAssetTable, isAssetTable{
            let otherFieldTableSavedLinkings = FPFormDataHolder.shared.arrLinkingDB.filter { $0.fieldTemplateId != self.fieldDetails?.templateId || $0.isTableSaved == true}
            FPFormDataHolder.shared.arrLinkingDB = []
            FPFormDataHolder.shared.arrLinkingDB.append(contentsOf: otherFieldTableSavedLinkings)
            AssetFormLinkingDatabaseManager().fetchAndRemoveNotConfirmedAssetLinkingForForm(FPFormDataHolder.shared.customForm)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    

    @IBAction func didTapAddRow(_ sender: Any){
        self.view.endEditing(true)
        guard let rowValue = txtRowCount.text, !rowValue.isEmpty, let intVal  = Int(rowValue) else {
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_Invalid_add_row"), completion: nil)
            return
        }
        rowCount = intVal
        if rowCount < 1{
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_add_row_non_Zero"), completion: nil)
            return
        }else if rowCount > 10{
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_add_row_max_ten"), completion: nil)
            return
        }
        guard let row = self.tableComponent?.rows?.first else { return }
        
        FPUtility.showHUDWithLoadingMessage()
        
        for _ in 1...rowCount {
            let newRow = self.tableComponent?.addNewRow(with: row.columns)
            if isSortFilterApplied{
                _ = self.sortFilteredTableComponent?.addNewRow(with: row.columns, rowSortId: newRow?.sortUuid)
            }
        }
        if let layout = collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.addRow(nRow: rowCount)
        }
        
        DispatchQueue.main.async {
            FPUtility.hideHUD()
            self.collectionView.reloadData()
        }
    }
    
    func addEmptyRowToTable(){
        guard let row = self.tableComponent?.rows?.first else { return }
        let newRow = self.tableComponent?.addNewRow(with: row.columns, ignoreDefaultVal: true)
        if isSortFilterApplied{
            _ = self.sortFilteredTableComponent?.addNewRow(with: row.columns, rowSortId: newRow?.sortUuid, ignoreDefaultVal: true)
        }
        if let layout = collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.addRow(nRow: 1)
        }
        self.collectionView.reloadData()
    }
    
    @IBAction func btnDuplicateDidTap(_ sender: UIButton) {
        FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage: FPLocalizationHelper.localize("msg_duplicate_selected_rows"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
            self.duplicateMultipleRows(self.arrSelectedRows)
        }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
    }
    
    @IBAction func btnDeleteDidTap(_ sender: UIButton) {
        
        FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage:  FPLocalizationHelper.localize("msg_delete_selected_rows"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
            self.deleteMultipleRows(self.arrSelectedRows)
        }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
    }
    
    @IBAction func btnLinkAssetDidTap(_ sender: UIButton) {
        if let childTableIndex = self.arrSelectedIndexes.first{
            self.linkAsset(at: childTableIndex, parentTableIndex: tableIndexPath)
        }
    }
}

extension FPTableEditViewController: FPSpreadsheetCollectionViewModelDataSource {
    func configure(_ cell: UICollectionViewCell, with content: String, column: ColumnData?, indexPath: IndexPath, isHideMore: Bool, isHideCHeckBoxHeader:Bool) {
        if let contentcell = cell as? TableContentCollectionViewCell {
            contentcell.parentTableIndex = tableIndexPath
            contentcell.childTableIndex = indexPath
            contentcell.data = column
            contentcell.delegate = self
            contentcell.btnAction.isSelected = self.isSelectedAll || self.arrSelectedIndexes.contains(indexPath)
            contentcell.btnAction.addTarget(self, action: #selector(btnActionClicked(sender:)), for: .touchUpInside)
            var showBarcodeBtn = false
            if isAssetEnabled, let isAssetTable = self.tableComponent?.tableOptions?.isAssetTable, isAssetTable{
                showBarcodeBtn = column?.scannable ?? false && column?.dataType == "TEXT" && column?.uiType == "INPUT"
            }
            contentcell.viewBarcode.isHidden = !showBarcodeBtn
            contentcell.btnBarcode.addTarget(self, action: #selector(btnBarcodeClicked(sender:)), for: .touchUpInside)
        }else if let headerCell = cell as? TableHeaderCollectionViewCell {
            headerCell.imgMore.image =  UIImage(named: "icn_more", in: ZenFormsBundle.bundle, compatibleWith: nil)
            headerCell.imgMore.setImageColor(color: .black)
            headerCell.text = content
            headerCell.viewBtn.isHidden = isHideMore
            headerCell.btnActions.isHidden = isHideCHeckBoxHeader
            headerCell.btnActions.isSelected =  self.isSelectedAll
            headerCell.title.isHidden = !isHideCHeckBoxHeader
            headerCell.btnMore.addTarget(self, action: #selector(btnMoreClicked(sender:)), for: .touchUpInside)
            headerCell.btnActions.addTarget(self, action: #selector(btnHeaderActionClicked(sender:)), for: .touchUpInside)
            if isSortFilterApplied == true, let index = arrAppliedFilters.firstIndex(where: { $0.indPath == indexPath}), let appliedFilter = arrAppliedFilters[safe: index]  {
                if appliedFilter.option == .filter {
                    headerCell.imgMore.image = UIImage(named: "icn_filter", in: ZenFormsBundle.bundle, compatibleWith: nil)
                }else{
                    headerCell.imgMore.image = UIImage(named: appliedFilter.option == .ascending ? "icn_sort_asc" : "icn_sort_dsc", in: ZenFormsBundle.bundle, compatibleWith: nil)
                }
                headerCell.imgMore.setImageColor(color: UIColor(named: "BT-Primary") ?? .blue)
            }
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
        if isSortFilterApplied{
            return self.sortFilteredTableComponent
        }else{
            return self.tableComponent
        }
    }
    
    @objc func btnMoreClicked(sender: UIButton){
        let btnPosition = sender.convert(CGPoint.zero, to: self.collectionView)
        sortFilterColumnIndexPath = self.collectionView.indexPathForItem(at: btnPosition)
        if  let sortedIndexPth = sortFilterColumnIndexPath, let shownColumns = self.tableComponent?.tableOptions?.columns?.filter({$0.uiType != "HIDDEN"}), let column = shownColumns[safe:sortedIndexPth.row - 2]{
            sortFilterColumn = column
        }
        if sortFilterColumn?.uiType == "DROPDOWN"{
            displayOptionsPopUp(sender)
        }else{
            displaySortingPopUp(sender)
        }
    }
    
    @objc func btnHeaderActionClicked(sender: UIButton){
        sender.isSelected = !sender.isSelected
        isSelectedAll = sender.isSelected
        if isSelectedAll{
            self.selectALLRows()
        }else{
            self.unSelectALLRows()
        }
        self.refreshActionButtons()
    }
    
    @objc func btnActionClicked(sender: UIButton){
        let btnPosition = sender.convert(CGPoint.zero, to: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: btnPosition){
            var selectedRow:Rows?
            if self.isSortFilterApplied{
                selectedRow =  self.sortFilteredTableComponent?.rows?[safe:indexPath.section-1]
            }else{
                selectedRow =  self.tableComponent?.rows?[safe:indexPath.section-1]
            }
            if let rowIndex = self.arrSelectedRows.firstIndex(where: { $0.sortUuid == selectedRow?.sortUuid }){
                self.arrSelectedRows.remove(at: rowIndex)
            }else{
                if let selectedRow = selectedRow{
                    self.arrSelectedRows.append(selectedRow)
                }
            }
            var tmpIndexs = self.arrSelectedIndexes
            if self.arrSelectedIndexes.contains(indexPath){
                self.arrSelectedIndexes.removeObject(indexPath)
            }else{
                tmpIndexs.append(indexPath)
                self.arrSelectedIndexes.append(indexPath)
            }
            if self.isSelectedAll{
                self.isSelectedAll = false
                self.collectionView.reloadData()
            }else{
                self.collectionView.reloadItems(at: tmpIndexs)
            }
            self.refreshActionButtons()
        }
    }
    
    @objc func btnBarcodeClicked(sender: UIButton){
        let btnPosition = sender.convert(CGPoint.zero, to: self.collectionView)
        if let index = self.collectionView.indexPathForItem(at: btnPosition){
            self.linkAsset(at: index, parentTableIndex: tableIndexPath)
        }
    }
    
    func refreshActionButtons(){
        stkOptions.isHidden = self.arrSelectedRows.count == 0
        btnAssetLink.isHidden = true
        btnDuplicate.isHidden = false
        if isAssetEnabled, let isAssetTable = self.tableComponent?.tableOptions?.isAssetTable, isAssetTable{
            btnAssetLink.isHidden  = self.arrSelectedRows.count > 1
            btnDuplicate.isHidden = true
        }
    }
    
    func selectALLRows(){
        self.arrSelectedIndexes = []
        self.arrSelectedRows = []
        (0..<collectionView.numberOfSections).indices.forEach { sectionIndex in
            var selectedRow:Rows?
            if self.isSortFilterApplied{
                selectedRow =  self.sortFilteredTableComponent?.rows?[safe:sectionIndex-1]
            }else{
                selectedRow =  self.tableComponent?.rows?[safe:sectionIndex-1]
            }
            if let selectedRow = selectedRow{
                self.arrSelectedRows.append(selectedRow)
            }
        }
        if self.arrSelectedRows.count == 1{
            (0..<collectionView.numberOfItems(inSection: 1)).indices.forEach { rowIndex in
                if let cell = collectionView.cellForItem(at: IndexPath(row: rowIndex, section: 1)) as? TableContentCollectionViewCell{
                    let showBarcodeBtn = cell.data?.scannable ?? false && cell.data?.dataType == "TEXT" && cell.data?.uiType == "INPUT"
                    if showBarcodeBtn {
                        self.arrSelectedIndexes.append(IndexPath(row: rowIndex, section: 1))
                    }
                }
            }
        }
        self.isSelectedAll = true
        self.collectionView.reloadData()
    }
    
    func unSelectALLRows(){
        self.isSelectedAll = false
        self.arrSelectedIndexes = []
        self.arrSelectedRows = []
        self.collectionView.reloadData()
    }
  
}

//MARK: Sort Filter Operations

extension UITableView{
    func configureRSSelectionMenuTable(){
        if #available(iOS 15, *) {
            self.sectionHeaderTopPadding = 0
        }
        self.layoutMargins = UIEdgeInsets.zero
        self.separatorInset = UIEdgeInsets.zero
    }
}
extension FPTableEditViewController{
    
    
    func displaySortingPopUp(_ sender:UIButton){
        let arrOptions = [FPLocalizationHelper.localize("lbl_Ascending"), FPLocalizationHelper.localize("lbl_Descending")]
        let menu = RSSelectionMenu(selectionStyle: .single, dataSource: arrOptions) { (cell, name, indexPath) in
            cell.textLabel?.text = name
            cell.tintColor = UIColor(named: "BT-Primary") ?? .blue
        }
        menu.tableView?.configureRSSelectionMenuTable()
        menu.setNavigationBar(title: FPLocalizationHelper.localize("lbl_Sort"), attributes: [NSAttributedString.Key.foregroundColor: isFromCoPILOT ? UIColor.white : UIColor.black], barTintColor: UIColor(named: "BT-Primary"), tintColor: isFromCoPILOT ? UIColor.white : UIColor.black)
        if !self.arrAppliedFilters.isEmpty{
            let leftBarButton = UIBarButtonItem(title:FPLocalizationHelper.localize("lbl_Clear"), style: .plain, target: self, action: #selector(leftBarButtonTapped))
            menu.navigationItem.leftBarButtonItem = leftBarButton
        }
        let rightBarButton = UIBarButtonItem(title:FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(rightBarButtonTapped))
        menu.navigationItem.rightBarButtonItem = rightBarButton
        menu.navigationItem.rightBarButtonItem?.tintColor = UIColor(named: "BT-Primary")
        if isSortFilterApplied == true, let index = arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}), let appliedFilter  = arrAppliedFilters[safe: index]{
            let strSort = appliedFilter.option == .ascending ? FPLocalizationHelper.localize("lbl_Ascending"): FPLocalizationHelper.localize("lbl_Descending")
            menu.setSelectedItems(items: [strSort]) {  (_, _, _, _) in }
        }
        menu.onDismiss = { selectedItems in
            if let selected = selectedItems.first{
                if let index = self.arrAppliedFilters.firstIndex(where: { $0.option != .filter}){
                    self.arrAppliedFilters.remove(at: index)
                }
                var localsort:SortColumnOption = .descending
                if selected == FPLocalizationHelper.localize("lbl_Ascending"){
                    localsort = .ascending
                }
                if let sortFilterColumnIndexPath = self.sortFilterColumnIndexPath, let index = self.arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}){
                    self.arrAppliedFilters.remove(at: index)
                }
                if let sortFilterColumnIndexPath = self.sortFilterColumnIndexPath{
                    let filter = SortFilter(indPath: sortFilterColumnIndexPath, option: localsort, filterItems: nil)
                    if let index = self.arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}){
                        self.arrAppliedFilters[index] = filter
                    }else{
                        self.arrAppliedFilters.append(filter)
                    }
                }
                self.applySortFilterToTable(option: localsort)
            }
        }
        menu.cellSelectionStyle = .tickmark
        menu.show(style: .popover(sourceView: sender, size: nil, arrowDirection: .any), from: self)
    }
    
    func clearCurrentRowFilter(){
        if let sortFilterColumnIndexPath = self.sortFilterColumnIndexPath, let index = self.arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}){
            self.arrAppliedFilters.remove(at: index)
        }
        if self.arrAppliedFilters.isEmpty{
            self.resetToDefault()
        }else if let object = self.arrAppliedFilters.first{
//            self.sortFilteredTableComponent = nil
            self.sortFilterColumnIndexPath = object.indPath
            if  let sortedIndexPth = sortFilterColumnIndexPath, let column = self.tableComponent?.tableOptions?.columns?[safe:sortedIndexPth.row - 2]{
                sortFilterColumn = column
            }
            self.applySortFilterToTable(option: object.option)
        }
    }
    
    func resetToDefault(){
        //clear option selected
        self.arrAppliedFilters = []
        self.sortFilterColumnIndexPath = nil
        self.isSortFilterApplied = false
        self.sortFilterColumn = nil
        self.sortFilteredTableComponent = nil
        self.resetMultipleSeletion()
        self.collectionView.reloadData()
    }
    
    
    func resetMultipleSeletion(){
        self.arrSelectedIndexes = []
        self.arrSelectedRows = []
        self.isSelectedAll = false
        self.refreshActionButtons()
        self.collectionView.reloadData()
    }
    
    func displayOptionsPopUp(_ sender:UIButton){
        if  isSortFilterApplied == true, let index = arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}), let appliedFilter  = arrAppliedFilters[safe: index]  {
            if appliedFilter.option  == .filter{
                self.displayFilterPopUp(sender)
            }else{
                self.displaySortingPopUp(sender)
            }
        }
        else{
            let arrOptions = [FPLocalizationHelper.localize("lbl_Sort"), FPLocalizationHelper.localize("lbl_Filter")]
            let menu = RSSelectionMenu(selectionStyle: .single, dataSource: arrOptions) { (cell, name, indexPath) in
                cell.textLabel?.text = name
                cell.tintColor = UIColor(named: "BT-Primary") ?? .blue
            }
            let rightBarButton = UIBarButtonItem(title:FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(rightBarButtonTapped))
            menu.navigationItem.rightBarButtonItem = rightBarButton
            menu.navigationItem.rightBarButtonItem?.tintColor = UIColor(named: "BT-Primary")
            menu.tableView?.configureRSSelectionMenuTable()
            menu.setNavigationBar(title: FPLocalizationHelper.localize("lbl_Sort_Filter"), attributes: [NSAttributedString.Key.foregroundColor: isFromCoPILOT ? UIColor.white : UIColor.black], barTintColor: UIColor(named: "BT-Primary"), tintColor: isFromCoPILOT ? UIColor.white : UIColor.black)
            menu.onDismiss = { selectedItems in
                if let selected = selectedItems.first{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if selected == FPLocalizationHelper.localize("lbl_Sort"){
                            self.displaySortingPopUp(sender)
                        }else{
                            self.displayFilterPopUp(sender)
                        }
                    }
                }
            }
            menu.cellSelectionStyle = .tickmark
            menu.show(style: .popover(sourceView: sender, size: nil, arrowDirection: .any), from: self)
        }
    }
    
    func displayFilterPopUp(_ sender:UIButton){
        var arrOptions = [DropdownOptions]()
        var generateDynamically = false
        if let column = sortFilterColumn, column.uiType == "DROPDOWN", let options = column.columnOptions?.dropdownOptions{
            generateDynamically = column.columnOptions?.generateDynamically ?? false
            arrOptions.append(contentsOf: options)
        }
        var menuFilterOptions = arrOptions.compactMap({ generateDynamically ? $0.label.stringValue() :  $0.value.stringValue()})
        menuFilterOptions.append(fileterBlankOptionKey)
        let menu = RSSelectionMenu(selectionStyle: .multiple, dataSource: menuFilterOptions) { (cell, name, indexPath) in
            cell.textLabel?.text = name
            cell.tintColor = UIColor(named: "BT-Primary") ?? .blue
        }
        menu.tableView?.configureRSSelectionMenuTable()
        menu.setNavigationBar(title: FPLocalizationHelper.localize("lbl_Filter"), attributes: [NSAttributedString.Key.foregroundColor: isFromCoPILOT ? UIColor.white : UIColor.black], barTintColor: UIColor(named: "BT-Primary"), tintColor: isFromCoPILOT ? UIColor.white : UIColor.black)
        if !self.arrAppliedFilters.isEmpty{
            let leftBarButton = UIBarButtonItem(title: FPLocalizationHelper.localize("lbl_Clear"), style: .plain, target: self, action: #selector(leftBarButtonTapped))
            menu.navigationItem.leftBarButtonItem = leftBarButton
        }
        menu.setRightBarButton(title: FPLocalizationHelper.localize("Done")) { selectedItems in
            menu.dismiss(animated: true)
            if selectedItems.isEmpty{
                if self.arrAppliedFilters.filter({ $0.option == .filter}).count > 0{
                    self.clearCurrentRowFilter()
                }else if self.arrAppliedFilters.isEmpty{
                    self.resetToDefault()
                }else{}
            }
            if let sortFilterColumnIndexPath = self.sortFilterColumnIndexPath{
                let filter = SortFilter(indPath: sortFilterColumnIndexPath, option: .filter, filterItems: selectedItems)
                if let _ = self.arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath }){
                    self.applyFilterToSameColomnTable(filter: filter)
                }else{
                    self.arrAppliedFilters.append(filter)
                    self.applySortFilterToTable(option: .filter)
                }
            }
        }

        if  isSortFilterApplied == true, let index = arrAppliedFilters.firstIndex(where: { $0.indPath == sortFilterColumnIndexPath}), let appliedFilter = arrAppliedFilters[safe: index], appliedFilter.option  == .filter, let filterItems = appliedFilter.filterItems{
            menu.setSelectedItems(items: filterItems) {  (_, _, _, _) in }
        }
        menu.cellSelectionStyle = .checkbox
        menu.show(style: .popover(sourceView: sender, size: nil, arrowDirection: .any), from: self)
    }
    
    @objc func leftBarButtonTapped() {
        self.clearCurrentRowFilter()
        self.dismiss(animated: true)
    }
    
    @objc func rightBarButtonTapped() {
        self.dismiss(animated: true)
    }
    
    func applySortingToTable(option:SortColumnOption, completion: @escaping (TableComponent) -> Void){
        if var tableComponent = tableComponent, let column = sortFilterColumn{
            if let sorted = sortFilteredTableComponent{
                tableComponent = sorted
            }
            tableComponent.sortData(component: tableComponent, sortOption: option, sortColumn: column) { sortedComponent in
                self.resetMultipleSeletion()
                completion(sortedComponent)
            }
        }
    }
    
    func applyFilterToTable(items:[String], completion: @escaping (TableComponent) -> Void){
        guard items.count > 0 else {
            if var tableComponent = tableComponent {
                if let sorted = sortFilteredTableComponent{
                    tableComponent = sorted
                }
                completion(tableComponent)
            }
            return
        }
        if var tableComponent = tableComponent, let column = sortFilterColumn {
            if let sorted = sortFilteredTableComponent{
                tableComponent = sorted
            }
            tableComponent.filterData(component: tableComponent, arrSelected: items, filterColumn: column) { filteredComponent in
                self.resetMultipleSeletion()
                completion(filteredComponent)
            }
        }
    }
    
    func applySortFilterToTable(option:SortColumnOption){
        if option == .filter, let index = self.arrAppliedFilters.firstIndex(where: { $0.option == .filter}), let filter  = self.arrAppliedFilters[safe: index]{
            self.applyFilterToTable(items: filter.filterItems ?? []) { filterdtbl in
                if filterdtbl.rows?.count == 0{
                    self.arrAppliedFilters.remove(at: index)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_no_data"), completion: nil)
                    }
                }else{
                    self.sortFilteredTableComponent  = filterdtbl
                }
                self.refreshWithSortFilter()
            }
        }else if  option != .filter,  let index = self.arrAppliedFilters.firstIndex(where: { $0.option != .filter}) , let filter  = arrAppliedFilters[safe: index]{
            self.applySortingToTable(option: filter.option) { sortedtbl in
                self.sortFilteredTableComponent  = sortedtbl
                self.refreshWithSortFilter()
            }
        }else{
        }
        
    }
    
    func applyFilterToSameColomnTable(filter:SortFilter){
        if let index = self.arrAppliedFilters.firstIndex(where: { $0.option == .filter}){
            self.arrAppliedFilters.remove(at: index)
        }
        self.sortFilteredTableComponent = nil
        if let index = self.arrAppliedFilters.firstIndex(where: { $0.option != .filter}), let sortfilter  = arrAppliedFilters[safe: index]{
            self.applySortingToTable(option: sortfilter.option) { sortedtbl in
                self.sortFilteredTableComponent  = sortedtbl
                self.filterToSameColomnTable(filter: filter)
            }
        }else{
            self.filterToSameColomnTable(filter: filter)
        }
    }
    
    func filterToSameColomnTable(filter:SortFilter){
        self.arrAppliedFilters.append(filter)
        self.applyFilterToTable(items: filter.filterItems ?? []) { filterdtbl in
            if filterdtbl.rows?.count == 0{
                self.arrAppliedFilters.removeLast()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_no_data"), completion: nil)
                }
            }else{
                self.sortFilteredTableComponent  = filterdtbl
            }
            self.refreshWithSortFilter()
        }
    }
    
    func refreshWithSortFilter(){
        DispatchQueue.main.async {
            self.isSortFilterApplied = !self.arrAppliedFilters.isEmpty
            self.collectionView.setContentOffset(.zero, animated: false)
            if self.arrAppliedFilters.isEmpty{
                self.resetToDefault()
            }else{
                self.collectionView.reloadData()
            }
        }
    }
}

//MARK: TableContentCellDelegate

extension FPTableEditViewController: TableContentCellDelegate{
    func duplicateRow(at index: IndexPath, parentTableIndex: IndexPath?) {
        self.view.endEditing(true)
        DispatchQueue.main.async{
            
            _ = FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage: FPLocalizationHelper.localizeWith(args: ["\(index.section)"], key: "msg_duplicate_row"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
                if self.isSortFilterApplied,  var duplicaterow =  self.sortFilteredTableComponent?.rows?[safe:index.section-1]{
                    duplicaterow.columns.indices.forEach { colmIndex in
                        if duplicaterow.columns[colmIndex].uiType == "ATTACHMENT"{
                            duplicaterow.columns[colmIndex].value = ""
                        }
                    }
                    let newRow = self.sortFilteredTableComponent?.addDuplicateRow(columns: duplicaterow.columns, at: index.section)
                    var insertAt = index.section
                    if let orginalIndex = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == duplicaterow.sortUuid }){
                        insertAt = orginalIndex + 1
                    }
                    _ = self.tableComponent?.addDuplicateRow(rowSortId: newRow?.sortUuid, columns: duplicaterow.columns, at: insertAt)
                }else{
                    if var duplicaterow =  self.tableComponent?.rows?[safe:index.section-1]{
//                        self.updateDuplicateAttachment(orginalRow: duplicaterow, index: index, parentTableIndex: parentTableIndex, component: self.tableComponent)
                        duplicaterow.columns.indices.forEach { colmIndex in
                            if duplicaterow.columns[colmIndex].uiType == "ATTACHMENT"{
                                duplicaterow.columns[colmIndex].value = ""
                            }
                        }
                        _ = self.tableComponent?.addDuplicateRow(columns: duplicaterow.columns, at: index.section)
                    }
                }
                self.collectionView.reloadData()
            }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
            
        }
        if let layout = collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.addRow()
            layout.invalidateLayout()
        }
    }
    
    func duplicateMultipleRows(_ arrRows:[Rows]){
        self.view.endEditing(true)
        FPUtility.showHUDWithLoadingMessage()
        self.resetMultipleSeletion()
        let group = DispatchGroup()
        var arrNewRowsIndexs:[Int] = []
        for currentRow in arrRows {
            group.enter()
            var duplicaterow = currentRow
            var newRow:Rows?
            duplicaterow.columns.indices.forEach { colmIndex in
                if duplicaterow.columns[colmIndex].uiType == "ATTACHMENT"{
                    duplicaterow.columns[colmIndex].value = ""
                }
            }
            if self.isSortFilterApplied, let indexSortRow = self.sortFilteredTableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                arrNewRowsIndexs.append(indexSortRow + 1)
                newRow = self.sortFilteredTableComponent?.addDuplicateRow(columns: duplicaterow.columns, at: indexSortRow + 1, isEndOfTable: self.isDuplicateRowAddedEndOFTable)
            }
            if let indexRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                arrNewRowsIndexs.append(indexRow+1)
                _ = self.tableComponent?.addDuplicateRow(rowSortId: newRow?.sortUuid, columns: duplicaterow.columns, at: indexRow+1, isEndOfTable: self.isDuplicateRowAddedEndOFTable)
            }
            group.leave()
        }
        group.notify(queue: DispatchQueue.main) {
            if let layout = self.collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
                layout.addRow(nRow: arrRows.count)
                layout.invalidateLayout()
            }
            FPUtility.hideHUD()
            self.collectionView.reloadData()
            if self.isDuplicateRowAddedEndOFTable{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.collectionView.scrollToBottom(animated: true)
                }
            }
        }
        
    }
    
    
    func deleteRow(at index:IndexPath){
        self.view.endEditing(true)
        DispatchQueue.main.async{
            FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage:FPLocalizationHelper.localizeWith(args: ["\(index.section)"], key: "msg_delete_row"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
                self.deleteIfAnyAssetLinking(index: index)
                if self.isSortFilterApplied{
                    if  let delrow =  self.sortFilteredTableComponent?.rows?[safe:index.section-1], let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == delrow.sortUuid }){
                        self.tableComponent?.deleteRow(at:indexOfRow)
                        self.sortFilteredTableComponent?.deleteSortedRow(at: index.section-1, orginalIndex: indexOfRow)
                    }
                }else{
                    self.tableComponent?.deleteRow(at:index.section-1)
                }
                if let mediaIndex = FPFormDataHolder.shared.tableMediaCache.firstIndex(where: {$0.childTableIndex?.section == index.section && $0.childTableIndex?.row == index.row}){
                    let media = FPFormDataHolder.shared.tableMediaCache[mediaIndex]
                    let medias = FPFormDataHolder.shared.tableMediaCache.filter({$0.childTableIndex!.section-1 > media.childTableIndex!.section-1})
                    medias.forEach { mmedia in
                        var mediaObj = mmedia
                        mediaObj.childTableIndex =  IndexPath(row: mmedia.childTableIndex!.row, section: mmedia.childTableIndex!.section-1)
                        FPFormDataHolder.shared.addUpdateTableMediaCache(media: mediaObj)
                    }
                    FPFormDataHolder.shared.tableMediaCache.remove(at: mediaIndex)
                }else{
                    let cache = FPFormDataHolder.shared.tableMediaCache
                    var tempIndex = 0
                    cache.forEach { media in
                        var mediaObj = media
                        if(mediaObj.childTableIndex!.section>index.section){
                            mediaObj.childTableIndex =  IndexPath(row: mediaObj.childTableIndex!.row, section: mediaObj.childTableIndex!.section-1)
                            FPFormDataHolder.shared.tableMediaCache[tempIndex] = mediaObj
                            tempIndex += 1
                        }
                    }
                }
                self.collectionView.reloadData()
            }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
            
        }
        if let layout = collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.removeRow()
            layout.invalidateLayout()
        }
    }
    
    func deleteMultipleRows(_ arrRows:[Rows]){
        self.view.endEditing(true)
        FPUtility.showHUDWithLoadingMessage()
        if self.isSelectedAll{
            self.addEmptyRowToTable()
        }
        self.resetMultipleSeletion()
        let group = DispatchGroup()
        for currentRow in arrRows {
            group.enter()
            var assetRowLocalId: String?
            var assetRowId: String?
            if let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                if self.isSortFilterApplied{
                    if let indexSRow = self.sortFilteredTableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                        self.sortFilteredTableComponent?.deleteSortedRow(at: indexSRow, orginalIndex: indexOfRow)
                    }
                }
                if let dictvalue = self.tableComponent?.values?[safe:indexOfRow]{
                    for (key, value) in dictvalue {
                        if key == "__id__"{
                            assetRowId = value as? String
                        }else if key == "__localId__"{
                            assetRowLocalId = value as? String
                        }
                    }
                }
                self.tableComponent?.deleteRow(at:indexOfRow)
            }
            self.upsertDeleteAssetLinking(assetRowId: assetRowId, assetRowLocalId: assetRowLocalId)
            group.leave()
        }
        group.notify(queue: DispatchQueue.main) {
            if let layout = self.collectionView.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
                layout.removeRow(nRow: arrRows.count)
                layout.invalidateLayout()
            }
            FPUtility.hideHUD()
            self.collectionView.reloadData()
        }
    }
    
    func updateData(at index:IndexPath, with data:ColumnData, filedData filed:FPFieldDetails?){
        if isSortFilterApplied, let sortCompnt = sortFilteredTableComponent{
            if var row = sortCompnt.rows?[safe:index.section-1]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    sortCompnt.rows?[index.section-1] = row
                    sortFilteredTableComponent = sortCompnt
                }
            }
            if var updateRow =  sortCompnt.rows?[safe:index.section-1], let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == updateRow.sortUuid }){
                if isAutoCalculateEnabled, data.isPartOfFormula == true{
                    updateRow = self.processAutoCalculationFor(row: updateRow, with: data)
                }
                self.tableComponent?.rows?.remove(at: indexOfRow)
                self.tableComponent?.rows?.insert(updateRow, at: indexOfRow)
            }
            if isAutoCalculateEnabled, data.isPartOfFormula == true{
                self.collectionView.reloadSections([index.section])
            }else{
                self.collectionView.reloadItems(at: [index])
            }
        }else if let tblCompnt = tableComponent, let _ = tableIndexPath{
            if var row = tblCompnt.rows?[safe:index.section-1]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    tblCompnt.rows?[index.section-1] = row
                    tableComponent = tblCompnt
                    if isAutoCalculateEnabled, data.isPartOfFormula == true, let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == row.sortUuid }){
                        let autoCalRow = self.processAutoCalculationFor(row: row, with: data)
                        self.tableComponent?.rows?.remove(at: indexOfRow)
                        self.tableComponent?.rows?.insert(autoCalRow, at: indexOfRow)
                    }
                }
            }
            if isAutoCalculateEnabled, data.isPartOfFormula == true{
                self.collectionView.reloadSections([index.section])
            }else{
                self.collectionView.reloadItems(at: [index])
            }
        }
    }
    
    func processAutoCalculationFor(row: Rows, with data:ColumnData) -> Rows{
        var updatedRow = row
        for formula in arrTblFormulas {
            var orginalExpression = formula.expression ?? ""
            for column in updatedRow.columns {
                let dblvalue = (column.value.replacingOccurrences(of: "__X2E__", with: ".") as NSString).doubleValue
                let strDblVal = String(format: "%.2f", dblvalue)
                orginalExpression = orginalExpression.replacingOccurrences(of: "\\b\(column.key)\\b", with: strDblVal, options: .regularExpression)
            }
            if let columnIndex = row.columns.firstIndex(where: {$0.key == formula.name}){
                if let dblvalue = zenFormsDelegate?.safelyEvaluteExpression(strExpression: orginalExpression) as? Double{
                    updatedRow.columns[columnIndex].value = String(format: "%.2f", dblvalue)
                }else{
                    updatedRow.columns[columnIndex].value = "-"
                }
//                //resultColmun
//                if let dblvalue = NSExpression(format: orginalExpression).expressionValue(with: nil, context: nil) as? Double{
//                    updatedRow.columns[columnIndex].value = String(format: "%.2f", dblvalue)
//                }
            }
        }
        return updatedRow
    }
    
    func showAddAttachment(at index:IndexPath,with data:ColumnData){
        self.view.endEditing(true)
        self.attachmentIndex = index
        self.attachmentColumnData = data
        let attachmentView =  TableAttachementView.instance
        attachmentView.parentViewController = self
        attachmentView.delegate = self
        attachmentView.attachmentValue = data.value
        attachmentView.showAttachmentPicker()
    }
    
    func showBarcodeScanner(at index:IndexPath,with data:ColumnData){
        self.linkAsset(at: index, parentTableIndex: tableIndexPath)
    }
    
}

extension UIScrollView {
    func scrollToBottom(animated: Bool) {
        let y = contentSize.height - 1
        let rect = CGRect(x: 0, y: y + safeAreaInsets.bottom, width: 1, height: 1)
        scrollRectToVisible(rect, animated: animated)
    }
}


//MARK: Attachment picker delegate
extension FPTableEditViewController: AttachmentPickerDelegate{
    func onMediaSave(mediaAdded: [SSMedia], mediaDeleted: [SSMedia]) {
        if let index = attachmentIndex,let data = attachmentColumnData{
            if isSortFilterApplied, let sortCompnt = sortFilteredTableComponent, let attachrow = sortCompnt.rows?[index.section-1], let tblRowIndex = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == attachrow.sortUuid }){
                let currentMainTblRow = self.tableComponent?.rows?[safe:tblRowIndex]
                let attachIndexPath  = IndexPath(row: index.row, section: tblRowIndex + 1)
                let tableMedia = TableMedia(columnIndex: attachIndexPath.row, key: data.key, parentTableIndex:tableIndexPath!, childTableIndex: attachIndexPath, mediaAdded: mediaAdded.filter({$0.id?.isEmpty ?? true}), mediaDeleted: mediaDeleted)
                FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                let result =  FPFormDataHolder.shared.getValueFromTableMedia(tableMedia: tableMedia, tableValues: tableComponent?.values)
                if let component  = tableComponent{
                    component.values = result?.valueArray ?? []
                    var row = component.rows![tableMedia.childTableIndex!.section -  1]
                    if let columnIndex = row.columns.firstIndex(where: {$0.key == tableMedia.key}){
                        var column  = row.columns[columnIndex]
                        if let currentColumn = currentMainTblRow?.columns[safe:columnIndex], currentColumn.uiType == "ATTACHMENT", currentColumn.value.trim.isEmpty {
                            var mediaDict:[String:Any] = [:]
                            mediaDict["files"] = []
                            if let dictValue = result?.columnValue.getDictonary(){
                                mediaDict["filesToUpload"] = dictValue["filesToUpload"]
                                mediaDict["filesToDelete"] = dictValue["filesToDelete"]
                            }
                            column.value = mediaDict.getJson()
                        }else{
                            column.value = result?.columnValue ?? ""
                        }
                        row.columns[columnIndex] = column
                    }
                    component.rows![tableMedia.childTableIndex!.section-1] = row
                    self.tableComponent = component
                    if let indexOfRow = self.sortFilteredTableComponent?.rows?.firstIndex(where: { $0.sortUuid == attachrow.sortUuid }){
                        self.sortFilteredTableComponent?.rows?.remove(at: indexOfRow)
                        self.sortFilteredTableComponent?.rows?.insert(row, at: indexOfRow)
                    }
                }
            }else{
                let tableMedia = TableMedia(columnIndex: index.row, key: data.key, parentTableIndex:tableIndexPath!, childTableIndex: index, mediaAdded: mediaAdded.filter({$0.id?.isEmpty ?? true}), mediaDeleted: mediaDeleted)
                FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                let result =  FPFormDataHolder.shared.getValueFromTableMedia(tableMedia: tableMedia, tableValues: tableComponent?.values)
                if let component  = tableComponent{
                    component.values = result?.valueArray ?? []
                    var row = component.rows![tableMedia.childTableIndex!.section-1]
                    if let columnIndex = row.columns.firstIndex(where: {$0.key == tableMedia.key}){
                        var column  = row.columns[columnIndex]
                        column.value = result?.columnValue ?? ""
                        row.columns[columnIndex] = column
                    }
                    component.rows![tableMedia.childTableIndex!.section-1] = row
                    self.tableComponent = component
                }
            }
            self.collectionView.reloadData()
        }
    }
    
}

protocol FPTableEditViewControllerDelegate{
    
    func didEditTableData()
}

//MARK: Asset Linking

extension FPTableEditViewController{
 
    func linkAsset(at index: IndexPath, parentTableIndex: IndexPath?) {
        self.view.endEditing(true)
        self.resetMultipleSeletion()
        var assetRow: Rows?
        var assetRowLocalId: String?
        var assetRowId: String?
        var dictValue: [String:Any]?
        if self.isSortFilterApplied, let currentRow = self.sortFilteredTableComponent?.rows?[safe:index.section-1]{
            assetRow = currentRow
            if let indexCRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                dictValue = self.tableComponent?.values?[safe:indexCRow]
            }
        }else{
            assetRow = self.tableComponent?.rows?[safe:index.section-1]
            dictValue = self.tableComponent?.values?[safe:index.section-1]
        }
        
        if let dictvalue = dictValue{
            for (key, value) in dictvalue {
                if key == "__id__"{
                    assetRowId = value as? String
                }else if key == "__localId__"{
                    assetRowLocalId = value as? String
                }
            }
        }
        
        var showAssetLinkedError = false
        if let assetIdColumIndex = assetRow?.columns.firstIndex(where: {(($0.getUIType() == .HIDDEN) && ($0.key.lowercased() == hiddenAssetIdColumnKey.lowercased()))}), let currentOne =  assetRow?.columns[safe:assetIdColumIndex]{
            showAssetLinkedError = !currentOne.value.isEmpty
        }

        if let _ =  AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(fieldTemplateId: self.fieldDetails?.templateId ?? "", rowId: assetRowId, rowLocalId: assetRowLocalId, customForm: FPFormDataHolder.shared.customForm).first{
            showAssetLinkedError = true
        }
        
        if showAssetLinkedError{
            DispatchQueue.main.async{
                _ = FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage: FPLocalizationHelper.localize("msg_asset_already_linked_row"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
                    self.assetLinkIndexPath = index
                    self.fpFormViewController?.linkingDelegate?.openBarcodeScanner(isOverWriteAsset: true, baseVc: self, linkedAssets: self.linkedAssets, fieldTemplateId: self.fieldDetails?.templateId)
                }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: { cancel in
                    self.clearAssetLinkingIndex()
                })
            }
        }else{
            self.continueAssetLinkProcedure(index: index, parentTableIndex: parentTableIndex)
        }
    }
    
    func continueAssetLinkProcedure( index: IndexPath, parentTableIndex: IndexPath?){
        DispatchQueue.main.async{
            _ = FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage: FPLocalizationHelper.localize("msg_link_asset_row_confm"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
                self.assetLinkIndexPath = index
                self.fpFormViewController?.linkingDelegate?.openBarcodeScanner(isOverWriteAsset: false, baseVc: self, linkedAssets: self.linkedAssets, fieldTemplateId: self.fieldDetails?.templateId)
            }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: { cancel in
                self.clearAssetLinkingIndex()
            })
        }
    }
    
    func proceedWithAssetFormLinking(assetData:AssetInspectionData, isScannedResult:Bool, fieldTemplateId: String?){
        if let assetLinkIndexPath = assetLinkIndexPath, self.fieldDetails?.templateId == fieldTemplateId{
            self.resetMultipleSeletion()
            if isScannedResult, !self.linkedAssets.isEmpty{
                var showError = false
                if let assetId = assetData.assetObjectId{
                    //assetId
                    let arrIds = self.linkedAssets.compactMap { $0["assetId"]}
                    if arrIds.contains(assetId){
                        showError = true
                    }
                }else if let assetLocalId = assetData.assetLocalId{
                    //assetLocalId
                    let arrLocalIds = self.linkedAssets.compactMap { $0["assetLocalId"]}
                    if arrLocalIds.contains(assetLocalId){
                        showError = true
                    }
                }
                
                if showError{
                    self.collectionView.reloadData()
                    if let topVc = FPUtility.topViewController(), !topVc.isKind(of: UIAlertController.self){
                        _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_asset_already_linked_form"), completion: nil)
                    }
                    return
                }
            }
            
            var assetRow: Rows?
            var assetRowLocalId: String?
            var assetRowId: String?
            var dictValue: [String:Any]?

            if self.isSortFilterApplied, let currentRow = self.sortFilteredTableComponent?.rows?[safe:assetLinkIndexPath.section-1]{
                assetRow = currentRow
                if let indexCRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }){
                    dictValue = self.tableComponent?.values?[safe:indexCRow]
                }
            }else{
                assetRow = self.tableComponent?.rows?[safe:assetLinkIndexPath.section-1]
                dictValue = self.tableComponent?.values?[safe:assetLinkIndexPath.section-1]
            }
            if let dictvalue = dictValue{
                for (key, value) in dictvalue {
                    if key == "__id__"{
                        assetRowId = value as? String
                    }else if key == "__localId__"{
                        assetRowLocalId = value as? String
                    }
                }
            }
            
            if assetData.isOverWriteAsset{
                self.upsertDeleteAssetLinking(assetRowId: assetRowId, assetRowLocalId: assetRowLocalId)
            }
            if let dictMapping = self.tableComponent?.tableOptions?.assetMapping{
                FPUtility.showHUDWithLoadingMessage()
                dictMapping.forEach { dictkey, dictvalue in
                    if let assetfields = assetData.assetSection?.fields, let assetField = assetfields.filter({ $0.name?.lowercased() == dictvalue.lowercased()}).first{
                        if let mappingColoumnIndex = assetRow?.columns.firstIndex(where: { $0.key.lowercased() == dictkey.lowercased()}){
                            if let currentOne =  assetRow?.columns[safe:mappingColoumnIndex]{
                                if assetField.getUIType() == .DROPDOWN{
                                    let options = assetField.getDropdownOptions()
                                    if let indexItm = options.map({ $0.value}).firstIndex(of: assetField.value ?? "0"), let selected = options[safe: indexItm]{
                                        assetRow?.columns[mappingColoumnIndex].value = selected.label ?? currentOne.value
                                    }
                                }else{
                                    assetRow?.columns[mappingColoumnIndex].value = assetField.value ?? currentOne.value
                                }
                                self.updateData(at: assetLinkIndexPath, with: assetRow!.columns[mappingColoumnIndex], filedData: nil)
                            }
                        }
                    }
                }
                if let assetId = assetData.assetObjectId {
                    if let assetIdColumIndex = assetRow?.columns.firstIndex(where: {(($0.getUIType() == .HIDDEN) && ($0.key.lowercased() == hiddenAssetIdColumnKey.lowercased()))}){
                        if let currentOne =  assetRow?.columns[safe:assetIdColumIndex]{
                            assetRow?.columns[assetIdColumIndex].value = assetId.stringValue
                            self.updateData(at: assetLinkIndexPath, with: assetRow!.columns[assetIdColumIndex], filedData: nil)
                        }
                    }
                }
                upsertAddAssetLinkIntoDB(assetData:assetData, rowLocalId: assetRowLocalId, rowId: assetRowId)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.collectionView.reloadData()
                    FPUtility.hideHUD()
                }
            }
        }
    }
    
    func upsertAddAssetLinkIntoDB(assetData:AssetInspectionData, rowLocalId:String?, rowId:String?){
        let data = AssetFormMappingData()
        data.assetId = assetData.assetObjectId
        data.assetLocalId = assetData.assetLocalId
        data.isAssetSynced = assetData.isAssetSyncedToServer
        data.customFormId = FPUtility.getNumberValue(FPFormDataHolder.shared.customForm?.objectId)
        data.customFormLocalId = FPFormDataHolder.shared.customForm?.sqliteId ?? 0
        data.formTemplateId = FPFormDataHolder.shared.customForm?.templateId ?? "0"
        data.fieldTemplateId =  fieldDetails?.templateId ?? "0"
        data.sectionTemplateId =  sectionDetails?.templateId ?? "0"
        data.tableRowLocalId  = rowLocalId ?? "0"
        data.tableRowId  = rowId
        data.isSyncedToServer = false
        data.sectionLinking = false
        data.addLinking = true
        data.deleteLinking = false
        data.isNotConfirmed = true
        if FPFormDataHolder.shared.customForm?.sqliteId == nil{
            FPFormDataHolder.shared.arrLinkingDB.append(data)
        }else{
            AssetFormLinkingDatabaseManager().upsert(item: data, isAddLinking: true) { success in }
        }
    }
    

    
    func deleteIfAnyAssetLinking(index:IndexPath){
        let component = self.isSortFilterApplied ? self.sortFilteredTableComponent : self.tableComponent
        var assetRowLocalId: String?
        var assetRowId: String?
        var dictValue: [String:Any]?

        if self.isSortFilterApplied, let currentRow = self.sortFilteredTableComponent?.rows?[safe:index.section-1], let indexCRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == currentRow.sortUuid }) {
            dictValue = self.tableComponent?.values?[safe:indexCRow]
        }else{
            dictValue = self.tableComponent?.values?[safe:index.section-1]
        }
        if let dictvalue = dictValue{
            for (key, value) in dictvalue {
                if key == "__id__"{
                    assetRowId = value as? String
                }else if key == "__localId__"{
                    assetRowLocalId = value as? String
                }
            }
        }
        self.upsertDeleteAssetLinking(assetRowId: assetRowId, assetRowLocalId: assetRowLocalId)
    }
    
    
    func upsertDeleteAssetLinking(assetRowId:String?, assetRowLocalId:String?){
        if self.isAssetEnabled, let isAssetTable = self.tableComponent?.tableOptions?.isAssetTable, isAssetTable{
            if let alreadyLinked =  AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(fieldTemplateId: self.fieldDetails?.templateId ?? "", rowId: assetRowId, rowLocalId: assetRowLocalId, customForm: FPFormDataHolder.shared.customForm, isAddLinking: true).first{
                if alreadyLinked.isSyncedToServer{
                    let updated = alreadyLinked
                    updated.deleteLinking = true
                    updated.addLinking = false
                    updated.isSyncedToServer = false
                    updated.isNotConfirmed = false
                    AssetFormLinkingDatabaseManager().upsert(item: updated) { success in }
                }else{
                    AssetFormLinkingDatabaseManager().deleteMapping(fieldTemplateId: fieldDetails?.templateId ?? "0", rowLocalId: assetRowLocalId, rowId: assetRowId, form: FPFormDataHolder.shared.customForm) { success in }
                }
            }
        }
    }
}

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}
