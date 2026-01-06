
//
//  FPChartViewController.swift
//  crm
//
//  Created by apple on 21/02/24.
//  Copyright © 2024 SmartServ. All rights reserved.
//

import UIKit
import SwiftUI
import Charts

class FPChartViewController: UIViewController {
    @IBOutlet weak var collDatasets: UICollectionView!
    @IBOutlet weak var mainScroll: UIScrollView!
    @IBOutlet weak var viewEmptyChart: UIStackView!
    @IBOutlet weak var viewChart: UIView!
    
    var arrChartColors:[String]{
        if let dictChartConts = UserDefaults.dictConstants?["CHART_CONSTANTS"] as? [String:Any]{
            return dictChartConts["lineColors"] as? [String] ?? []
        }else{
            FPFormsServiceManager.getZenFormConstants()
            return []
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
    
    @objc func onDoneButtonTapped(sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }

    
    var lblYAxis:UILabel?
    var fieldItem:FPFieldDetails?
    var fieldIndex = -1
    var sectionIndex = -1
    var arrDatasets = [[String:Any]]()
    var arrXLablels = [String]()
    var cloneItem = FPFieldDetails()
    
    weak var delegate:FPDynamicDataTypeCellDelegate?
    
    private let HEIGHT_HEADER = 40
    private let HEIGHT_CONTENT = 60
    private let OFFSET = 20
    private let WIDTH_CONTENT = 120
    private let WIDTH_HEADER = 60

    var isAnalysed = false
    var isFromHistory = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
    }
    
    
    //MARK: Prepare UI
    
    func prepareUI(){
        cloneItem = fieldItem?.copyFPFieldDetails(false) ?? FPFieldDetails()
        setupCollectionview()
        setBarButtons()
        drawCharts()
    }
    
    //MARK: SetUps
    func setBarButtons(){
        self.navigationItem.title = cloneItem.displayName ?? ""
        if !self.isAnalysed && !self.isFromHistory {
            let saveBtn = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: #selector(saveButtonAction))
            self.navigationItem.rightBarButtonItems = [saveBtn]
        }
    }
    
    func setupCollectionview(){
        collDatasets.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ChartDatasetCollectionCell")
        collDatasets.dataSource = self
        collDatasets.delegate = self
        if let layout = collDatasets.collectionViewLayout as? FPSpreadsheetCollectionViewLayout  {
            layout.delegate = self
        }
    }
    
    @objc func saveButtonAction() {
        self.view.endEditing(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.delegate?.selectedValue(for: self.sectionIndex, fieldIndex: self.fieldIndex, pickerIndex: nil, value: self.cloneItem.value, date: nil, isSectionDuplicationField: false)
            self.navigationController?.popViewController(animated: true)
        })
    }
    
   
    
    func drawCharts(){
        if let dictValue = cloneItem.value?.getDictonary(), !dictValue.isEmpty{
            self.feedDatasets(isRefresh: false)
        }else{
            viewChart.isHidden = true
            viewEmptyChart.isHidden = false
            collDatasets.isHidden = true
        }
    }
    
    
    //MARK: Helper methods
    
    func feedDatasets(isRefresh:Bool = true){
        if let dictValue = cloneItem.value?.getDictonary(), !dictValue.isEmpty{
            arrDatasets = []
            if let value = dictValue["datasets"] as? [[String:Any]]{
                arrDatasets.append(contentsOf: value)
            }
            viewChart.isHidden = arrDatasets.isEmpty
            viewEmptyChart.isHidden = !viewChart.isHidden
            arrXLablels  = []
            if let lablels = dictValue["labels"] as? [String]{
                arrXLablels.append(contentsOf: lablels)
            }
            self.drawSwiftChart(dictValue: dictValue)
            reloadDatasetsColls()
        }
    }
        
