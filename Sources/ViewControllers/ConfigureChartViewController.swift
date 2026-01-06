//
//  ConfigureChartViewController.swift
//  crm
//
//  Created by apple on 21/02/24.
//  Copyright © 2024 SmartServ. All rights reserved.
//

import UIKit
import SwiftUI

protocol ConfigureChartDelegate: AnyObject {
     func refreshChart(dictValue:[String:Any])
     func removeColumn()
     func addColumn()
}

class ConfigureChartViewController: UIViewController {
    @IBOutlet weak var tblLabels: AutoSizeTableView!
    @IBOutlet weak var lblChartTitle: UITextField!
    @IBOutlet weak var lblXAxis: UITextField!
    @IBOutlet weak var lblYAxis: UITextField!
    @IBOutlet weak var mainScroll: UIScrollView!
    
    var arrXLablels = [String]()
    var arrDatasets = [[String:Any]]()
    var fieldItem:FPFieldDetails?
    var cancelBarButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    var isLabelsChanged = false
    private var errDict :[IndexPath:UIAlertController?] = [:]

    weak var delegate:ConfigureChartDelegate?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBarButtons()
        tblLabels.dataSource = self
        tblLabels.register(UITableViewCell.self, forCellReuseIdentifier: "ChartLabelRowView")
    }
    
    
    
    //MARK: Nav
    func setBarButtons(){
        self.lblChartTitle.inputAccessoryView = self.accessoryToolbar
        self.lblXAxis.inputAccessoryView = self.accessoryToolbar
        self.lblYAxis.inputAccessoryView = self.accessoryToolbar
        
        self.cancelBarButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(ConfigureChartViewController.cancelBtnAction))
        
        self.doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(ConfigureChartViewController.doneBtnAction))
        self.navigationItem.leftBarButtonItem = self.cancelBarButton
        self.navigationItem.rightBarButtonItem = self.doneButton
        if let dictValue = fieldItem?.value?.getDictonary() as? [String:Any]{
            lblYAxis.text =  dictValue["yAxisLabel"] as? String  ?? ""
            lblXAxis.text =  dictValue["xAxisLabel"] as? String  ?? ""
            lblChartTitle.text =  dictValue["chartTitle"] as? String  ?? ""
            if let lablels = dictValue["labels"] as? [String]{
                self.arrXLablels  = []
                self.arrXLablels.append(contentsOf: lablels)
            }
            if let datasets = dictValue["datasets"] as? [[String:Any]]{
                self.arrDatasets = []
                self.arrDatasets.append(contentsOf: datasets)
            }
            self.tblLabels.reloadData()
        }
    }
    
    @objc func cancelBtnAction(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnAction(){
        self.view.endEditing(true)
        
        if !isValidData(){
            return
        }
        
        if self.arrXLablels.count < 2  {
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_atleast_need_two_lbl"), completion: nil)
            return
        }
        
        var newDict = [String:Any]()
        if let dictValue = fieldItem?.value?.getDictonary() as? [String:Any]{
            for (key, value) in dictValue {
                newDict[key] = value
            }
        }
        if let YAxis = lblYAxis.text, !YAxis.trim.isEmpty{
            newDict["yAxisLabel"] = YAxis
        }
        if let XAxis = lblXAxis.text, !XAxis.trim.isEmpty{
            newDict["xAxisLabel"] = XAxis
        }
        if let chartTitle = lblChartTitle.text, !chartTitle.trim.isEmpty{
            newDict["chartTitle"] = chartTitle
        }
        
        newDict["labels"] = arrXLablels
        newDict["datasets"] = arrDatasets
        self.delegate?.refreshChart(dictValue: newDict)
        self.dismiss(animated: true) {}
    }
    
    @IBAction func addLableClicked(_ sender: UIButton) {
        self.view.endEditing(true)
        if !isValidData(){
            return
        }
        isLabelsChanged = true
        arrXLablels.append("")
        arrDatasets.indices.forEach { dIndex in
            if  let dataset  = arrDatasets[safe:dIndex],  let value = dataset["data"] as? [String]{
                var arrEmptyData = value
                arrXLablels.indices.forEach { xIndex in
                    if let _ = arrEmptyData[safe:xIndex]{
                        arrEmptyData[xIndex] = arrEmptyData[xIndex]
                    }else{
                        arrEmptyData.append("0.0")
                    }
                }
                arrDatasets[dIndex]["data"] = arrEmptyData
            }
        }
        delegate?.addColumn()
        tblLabels.reloadData()
    }
    
    func isValidData() -> Bool{
        
        var errorDictData: [(key: IndexPath, value: UIAlertController?)] = []
        for (key, value) in errDict {
            if let value = value {
                errorDictData.append((key, value))
            }
        }
             
        var isValid = false
        
        if errorDictData.isEmpty{
            isValid = true
        }else if let errAlrt = errorDictData.first?.value{
            if FPUtility.topViewController()?.isKind(of: UIAlertController.self) == false{
                FPUtility.topViewController()?.present(errAlrt, animated: true)
            }
            isValid = false
        }else{
            isValid = true
        }
        
        if arrXLablels.filter({$0.trim.isEmpty}).count > 0{
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_lbl_noblank_name"), completion: nil)
            isValid = false
        }
        
        return isValid
    }

}


