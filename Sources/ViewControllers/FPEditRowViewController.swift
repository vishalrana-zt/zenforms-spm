//
//  FPEditRowViewController.swift
//  ZenForms
//
//  Created by apple on 27/02/26.
//

import UIKit
internal import SSMediaManager
internal import TagListView
import MobileCoreServices
import UniformTypeIdentifiers
import Photos
import PhotosUI
internal import IQKeyboardManagerSwift
import SwiftUI
internal import ZTExpressionEngine



class FPEditRowViewController: UIViewController, UINavigationControllerDelegate {
  
    @IBOutlet weak var viewBottom: UIView!
    @IBOutlet weak var tblRows: UITableView!
    @IBOutlet weak var btnPrevious: ZTLIBLoaderButton!
    @IBOutlet weak var btnNext: ZTLIBLoaderButton!
    @IBOutlet weak var txtRow: UITextField!
    @IBOutlet weak var lblCurrentRow: UILabel!
   
    var tableComponent:TableComponent?
    var currentRowNo:Int = 0
    var tableIndexPath:IndexPath?

    var attachmentIndex:IndexPath?
    var attachmentColumnData: ColumnData?

    var arrTblFormulas = [ColumnFormula]()
    var isAutoCalculateEnabled: Bool = false

    var didEditedRows:((_ tableComponent:TableComponent?)->())?

    fileprivate let fileManager = FileManager.default
        
    fileprivate func setUpTableView() {
        tblRows.register(UINib(nibName: "FPEditRowTableViewCell", bundle: ZenFormsBundle.bundle), forCellReuseIdentifier: "FPEditRowTableViewCell")
        tblRows.delegate = self
        tblRows.dataSource = self
        tblRows.rowHeight = UITableView.automaticDimension
        tblRows.estimatedRowHeight = 200
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.enableAutoToolbar = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = false
        IQKeyboardManager.shared.enableAutoToolbar = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func initializeView() {
        view.backgroundColor = .systemBackground
        txtRow.keyboardType = .numberPad
        txtRow.delegate = self
        
        btnPrevious.currentView = self.navigationController?.view ?? self.view
        btnNext.currentView = self.navigationController?.view ?? self.view
        
        reflectCurrentRowOnUI()
        viewBottom.dropShadow()
        setUpTableView()
        handleSectionControlUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        SCREEN_WIDTH_S = size.width
        DispatchQueue.main.async {
            self.tblRows.reloadData()
        }
    }
    
    
   
    
    func setupNavBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style: .plain, target: self, action: #selector(saveButtonAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(cancelButtonAction))
    }
    
    //MARK: - ViewController button actions

    
    @IBAction func previousButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.btnPrevious.isLoading = true
        self.btnNext.updateInteraction(isEnabled: false)
        self.showPreviousSection()
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.btnNext.isLoading = true
        self.btnPrevious.updateInteraction(isEnabled: false)
        self.showNextSection()
    }
    
    func showNextSection(){
        if self.currentRowNo <= (self.tableComponent?.rows?.count ?? 0) - 1{
            self.currentRowNo += 1
            handleSectionControlUI()
        }else{
            self.stopLoadings()
        }
    }
    
    func showPreviousSection(){
        if self.currentRowNo > 0{
            self.currentRowNo -= 1
            self.handleSectionControlUI()
        }else{
            self.stopLoadings()
        }
    }
    
    func handleSectionControlUI(){
        self.stopLoadings()
        DispatchQueue.main.async {
            let rows = self.tableComponent?.rows ?? []
            if rows.count == 1{
                self.btnPrevious.isHidden = true
                self.btnNext.isHidden = true
                return
            }else{
                self.btnPrevious.isHidden = false
                self.btnNext.isHidden = false
            }
            self.handleSectionButtonsInteraction()
            self.tblRows.reloadData()
        }
    }
    
    func handleSectionButtonsInteraction(){
        let rows = self.tableComponent?.rows ?? []
        DispatchQueue.main.async {
            self.btnPrevious.updateInteraction(isEnabled: self.currentRowNo > 0)
            self.btnNext.updateInteraction(isEnabled: self.currentRowNo < rows.count - 1)
            self.reflectCurrentRowOnUI()
        }
    }
    
    func reflectCurrentRowOnUI(){
        lblCurrentRow.text = "\(currentRowNo + 1)"
        txtRow.text = "\(currentRowNo + 1)"
    }
    
    
    //MARK: - Navigation bar button actions
    
    @objc func saveButtonAction() {
        self.view.endEditing(true)
        self.navigationController?.dismiss(animated: true) {
            self.didEditedRows?(self.tableComponent)
        }
    }
    
    func stopLoadings(){
        DispatchQueue.main.async {
            self.btnNext.isLoading = false
            self.btnPrevious.isLoading = false
            self.handleSectionButtonsInteraction()
        }
    }
        
    @objc func cancelButtonAction() {
        self.navigationController?.dismiss(animated: true) {}
    }
  
}