    func drawSwiftChart(dictValue:[String:Any]){
        let linechartView = FPUtility().renderSwiftChart(dictValue: dictValue, xLbls: arrXLablels)
        // Wrap the SwiftUI Chart in a UIHostingController
        let hostingController = UIHostingController(rootView: linechartView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Add the hosting controller's view to the CollectionView cell (chartView)
        hostingController.view.bounds = viewChart.bounds
        hostingController.view.backgroundColor = .clear  // Transparent background for SwiftUI chart

        // Add hostingController's view to your CollectionView cell
        viewChart.removeSubviews()
        viewChart.addSubview(hostingController.view)

        // Set constraints to fit within your chartView bounds
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: viewChart.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewChart.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: viewChart.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewChart.bottomAnchor)
        ])
    }
    
    
    func reloadDatasetsColls(){
        collDatasets.isHidden = arrXLablels.isEmpty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.collDatasets.reloadData()
            self.collDatasets.layoutIfNeeded()
            FPUtility.hideHUD()
        }
    }
    
    //MARK: Action methods

    
    @objc func configureChartClicked(_ sender: UIButton) {
        let chartSettingVC =  ConfigureChartViewController(nibName: "ConfigureChartViewController", bundle: ZenFormsBundle.bundle)
        chartSettingVC.fieldItem = cloneItem
        chartSettingVC.delegate = self
        let navController = UINavigationController(rootViewController: chartSettingVC)
        if UIDevice.current.userInterfaceIdiom == .pad{
            navController.presentAsPopoverFP(self.view, rect: CGRectMake(CGRectGetMidX(self.view.bounds), 80,0,0), permittedArrowDirections: UIPopoverArrowDirection(), preferredContentSize: CGSize(width: 300, height: 500), base: self)
        } else {
            present(navController, animated: true)
        }
    }
    
    @IBAction func btnChartSettigsClicked(_ sender: UIButton) {
        self.configureChartClicked(sender)
    }
    
    
    @IBAction func addDatasetClicked(_ sender: UIButton) {
        
        guard !arrChartColors.isEmpty else {
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_constatnts_not_avlble"), completion: nil)
            return
        }
        
        guard !arrXLablels.isEmpty else {
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_add_label"), completion: nil)
            return
        }
                
        guard arrDatasets.count < arrChartColors.count else {
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_max_Dataset_reached"), completion: nil)
            return
        }
        
        var takenColors:[String] = []
        if let dictValue = cloneItem.value?.getDictonary(), !dictValue.isEmpty, let arrDatasets = dictValue["datasets"] as? [[String:Any]]{
            takenColors = arrDatasets.map { $0["borderColor"] as? String ?? "#EE5566"}
        }
        let newColor = arrChartColors.filter { !takenColors.contains($0) }.first ??  "#EE5566"
        
        if let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty{
            var arrDatasets = dictValue["datasets"] as? [[String:Any]] ?? []
            for dataset in arrDatasets {
                if let name = dataset["label"] as? String, name.trim.isEmpty{
                    _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_valid_Dataset_name"), completion: nil)
                    return
                }
            }
            var newDict = [String:Any]()
            for (key, value) in dictValue {
                newDict[key] = value
            }
            var newDataset = [String:Any]()
            newDataset["label"] =  "dataset \(arrDatasets.count + 1)"
            var arrEmptyData = [String]()
            for _ in arrXLablels {
                arrEmptyData.append("0.0")
            }
            newDataset["borderColor"] =  newColor
            newDataset["data"] =  arrEmptyData
            newDataset["radius"] =  (UserDefaults.dictConstants?["CHART_CONSTANTS"] as? [String:Any])?["datasetLineDefaultRadius"] as? Double ??  6.0
            newDataset["lineTension"] = (UserDefaults.dictConstants?["CHART_CONSTANTS"] as? [String:Any])?["datasetLineDefaultTension"] as? Double ??  0.5
            newDataset["fill"] =  (UserDefaults.dictConstants?["CHART_CONSTANTS"] as? [String:Any])?["datasetLineFill"] as? Bool ??  false
            takenColors.append(newColor)
            arrDatasets.append(newDataset)
            newDict["datasets"] =  arrDatasets
            self.cloneItem.value = newDict.getJson()
            if let layout = collDatasets.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
                layout.addRow()
            }
            self.feedDatasets()
        }
    }
    
}

