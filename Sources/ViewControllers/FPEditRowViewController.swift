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



class FPEditRowViewController: UIViewController, UINavigationControllerDelegate {
  
    @IBOutlet weak var viewBottom: UIView!
    @IBOutlet weak var tblRows: UITableView!
    @IBOutlet weak var btnPrevious: ZTLIBLoaderButton!
    @IBOutlet weak var btnNext: ZTLIBLoaderButton!
    @IBOutlet weak var lblCurrentSectionName: UILabel!
    @IBOutlet weak var rowStepper: NumericStepperView!
   
    var tableComponent:TableComponent?

    var currentRowNo = 0
  
    var tableIndexPath:IndexPath?


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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:FPLocalizationHelper.localize("SAVE"), style:.plain, target: self, action: #selector(saveButtonAction))
        self.navigationItem.leftBarButtonItem =  UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(cancelButtonAction))
       
    }
    
    //MARK: - ViewController button actions

    
    @IBAction func previousButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.btnPrevious.isLoading = true
        self.btnNext.updateInteraction(isEnabled: false)
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.btnNext.isLoading = true
        self.btnPrevious.updateInteraction(isEnabled: false)
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
        }
    }
    
    func handleSectionButtonsInteraction(){
        let rows = self.tableComponent?.rows ?? []
        DispatchQueue.main.async {
            self.btnPrevious.updateInteraction(isEnabled: self.currentRowNo > 0)
            self.btnNext.updateInteraction(isEnabled: self.currentRowNo < rows.count - 1)
        }
    }
    
    
    //MARK: - Navigation bar button actions
    
    @objc func saveButtonAction() {
        self.view.endEditing(true)
        
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
        return self.tableComponent?.rows?[safe:currentRowNo]?.columns.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FPEditRowTableViewCell",
            for: indexPath
        ) as! FPEditRowTableViewCell
        
        cell.indexPath = indexPath
        cell.parentIndexPath = tableIndexPath
        cell.data = self.tableComponent?.rows?[safe:currentRowNo]?.columns[safe: indexPath.row]
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




//MARK: FPEditRowCellDelegate

extension FPEditRowViewController: FPEditRowCellDelegate{
   
    func updateData(at index:IndexPath, with data:ColumnData, filedData filed:FPFieldDetails?){
        
    }
    
    func inferValue(_ value: String) -> Any {
        let replaced = value.replacingOccurrences(of: "__X2E__", with: ".")
        let trimmed = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = Double(trimmed) {
            return number
        }
        return trimmed
    }
    
    
    func showAddAttachment(at index:IndexPath,with data:ColumnData){
        self.view.endEditing(true)
//        self.attachmentIndex = index
//        self.attachmentColumnData = data
        let attachmentView =  TableAttachementView.instance
        attachmentView.parentViewController = self
        //attachmentView.delegate = self
        attachmentView.attachmentValue = data.value
        attachmentView.showAttachmentPicker()
    }
    
    func showBarcodeScanner(at index:IndexPath,with data:ColumnData){
        
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
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(dismissController))
        )
    }

    @objc private func dismissController() {
        presentedViewController.dismiss(animated: true)
    }

    override var frameOfPresentedViewInContainerView: CGRect {

        guard let container = containerView else { return .zero }

        let width = min(container.bounds.width * 0.9, 420)
        let height = container.bounds.height * 0.7

        let originX = (container.bounds.width - width) / 2
        let originY = (container.bounds.height - height) / 2

        return CGRect(x: originX,
                      y: originY,
                      width: width,
                      height: height)
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
    }
}