extension FPEditRowViewController: UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableComponent?.rows?[safe:currentRowNo]?.columns.filter({ $0.getUIType() != .HIDDEN}).count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FPEditRowTableViewCell",
            for: indexPath
        ) as! FPEditRowTableViewCell
        
        // Use 1-based section so TableMedia matches FPFormDataHolder convention (valueArray[section - 1])
        cell.childTableIndex = IndexPath(row: indexPath.row, section: currentRowNo + 1)
        cell.parentTableIndex = tableIndexPath
        cell.data = self.tableComponent?.rows?[safe:currentRowNo]?.columns.filter({ $0.getUIType() != .HIDDEN})[safe: indexPath.row]
        cell.delegate = self
        return cell
    }
    
    private func safeReloadRows(_ indexPaths: [IndexPath]) {
        let section = 0
        let maxRows = tblRows.numberOfRows(inSection: section)
        
        let validPaths = indexPaths.filter { $0.row >= 0 && $0.row < maxRows }
        guard !validPaths.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.tblRows.beginUpdates()
            self.tblRows.reloadRows(at: validPaths, with: .automatic)
            self.tblRows.endUpdates()
        }
    }
    
    /// Reloads only the attachment column row so the table does not scroll to top.
    fileprivate func reloadAttachmentRowOnly(columnKey: String) {
        let filtered = tableComponent?.rows?[safe: currentRowNo]?.columns.filter { $0.getUIType() != .HIDDEN } ?? []
        guard let rowIndex = filtered.firstIndex(where: { $0.key == columnKey }) else { return }
        let indexPath = IndexPath(row: rowIndex, section: 0)
        let maxRows = tblRows.numberOfRows(inSection: 0)
        guard rowIndex >= 0, rowIndex < maxRows else { return }
        DispatchQueue.main.async {
            let offset = self.tblRows.contentOffset
            self.tblRows.reloadRows(at: [indexPath], with: .none)
            self.tblRows.contentOffset = offset
        }
    }
}

extension FPEditRowViewController:UITextFieldDelegate{
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        if textField == txtRow {
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let number = Int(textField.text ?? "") ?? 0
        let rowCount = self.tableComponent?.rows?.count ?? 0
        if number >= 1, number <= rowCount {
            DispatchQueue.main.async {
                _ = FPUtility.showAlertController(title: FPLocalizationHelper.localize("alert_dialog_title"), andMessage: "Do you want to move to row no: \(number) ?", completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .default, andHandler: { (action) in
                    self.currentRowNo = number - 1
                    self.handleSectionControlUI()
                }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
            }
        } else {
            self.reflectCurrentRowOnUI()
            _ = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: "The Row number \(number) is not present in the table.", completion: nil)
        }
    }
}


//MARK: FPEditRowCellDelegate