// MARK: - UICollectionViewDataSource
extension FPChartViewController: UICollectionViewDataSource {
    // i.e. rows
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let datasets = self.arrDatasets.count
        return (datasets > 0 ? datasets : 0)+1 // +1 headers
    }
    
    // i.e. number of columns
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrXLablels.count+3 // +3 > Color, Action and Name
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartDatasetCollectionCell", for: indexPath)
        cell.backgroundColor = .clear
        
        var isHeaderLblHidden = true
        var isInputHidden = true
        var isRemoveHidden = true
        var isColorHidden = true
        var backgroundColor: UIColor = .white
        var keyboardType:UIKeyboardType = .default
       
        var strHeaderLbl:String = ""
        var btnColor:String = ""
        var strInputValue:String = ""

        switch (column: indexPath.row, row: indexPath.section) {
            // Origin
        case (0, 0):
            isHeaderLblHidden = false
            strHeaderLbl = FPLocalizationHelper.localize("lbl_Color")
            backgroundColor = .lightGray
            break
            
        case (1, 0):
            isHeaderLblHidden = false
            strHeaderLbl = FPLocalizationHelper.localize("Delete")
            backgroundColor = .lightGray
            break
            
            
        case (2, 0):
            isHeaderLblHidden = false
            strHeaderLbl = FPLocalizationHelper.localize("lbl_Name")
            backgroundColor = .lightGray
            break
            
            // Top row - Header
        case (_, 0):
            isHeaderLblHidden = false
            strHeaderLbl = self.arrXLablels[safe:indexPath.row - 3] ?? ""
            backgroundColor = .lightGray
            break
            
            // Left column -color
        case (0, _):
            isColorHidden = false
            if let hexColor = arrDatasets[safe: indexPath.section - 1]?["borderColor"]  as? String, !hexColor.contains("rgb"){
                btnColor = hexColor
            }
            break
            
            //Action column
        case (1, _):
            isRemoveHidden =  false
            break
            
            // Left column -name
        case (2, _):
            isInputHidden =  false
            keyboardType = .default
            strInputValue = arrDatasets[safe: indexPath.section - 1]?["label"]  as? String ?? ""
            break
            
            // Inner-content
        default:
            isInputHidden =  false
            keyboardType = .decimalPad
            if let arrData = arrDatasets[safe: indexPath.section - 1]?["data"] as? [String], let value = arrData[safe:indexPath.row-3]{
                strInputValue = value
            }else{
                strInputValue = "0.0"
            }
        }
        
        cell.contentConfiguration = UIHostingConfiguration {
            ChartDatasetCollectionCell(
                lblHeader: strHeaderLbl,
                isHeaderLblHidden: isHeaderLblHidden,
                strDatasetValue: strInputValue,
                keyboardType: keyboardType,
                isInputHidden: isInputHidden,
                cellIndxPath: indexPath,
                onDatasetValueEditChanged: { strValue in
//                    if indexPath.row != 2 {
//                        //other than dataset name field
//                        let allowedCharacters = CharacterSet(charactersIn: "1234567890.")
//                        let characterSet = CharacterSet(charactersIn: strValue)
//                        return allowedCharacters.isSuperset(of: characterSet)
//                    }
//
                    if indexPath.row == 2, strValue.trim.isEmpty == true{
                        _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_Dataset_noblank_name"), completion: nil)
                        strInputValue = self.arrDatasets[safe: indexPath.section - 1]?["label"] as? String ?? strValue
                        return
                    }
                    if indexPath.row != 2, strValue == "0." || strValue.isEmpty{
                        strInputValue = "0.0"
                    }
                    if indexPath.row != 2, Double(strValue) == nil{
                        strInputValue = (self.arrDatasets[safe:indexPath.section - 1]?["data"] as? [String])?[safe:indexPath.row - 3] ?? strValue
                        _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), andMessage: FPLocalizationHelper.localize("msg_chart_valid_dataset_value"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("OK"), style: .default, andHandler: { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                //textField.becomeFirstResponder()
                            }
                        }, withNegativeAction: nil, style: .default, andHandler: nil)
                        return
                    }
                    self.onDatasetEditedAt(indexPth: indexPath, datasetValue: strValue)
                },
                isRemoveHidden: isRemoveHidden,
                onRemove: {
                    self.btnDatasetRemoveTapedAt(indexPath)
                },
                backColor: Color(backgroundColor),
                isColorHidden: isColorHidden,
                strColor: btnColor) {
                    self.btnDatasetColorTapedAt(indexPath, cell: cell)
                }
        }
        .margins(.all, 0)
        return cell
    }
    
    func btnDatasetRemoveTapedAt(_ indexPth: IndexPath){
        DispatchQueue.main.async{
            _ = FPUtility.showAlertController(title:FPLocalizationHelper.localize("alert_dialog_title"), andMessage: "\(FPLocalizationHelper.localize("msg_chart_delete_dataset_confrm"))" + "\(self.arrDatasets[safe: indexPth.section - 1]?["label"]  as? String ?? "")?", completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .destructive, andHandler: { (action) in
                if let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty{
                    var newDict = [String:Any]()
                    for (key, value) in dictValue {
                        newDict[key] = value
                    }
                    var arrDatasets = dictValue["datasets"] as? [[String:Any]] ?? []
                    arrDatasets.remove(at: indexPth.section - 1)
                    newDict["datasets"] =  arrDatasets
                    self.cloneItem.value = newDict.getJson()
                    _  = FPUtility.showHUDWithDeleteMessage()
                    self.feedDatasets()
                    if let layout = self.collDatasets.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
                        layout.removeRow()
                        layout.invalidateLayout()
                    }
                }
            }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
        }
    }
    
    
    func btnDatasetColorTapedAt(_ indexPth: IndexPath, cell:UICollectionViewCell){
        if let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty {
            let colorVC =  DatasetColorPickerViewController(nibName: "DatasetColorPickerViewController", bundle: ZenFormsBundle.bundle)
            colorVC.fieldItem = cloneItem
            colorVC.delegate = self
            colorVC.indexPath = indexPth
            var datasetColr:String?
            if let hexColor = arrDatasets[safe: indexPth.section - 1]?["borderColor"]  as? String, !hexColor.contains("rgb"){
                datasetColr = hexColor
            }
            colorVC.selectedColor = datasetColr
            let navController = UINavigationController(rootViewController: colorVC)
            if UIDevice.current.userInterfaceIdiom == .pad{
                navController.presentAsPopoverFP(cell, permittedArrowDirections: .any, preferredContentSize: CGSize(width: 300, height: 500), base: self)
            } else {
                present(navController, animated: true)
            }
        }
    }
    
    func onDatasetEditedAt(indexPth: IndexPath, datasetValue: String?) {
        if let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty {
            var newDict = [String:Any]()
            var isRefreshNeeded = false
            for (key, value) in dictValue {
                newDict[key] = value
            }
            var arrDatasets = newDict["datasets"] as? [[String:Any]] ?? []
            if let _ = arrDatasets[safe: indexPth.section - 1]{
                if indexPth.row == 2{
                    //dataset name
                    if let name = arrDatasets[safe: indexPth.section - 1]?["label"] as? String, let new = datasetValue, name != new{
                        arrDatasets[indexPth.section - 1]["label"] = new
                        isRefreshNeeded = true
                    }
                }else{
                    //values
                    var arrData = arrDatasets[safe:indexPth.section - 1]?["data"] as? [String]  ?? []
                    if let value = arrData[safe:indexPth.row - 3], let new  = datasetValue, value != new{
                        arrData[indexPth.row - 3] = new
                        arrDatasets[indexPth.section - 1]["data"] = arrData
                        isRefreshNeeded = true
                    }
                }
            }
            if isRefreshNeeded{
                newDict["datasets"] = arrDatasets
                self.cloneItem.value = newDict.getJson()
                self.feedDatasets()
            }
        }
    }


    
}


