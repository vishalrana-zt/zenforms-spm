//
//  FPQueAnsTableEditViewController.swift
//  crm
//
//  Created by apple on 16/10/24.
//  Copyright © 2024 SmartServ. All rights reserved.
//

import UIKit
internal import SSMediaManager
internal import RSSelectionMenu
internal import IQKeyboardManagerSwift
internal import IQKeyboardToolbar
internal import IQKeyboardToolbarManager


class FPQueAnsTableEditViewController: UIViewController {
   
    private let headerCellReuseIdentifier = "TableHeaderCollectionViewCell"
    private let contentCellReuseIdentifier = "TableContentCollectionViewCell"
    
    @IBOutlet weak var collectionView: UICollectionView!
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
    var didCompletedEdit:((_ tableComponent:TableComponent)->())?
    
    var sortFilterColumnIndexPath:IndexPath?
    var sortFilterColumn:Columns?
    var isSortFilterApplied:Bool = false
    var arrAppliedFilters = [SortFilter]()
    
    var viewModel: FPQueAnsCollectionViewModel? {
        didSet {
            guard let layout = collectionView.collectionViewLayout as? FPQueAnsCollectionViewLayout else {
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
    
    var fieldDetails:FPFieldDetails?
    var sectionDetails:FPSectionDetails?
    var fpFormViewController:FPFormViewController?
   
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if !self.isAnalysed && !self.isFromHistory {
            let rightBarButton = UIBarButtonItem(title:FPLocalizationHelper.localize("SAVE"), style:.plain, target: self, action: #selector(saveButtonAction))
            self.navigationItem.rightBarButtonItem = rightBarButton
        }
        
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
        viewModel = FPQueAnsCollectionViewModel()
        viewModel?.widthQuesColumn = WIDTH_QUES_COLUMN
        self.title  = titleText
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    
    @objc func onDoneButtonTapped(sender: UIBarButtonItem) {
        
    }
    
    
    //MARK: Actions
    
    @IBAction func btnOpenClonseDidTap(_ sender: UIButton) {
        self.constLeading.constant = sender.isSelected ? -50.0 : 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        sender.isSelected = !sender.isSelected
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
            self.navigationController?.popViewController(animated: false)
            
        })
    }
    
    @objc func cancelButtonClicked(button:UIButton) {
        view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension FPQueAnsTableEditViewController: FPQueAnsCollectionViewModelDataSource {
    func configure(_ cell: UICollectionViewCell, with content: String, column: ColumnData?, indexPath: IndexPath, isHideMore: Bool, isHideCHeckBoxHeader:Bool) {
        if let contentcell = cell as? TableContentCollectionViewCell {
            contentcell.parentTableIndex = tableIndexPath
            contentcell.childTableIndex = indexPath
            contentcell.data = column
            contentcell.delegate = self
            contentcell.btnAction.isHidden = true
            contentcell.viewBarcode.isHidden = true
        }else if let headerCell = cell as? TableHeaderCollectionViewCell {
            headerCell.imgMore.image =  UIImage(named: "icn_more", in: Bundle(for: type(of: self)), compatibleWith: nil)
            headerCell.imgMore.setImageColor(color: .black)
            headerCell.text = content
            headerCell.viewBtn.isHidden = isHideMore
            headerCell.btnActions.isHidden = true
            headerCell.title.isHidden = !isHideCHeckBoxHeader
            headerCell.btnMore.addTarget(self, action: #selector(btnMoreClicked(sender:)), for: .touchUpInside)
            if isSortFilterApplied == true, let index = arrAppliedFilters.firstIndex(where: { $0.indPath == indexPath}), let appliedFilter = arrAppliedFilters[safe: index]  {
                if appliedFilter.option == .filter {
                    headerCell.imgMore.image = UIImage(named: "icn_filter", in: Bundle(for: type(of: self)), compatibleWith: nil)
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
        if  let sortedIndexPth = sortFilterColumnIndexPath, let shownColumns = self.tableComponent?.tableOptions?.columns?.filter({$0.uiType != "HIDDEN"}), let column = shownColumns[safe:sortedIndexPth.row - 1]{
            sortFilterColumn = column
        }
        if sortFilterColumn?.uiType == "DROPDOWN"{
            displayOptionsPopUp(sender)
        }else{
            displaySortingPopUp(sender)
        }
    }

}

//MARK: Sort Filter Operations
extension FPQueAnsTableEditViewController{
    
    
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
            if  let sortedIndexPth = sortFilterColumnIndexPath, let column = self.tableComponent?.tableOptions?.columns?[safe:sortedIndexPth.row - 1]{
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

extension FPQueAnsTableEditViewController: TableContentCellDelegate{
    func deleteRow(at index: IndexPath) {}
    
    func duplicateRow(at index: IndexPath, parentTableIndex: IndexPath?) {}
    
    
    func updateData(at index: IndexPath, with data: ColumnData, filedData filed: FPFieldDetails?) {
        if isSortFilterApplied, let sortCompnt = sortFilteredTableComponent{
            if var row = sortCompnt.rows?[safe:index.section-1]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    sortCompnt.rows?[index.section-1] = row
                    sortFilteredTableComponent = sortCompnt
                }
            }
            if let updateRow =  sortCompnt.rows?[safe:index.section-1], let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == updateRow.sortUuid }){
                self.tableComponent?.rows?.remove(at: indexOfRow)
                self.tableComponent?.rows?.insert(updateRow, at: indexOfRow)
            }
            self.collectionView.reloadItems(at: [index])
        }else if let tblCompnt = tableComponent, let _ = tableIndexPath{
            if var row = tblCompnt.rows?[safe:index.section-1]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    tblCompnt.rows?[index.section-1] = row
                    tableComponent = tblCompnt
                }
            }
            self.collectionView.reloadItems(at: [index])
        }
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
    
}


//MARK: Attachment picker delegate
extension FPQueAnsTableEditViewController: AttachmentPickerDelegate{
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

protocol FPQueAnsTableEditViewControllerDelegate{
    
    func didEditTableData()
}