extension FPEditRowViewController: FPEditRowCellDelegate{
    func updateRow(with data: ColumnData) {
        if let tblCompnt = tableComponent, let _ = tableIndexPath{
            if var row = tblCompnt.rows?[safe:currentRowNo]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    tblCompnt.rows?[currentRowNo] = row
                    tableComponent = tblCompnt
                    if isAutoCalculateEnabled, data.isPartOfFormula == true, let indexOfRow = self.tableComponent?.rows?.firstIndex(where: { $0.sortUuid == row.sortUuid }){
                        let autoCalRow = self.processAutoCalculationFor(row: row, with: data)
                        self.tableComponent?.rows?.remove(at: indexOfRow)
                        self.tableComponent?.rows?.insert(autoCalRow, at: indexOfRow)
                    }
                }
            }
            if isAutoCalculateEnabled, data.isPartOfFormula == true{
                self.tblRows.reloadData()
            }
        }
    }
    
    func inferValue(_ value: String) -> Any {
        let replaced = value.replacingOccurrences(of: "__X2E__", with: ".")
        let trimmed = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = Double(trimmed) {
            return number
        }
        return trimmed
    }
    
    
    func showRowAttachment(at index:IndexPath,with data:ColumnData){
        self.view.endEditing(true)
        self.attachmentIndex = index
        self.attachmentColumnData = data
        let attachmentView = TableAttachementView.instance
        attachmentView.parentViewController = self
        attachmentView.delegate = self
        attachmentView.attachmentValue = data.value
        attachmentView.showAttachmentSourcePickerOnly(sourceView: view)
    }
    
    func didRemoveAttachment(at index: IndexPath, columnData: ColumnData, fileName: String) {
        guard let tableIndexPath = tableIndexPath,
              let component = tableComponent,
              let rows = component.rows,
              index.section >= 1,
              index.section - 1 < rows.count else { return }
        let row = rows[index.section - 1]
        guard let columnIndex = row.columns.firstIndex(where: { $0.key == columnData.key }) else { return }
        let column = row.columns[columnIndex]
        let dataObject = column.value.getDictonary()
        var mediaAdded: [SSMedia] = []
        var mediaDeleted: [SSMedia] = []
        let cached = FPFormDataHolder.shared.tableMediaCache.first(where: { $0.parentTableIndex == tableIndexPath && $0.childTableIndex == index })
        mediaAdded = (cached?.mediaAdded ?? []).filter { $0.name != fileName }
        mediaDeleted = cached?.mediaDeleted ?? []
        let wasInMediaAdded = (cached?.mediaAdded.contains(where: { $0.name == fileName })) ?? false
        if !wasInMediaAdded, let files = dataObject["files"] as? [[String: Any]],
           let file = files.first(where: { ($0["altText"] as? String) == fileName }),
           let id = file["id"] as? String, !id.isEmpty {
            mediaDeleted.append(SSMedia(name: fileName, id: id, mimeType: file["type"] as? String, filePath: file["localPath"] as? String, serverUrl: file["file"] as? String, moduleType: .forms))
        }
        let tableMedia = TableMedia(columnIndex: index.row, key: columnData.key, parentTableIndex: tableIndexPath, childTableIndex: index, mediaAdded: mediaAdded, mediaDeleted: mediaDeleted)
        FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
        guard let result = FPFormDataHolder.shared.getValueFromTableMedia(tableMedia: tableMedia, tableValues: component.values) else { return }
        component.values = result.valueArray
        var updatedRow = rows[index.section - 1]
        if let colIdx = updatedRow.columns.firstIndex(where: { $0.key == columnData.key }) {
            var col = updatedRow.columns[colIdx]
            col.value = result.columnValue ?? ""
            updatedRow.columns[colIdx] = col
        }
        component.rows?[index.section - 1] = updatedRow
        tableComponent = component
        reloadAttachmentRowOnly(columnKey: columnData.key)
    }
    
    func showBarcodeScanner(at index:IndexPath,with data:ColumnData){}
    
    func processAutoCalculationFor(row: Rows, with data:ColumnData) -> Rows{
        var updatedRow = row
        for formula in arrTblFormulas {
            let orginalExpression = formula.expression ?? ""
            var rawVars: [String: Any] = [:]
            for column in updatedRow.columns {
                if orginalExpression.range(of: "\\b\(column.key)\\b", options: .regularExpression) != nil {
                    rawVars[column.key] = self.inferValue(column.value)
                }
            }
            if let columnIndex = row.columns.firstIndex(where: {$0.key == formula.name}){
                debugPrint("formula: \(orginalExpression)")
                debugPrint("variables: \(rawVars)")
                do {
                    let value = try ZTExpressionEngine.evaluate(orginalExpression, variables: rawVars)
                    debugPrint("result: \(value)")
                    if let dbvalue = value as? Double{
                        updatedRow.columns[columnIndex].value = dbvalue.formattedMax2Decimal()
                    }else if let strVal = value as? String{
                        updatedRow.columns[columnIndex].value = strVal
                    }else{
                        updatedRow.columns[columnIndex].value = "-"
                    }
                } catch {
                    debugPrint(error)
                }
            }
        }
        return updatedRow
    }
    
}