// MARK: - DatasetColorDelegate
extension FPChartViewController: DatasetColorDelegate {
    func datasetColorSelected(color: String, for indexPath: IndexPath) {
        if let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty{
            var newDict = [String:Any]()
            for (key, value) in dictValue {
                newDict[key] = value
            }
            var arrDatasets = dictValue["datasets"] as? [[String:Any]] ?? []
            if let _ = arrDatasets[safe:indexPath.section - 1]{
                arrDatasets[indexPath.section - 1]["borderColor"] = color
            }
            newDict["datasets"] =  arrDatasets
            self.cloneItem.value = newDict.getJson()
            self.feedDatasets()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FPChartViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

// MARK: - ConfigureChartDelegate
extension FPChartViewController: ConfigureChartDelegate {
    func removeColumn() {
        if let layout = self.collDatasets.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.removeColumn()
            layout.invalidateLayout()
        }
    }
    
    func addColumn() {
        if let layout = self.collDatasets.collectionViewLayout as? FPSpreadsheetCollectionViewLayout{
            layout.addColumn()
            layout.invalidateLayout()
        }
    }
    
    func refreshChart(dictValue: [String:Any]) {
        self.cloneItem.value = dictValue.getJson()
        self.feedDatasets(isRefresh: true)
    }
}

// MARK: - UITextFieldDelegate
extension FPChartViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let position = textField.convert(CGPoint.zero, to: self.collDatasets)
        guard let indexPth = self.collDatasets.indexPathForItem(at: position) else {
            return true
        }
        if indexPth.row != 2, let value = textField.text, Double(value) == 0{
            textField.text = ""
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let position = textField.convert(CGPoint.zero, to: self.collDatasets)
        guard let indexPth = self.collDatasets.indexPathForItem(at: position) else {
            return
        }
        if indexPth.row == 2, textField.text?.trim.isEmpty == true{
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_Dataset_noblank_name"), completion: nil)
            textField.text = arrDatasets[safe: indexPth.section - 1]?["label"] as? String
            return
        }
        if indexPth.row != 2, textField.text == "0." || (textField.text?.isEmpty ?? false){
            textField.text = "0.0"
        }
        if indexPth.row != 2, let value = textField.text, Double(value) == nil{
            textField.text = (self.arrDatasets[safe:indexPth.section - 1]?["data"] as? [String])?[safe:indexPth.row - 3]
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), andMessage: FPLocalizationHelper.localize("msg_chart_valid_dataset_value"), completion: nil, withPositiveAction: FPLocalizationHelper.localize("OK"), style: .default, andHandler: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    textField.becomeFirstResponder()
                }
            }, withNegativeAction: nil, style: .default, andHandler: nil)
            return
        }
        if let indexPth = self.collDatasets.indexPathForItem(at: position), let dictValue = self.cloneItem.value?.getDictonary(), !dictValue.isEmpty {
            var newDict = [String:Any]()
            var isRefreshNeeded = false
            for (key, value) in dictValue {
                newDict[key] = value
            }
            var arrDatasets = newDict["datasets"] as? [[String:Any]] ?? []
            if let _ = arrDatasets[safe: indexPth.section - 1]{
                if indexPth.row == 2{
                    //dataset name
                    if let name = arrDatasets[safe: indexPth.section - 1]?["label"] as? String, let new = textField.text, name != new{
                        arrDatasets[indexPth.section - 1]["label"] = new
                        isRefreshNeeded = true
                    }
                }else{
                    //values
                    var arrData = arrDatasets[safe:indexPth.section - 1]?["data"] as? [String]  ?? []
                    if let value = arrData[safe:indexPth.row - 3], let new  = textField.text, value != new{
                        arrData[indexPth.row - 3] = new
                        arrDatasets[indexPth.section - 1]["data"] = arrData
                        isRefreshNeeded = true
                    }
                }
            }
            if isRefreshNeeded{
                newDict["datasets"] = arrDatasets
                self.cloneItem.value = newDict.getJson()
                self.feedDatasets()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let position = textField.convert(CGPoint.zero, to: self.collDatasets)
        if let indexPth = self.collDatasets.indexPathForItem(at: position),  indexPth.row != 2 {
            let allowedCharacters = CharacterSet(charactersIn: "1234567890.")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}

// MARK: - SpreadsheetLayoutDelegate
extension FPChartViewController: SpreadsheetCollectionViewLayoutDelegate {
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
