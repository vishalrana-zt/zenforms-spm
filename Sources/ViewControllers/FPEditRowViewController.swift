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
        view.backgroundColor = .systemBackground
        btnPrevious.currentView = self.navigationController?.view ?? self.view
        btnNext.currentView = self.navigationController?.view ?? self.view
        reflectCurrentRowOnUI()
        viewBottom.dropShadow()
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
        txtRow.delegate = self
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(saveButtonAction))
//        self.navigationItem.leftBarButtonItem =  UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(cancelButtonAction))
       
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
        
        cell.childTableIndex = IndexPath(row: indexPath.row, section: currentRowNo)
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

        // Allow normal typing for other textfields
        return true
    }
}


//MARK: FPEditRowCellDelegate

extension FPEditRowViewController: FPEditRowCellDelegate{
    func updateRow(with data: ColumnData) {
        if let tblCompnt = tableComponent, let _ = tableIndexPath{
            if var row = tblCompnt.rows?[safe:currentRowNo - 1]{
                if let columnIndex = row.columns.firstIndex(where: {$0.key == data.key}){
                    row.columns[columnIndex] = data
                    tblCompnt.rows?[currentRowNo - 1] = row
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
        let attachmentView =  TableAttachementView.instance
        attachmentView.parentViewController = self
        attachmentView.delegate = self
        attachmentView.attachmentValue = data.value
        attachmentView.showAttachmentPicker()
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
        if let index = attachmentIndex,let data = attachmentColumnData{
            let tableMedia = TableMedia(columnIndex: index.row, key: data.key, parentTableIndex:tableIndexPath!, childTableIndex: index, mediaAdded: mediaAdded.filter({$0.id?.isEmpty ?? true}), mediaDeleted: mediaDeleted)
            FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
            let result =  FPFormDataHolder.shared.getValueFromTableMedia(tableMedia: tableMedia, tableValues: tableComponent?.values)
            if let component  = tableComponent{
                component.values = result?.valueArray ?? []
                var row = component.rows![tableMedia.childTableIndex!.row]
                if let columnIndex = row.columns.firstIndex(where: {$0.key == tableMedia.key}){
                    var column  = row.columns[columnIndex]
                    column.value = result?.columnValue ?? ""
                    row.columns[columnIndex] = column
                }
                component.rows![tableMedia.childTableIndex!.row] = row
                self.tableComponent = component
                DispatchQueue.main.async {
                    self.tblRows.reloadData()
                }
            }
        }
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