extension ConfigureChartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  arrXLablels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartLabelRowView")
        cell?.backgroundColor = .clear
        cell?.selectionStyle = .none
        cell?.contentConfiguration = UIHostingConfiguration {
            ChartLabelRowView(strLbl: self.arrXLablels[safe:indexPath.row] ?? "", removeAlpha: self.arrXLablels.count > 2 ? 1.0 : 0.5) {
                self.onLblRemoveTapedAt(indexPath)
            } onLblChanged: { newlbl in
                self.arrXLablels[indexPath.row] = newlbl
            } onKeyboardHiddenShown: {  newlbl  in
                self.onLblEditedAt(indexPath, lblValue: newlbl)
            }
        }
        .margins(.all, 0)
        return cell ?? UITableViewCell()
    }
    
    func onLblRemoveTapedAt(_ indxPath: IndexPath) {
        if self.arrXLablels.count <= 2  {
            _  = FPUtility.showAlertController(title:FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_atleast_need_two_lbl"), completion: nil)
            return
        }
        
        if let _ = self.arrXLablels[safe:indxPath.row]{
            DispatchQueue.main.async{
                _ = FPUtility.showAlertController(title:FPLocalizationHelper.localize("alert_dialog_title"), andMessage: "\(FPLocalizationHelper.localize("msg_chart_delete_lbl_confrm"))" + "\(self.arrXLablels[safe:indxPath.row] ?? "")?", completion: nil, withPositiveAction: FPLocalizationHelper.localize("Yes"), style: .destructive, andHandler: { (action) in
                    self.isLabelsChanged = true
                    self.errDict[indxPath] = nil
                    self.arrXLablels.remove(at: indxPath.row)
                    self.arrDatasets.indices.forEach { dataIndx in
                        var data = self.arrDatasets[dataIndx]["data"] as? [String]
                        data?.remove(at: indxPath.row)
                        self.arrDatasets[dataIndx]["data"] = data
                    }
                    self.tblLabels.reloadData()
                    self.delegate?.removeColumn()
                }, withNegativeAction: FPLocalizationHelper.localize("Cancel"), style: .default, andHandler: nil)
            }
            self.tblLabels.reloadData()
        }
    }
    
    func onLblEditedAt(_ indexPth: IndexPath, lblValue:String?) {
        if let value = arrXLablels[safe:indexPth.row], let label  = lblValue{
            if label.trim.isEmpty{
                let errAlrt = FPUtility.errorAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_lbl_noblank_name"))
                errDict[indexPth] = errAlrt
                
                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_lbl_noblank_name"), completion: nil)

                return
            }
            else if !label.trim.isEmpty, arrXLablels.filter({$0.lowercased() == label.lowercased()}).count > 1{
                let errAlrt = FPUtility.errorAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_valid_lbl_name"))
                
                errDict[indexPth] = errAlrt

                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_valid_lbl_name"), completion: nil)

                return
            }
            else if !label.trim.isEmpty, Double(label) == nil{
                let errAlrt = FPUtility.errorAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_valid_lbl_name"))
                
                errDict[indexPth] = errAlrt
                
                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localize("msg_chart_valid_lbl_name"), completion: nil)
                
                return
            }
            else if let existValue = arrXLablels[safe:indexPth.row - 1], let existDblValue = Double(existValue), let curntlValue = Double(label), curntlValue <= existDblValue{
                let errAlrt = FPUtility.errorAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localizeWith(args: [existValue], key: "msg_chart_valid_lbl_value"))
                
                errDict[indexPth] = errAlrt

                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localizeWith(args: [existValue], key: "msg_chart_valid_lbl_value"), completion: nil)

                return
            }
            else if let existValue = arrXLablels[safe:indexPth.row + 1], let existDblValue = Double(existValue), let curntlValue = Double(label), curntlValue >= existDblValue{
                let errAlrt = FPUtility.errorAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localizeWith(args: [existValue], key: "msg_chart_valid_prev_lbl_value"))
                
                errDict[indexPth] = errAlrt

                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message:FPLocalizationHelper.localizeWith(args: [existValue], key: "msg_chart_valid_prev_lbl_value"), completion: nil)

                return
            }
            
            isLabelsChanged = value != label
            errDict[indexPth] = nil
        }
        self.arrXLablels[indexPth.row] = lblValue ?? ""
        self.tblLabels.reloadData()
    }
}