//MARK: Attachment picker delegate
extension FPEditRowViewController: AttachmentPickerDelegate{
    func onMediaSave(mediaAdded: [SSMedia], mediaDeleted: [SSMedia]) {
        guard let index = attachmentIndex, let data = attachmentColumnData, let tableIndexPath = tableIndexPath else { return }
        let tableMedia = TableMedia(columnIndex: index.row, key: data.key, parentTableIndex: tableIndexPath, childTableIndex: index, mediaAdded: mediaAdded.filter({ $0.id?.isEmpty ?? true }), mediaDeleted: mediaDeleted)
        FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
        guard let result = FPFormDataHolder.shared.getValueFromTableMedia(tableMedia: tableMedia, tableValues: tableComponent?.values),
              let component = tableComponent,
              let childIndex = tableMedia.childTableIndex,
              childIndex.section >= 1,
              let rows = component.rows,
              childIndex.section - 1 < rows.count else { return }
        component.values = result.valueArray
        var row = rows[childIndex.section - 1]
        if let columnIndex = row.columns.firstIndex(where: { $0.key == tableMedia.key }) {
            var column = row.columns[columnIndex]
            column.value = result.columnValue ?? ""
            row.columns[columnIndex] = column
        }
        component.rows?[childIndex.section - 1] = row
        self.tableComponent = component
        reloadAttachmentRowOnly(columnKey: data.key)
    }
    
}


final class CardTransitioningDelegate: NSObject,
                                       UIViewControllerTransitioningDelegate {

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {

        CardPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
    }
}


final class CardPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.alpha = 0
        dimmingView.isUserInteractionEnabled = true
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(dismissController))
        )
    }

    @objc private func dismissController() {
        //presentedViewController.dismiss(animated: true)
    }

    override var frameOfPresentedViewInContainerView: CGRect {

        guard let container = containerView else { return .zero }

        let bounds = container.bounds
        _ = container.safeAreaInsets

        let isPad = traitCollection.userInterfaceIdiom == .pad

        if isPad {

            // ⭐ Large editor style
            let width = bounds.width * 0.8
            let height = bounds.height * 0.8

            return CGRect(
                x: (bounds.width - width) / 2,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        } else {

            let width = bounds.width * 0.9
            let height = bounds.height * 0.75

            return CGRect(
                       x: (bounds.width - width) / 2,
                       y: (bounds.height - height) / 2,
                       width: width,
                       height: height
                   )
        }
    }

    override func presentationTransitionWillBegin() {

        guard let container = containerView else { return }

        dimmingView.frame = container.bounds
        container.insertSubview(dimmingView, at: 0)

        presentedViewController.transitionCoordinator?
            .animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            })
    }

    override func dismissalTransitionWillBegin() {

        presentedViewController.transitionCoordinator?
            .animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            })
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 20
        presentedView?.clipsToBounds = true
        presentedView?.layer.shadowColor = UIColor.black.cgColor
        presentedView?.layer.shadowOpacity = 0.15
        presentedView?.layer.shadowRadius = 20
        presentedView?.layer.shadowOffset = CGSize(width: 0, height: 10)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
