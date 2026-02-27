//
//  FPEditRowTableViewCell.swift
//  ZenForms
//
//  Created by apple on 27/02/26.
//


import UIKit
internal import SSMediaManager
internal import IQKeyboardManagerSwift

// MARK: - Cell

protocol FPEditRowCellDelegate: AnyObject {
    func updateData(at index:IndexPath, with data:ColumnData, filedData filed:FPFieldDetails?)
    func showAddAttachment(at index:IndexPath,with data:ColumnData)
}


 class FPEditRowTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var lblColumnName: UILabel!
    @IBOutlet weak var btnAddAttachment: UIButton!
    @IBOutlet weak var tblTextField: UITextField!
    @IBOutlet weak var tblDropdownField: ZTDropDown!
    @IBOutlet weak var tblTextView: UITextView!
    @IBOutlet weak var viewBarcode: UIView!
    @IBOutlet weak var imgBarcode: UIImageView!
    @IBOutlet weak var btnBarcode: UIButton!

    // MARK: - Properties

    var childTableIndex: IndexPath?
    var parentTableIndex: IndexPath?
    
    weak var delegate: FPEditRowCellDelegate?
     
     var defaultDeficeincyOptions:[DropdownOptions]{
         let yesOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")))
         let noOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")))
         let naOption = DropdownOptions(key:FPStringBoolIntValue.string("NA") , value: FPStringBoolIntValue.string("NA"), label: FPStringBoolIntValue.string("NA"))
         return [yesOption, noOption, naOption]
     }

    var data: ColumnData? {
        didSet {
            guard let data else { return }
            setupView(column: data)
        }
    }
     
    var strFPDateFormat: String {
         var strFormat = ""
         var dateFormatType: FPFORM_DATE_FORMAT = .DATE
         
         if let columnData  = data{
             if columnData.dataType == "TIME"{
                 dateFormatType = .TIME
             }else if columnData.dataType == "DATE_TIME"{
                 dateFormatType = .DATE_TIME
             }else if columnData.dataType == "YEAR"{
                 dateFormatType = .YEAR
             }else{
                 dateFormatType = .DATE
             }
         }
         if dateFormatType == .DATE_TIME, let dateFormat = data?.dateFormat{
             strFormat = dateFormat
         }else{
             strFormat = dateFormatType.rawValue
         }
         strFormat = dateFormatType.rawValue
         return strFormat
     }

    private var pickerArray: [DropdownOptions] = []
    private var generateDynamically = false
    private var isUITypeDeficiency = false

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        tblTextField.delegate = self
        tblTextView.delegate = self

        tblTextField.iq.toolbar.doneBarButton
            .setTarget(self, action: #selector(doneTapped))

        tblTextView.iq.toolbar.doneBarButton
            .setTarget(self, action: #selector(doneTapped))

        imgBarcode.setImageColor(
            color: UIColor(named: "BT-Primary") ?? .black
        )
        
        tblTextView.layer.cornerRadius = 8
        tblTextView.layer.borderWidth = 1
        tblTextView.layer.borderColor = UIColor.systemGray4.cgColor
        tblTextView.layer.masksToBounds = true
        tblTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        tblTextField.text = nil
        tblTextView.text = nil
        tblDropdownField.text = nil

        btnAddAttachment.isHidden = true
        tblTextField.isHidden = true
        tblTextView.isHidden = true
        tblDropdownField.isHidden = true
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        endEditing(true)
    }

    @IBAction func didTapAddAttachments(_ sender: Any) {
        guard let childTableIndex, let data else { return }
        delegate?.showAddAttachment(at: childTableIndex, with: data)
    }
}

// MARK: - Configuration

private extension FPEditRowTableViewCell {
    func setupView(column:ColumnData){
        self.tblTextView.isUserInteractionEnabled = !(column.readonly ?? false)
        self.tblTextField.isUserInteractionEnabled = !(column.readonly ?? false)
        self.tblDropdownField.isUserInteractionEnabled = !(column.readonly ?? false)
        self.lblColumnName.text = column.key.handleAndDisplayApostrophe() ?? ""

        self.tblDropdownField.isHidden = true
        if column.uiType == "DEFICIENCY" || column.uiType == "DROPDOWN"{
            self.generateDynamically = column.generateDynamically ?? false
            self.isUITypeDeficiency = column.uiType == "DEFICIENCY"
            self.btnAddAttachment.isHidden = true
            self.tblTextView.isHidden = true
            self.tblTextField.isHidden = true
            self.tblDropdownField.isHidden = false
            let displayValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: column.value, isForLocal: false) ?? column.value
            self.tblDropdownField.text = displayValue
            self.tblDropdownField.checkMarkEnabled = false
            self.tblDropdownField.isSearchEnable = (column.uiType == "DROPDOWN")
            self.tblDropdownField.itemsColor = .black
            self.tblDropdownField.rowHeight = 40
            self.tblDropdownField.selectedRowColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9647058824, alpha: 1)
            self.tblDropdownField.arrowSize = 15
            self.setTextFieldByType(column)
        }else if(column.uiType == "ATTACHMENT"){
            self.btnAddAttachment.isHidden = false
            self.tblTextView.isHidden = true
            self.tblTextField.isHidden = true
            let dataObject = column.value.getDictonary()
            if(!dataObject.isEmpty){
                if let files =  dataObject["files"] as? [[String:Any]],!files.isEmpty{
                    self.btnAddAttachment.setTitle(FPLocalizationHelper.localize("lbl_View"), for: .normal)
                }else{
                    if let files =  dataObject["filesToUpload"] as? [[String:Any]],!files.isEmpty{
                        var mediasAdded:[SSMedia] = []
                        files.forEach { file in
                            if((FPFormDataHolder.shared.tableMediaCache.first(where: {$0.mediaAdded.contains(where: {$0.name == file["altText"] as? String ?? "" })})) == nil){
                                
                                let mediaAdded = SSMedia(name:file["altText"] as? String ?? "",mimeType:file["type"] as? String ?? "",filePath: file["localPath"] as? String ?? "", moduleType: .forms)
                                mediasAdded.append(mediaAdded)
                            }
                        }
                        if mediasAdded.count>0{
                            if let mediaIndex = FPFormDataHolder.shared.tableMediaCache.firstIndex(where: {$0.parentTableIndex == parentTableIndex && $0.childTableIndex == childTableIndex}){
                                var tableMedia = FPFormDataHolder.shared.tableMediaCache[mediaIndex]
                                tableMedia.mediaAdded = mediasAdded
                                FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                                
                            }else{
                                let tableMedia = TableMedia(columnIndex:childTableIndex!.row-2,key:column.key,parentTableIndex: parentTableIndex,childTableIndex: childTableIndex, mediaAdded: mediasAdded, mediaDeleted: [])
                                FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                            }
                        }
                        
                        self.btnAddAttachment.setTitle(FPLocalizationHelper.localize("lbl_View"), for: .normal)
                    }else{
                        self.btnAddAttachment.setTitle(FPLocalizationHelper.localize("lbl_Add"), for: .normal)
                    }
                }
            }else{
                self.btnAddAttachment.setTitle(FPLocalizationHelper.localize("lbl_Add"), for: .normal)
            }
            
        }else{
            self.btnAddAttachment.isHidden = true
            self.tblTextView.isHidden = true
            self.tblTextField.isHidden = true
            self.tblDropdownField.isHidden = true
            self.tblTextField.delegate = self
            self.tblTextView.delegate = self
            self.tblTextField.clearDropdownView()
            if column.dataType == "DATE" || column.dataType == "TIME" || column.dataType == "DATE_TIME" || column.dataType == "YEAR"{
                self.tblTextField.isHidden = false
                self.tblTextField.text = ""
                if !column.value.trim.isEmpty{
                    if let date = FPUtility.getOPDateFrom(column.value) {
                        self.tblTextField.text = self.formateDateAccordingToMode(date: date)
                    }else if let fixedDate = fixDateFormat(column.value) {
                        self.tblTextField.text = self.formateDateAccordingToMode(date: fixedDate)
                    }else{}
                }
            }else{
                self.tblTextView.isHidden = false
                let displayValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: column.value, isForLocal: false) ?? column.value
                self.tblTextView.text = displayValue
            }
        }
        self.tblTextView.tag = childTableIndex!.row-2
        self.tblTextField.tag = childTableIndex!.row-2
        self.btnAddAttachment.tag = childTableIndex!.row-2
    }
    func setTextFieldByType(_ rowData: ColumnData) {
        //        self.tblTextView.disablePaste()
        self.tblTextView.tintColor = UIColor.blue
        
        switch rowData.uiType {
        case "DROPDOWN","DEFICIENCY":
            self.tblTextField.isHidden = true
            self.tblDropdownField.isHidden = false
            self.pickerArray = []
            let selOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")))
            self.pickerArray.append(selOption)
            if rowData.uiType == "DEFICIENCY", rowData.dropDownOptions == nil{
                self.pickerArray.append(contentsOf: defaultDeficeincyOptions)
            }else{
                self.pickerArray.append(contentsOf: rowData.dropDownOptions ?? [])
            }
            let arrStrOptions = self.pickerArray.compactMap({ self.generateDynamically || self.isUITypeDeficiency ? $0.label.stringValue().handleAndDisplayApostrophe() : $0.key.stringValue().handleAndDisplayApostrophe()})
            self.tblDropdownField.optionArray = arrStrOptions
            
            if self.isUITypeDeficiency, rowData.dropDownOptions != nil{
                let compareValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: rowData.value, isForLocal: false) ?? rowData.value
                if let index = self.pickerArray.firstIndex(where: { $0.value.stringValue().handleAndDisplayApostrophe().lowercased() == compareValue.lowercased() }){
                    self.tblDropdownField.selectedIndex = index
                    self.tblDropdownField.text = self.pickerArray[index].label.stringValue().handleAndDisplayApostrophe()
                }
            }else{
                if !rowData.value.isEmpty{
                    let compareValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: rowData.value, isForLocal: false) ?? rowData.value
                    if let index = arrStrOptions.firstIndex(where: { $0.lowercased() == compareValue.lowercased() }){
                        self.tblDropdownField.selectedIndex = index
                    }
                }
            }
            self.tblDropdownField.didSelect{(selectedText , index ,id) in
                self.pickedValue(index: index)
            }
            self.tblDropdownField.didEndSelect{(selectedText) in
                DispatchQueue.main.async {
                    self.tblDropdownField.hideList()
                }
                if var columnData = self.data{
                    let dbValue = selectedText.handleAndDisplayApostrophe()
                    columnData.value = dbValue
                    self.delegate?.updateData(at: self.childTableIndex!, with: columnData, filedData: nil)
                }
            }
        default:
            self.setTextFieldByInputType(rowData)
        }
    }
    
    func setTextFieldByInputType(_ rowData: ColumnData) {
        self.tblTextView.isHidden = true
        self.tblTextField.isHidden = true
        switch rowData.dataType {
        case "NUMBER":
            self.tblTextView.isHidden = false
            self.tblTextView.keyboardType = .numbersAndPunctuation
            self.tblTextView.inputView = nil
            self.tblTextView.disablePaste()
            self.tblTextView.disableCut()
        case "TEXT":
            self.tblTextView.isHidden = false
            self.tblTextView.keyboardType = .default
            self.tblTextView.inputView = nil
            self.tblTextView.allowCut()
            self.tblTextView.allowPaste()
        case "DATE", "TIME", "DATE_TIME":
            self.tblTextField.isHidden = false
            self.tblTextField.disablePaste()
            self.tblTextField.disableCut()
            self.tblTextField.clearDropdownView()
            self.tblTextField.tintColor = UIColor.blue
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            if rowData.dataType == "TIME"{
                datePicker.datePickerMode = .time
            }else if rowData.dataType == "DATE_TIME"{
                datePicker.datePickerMode = .dateAndTime
            }else{}
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
            if !rowData.value.trim.isEmpty, let date = FPUtility.getOPDateFrom(rowData.value) {
                self.tblTextField.text = self.formateDateAccordingToMode(date: date)
            }else if let fixedDate = fixDateFormat(rowData.value) {
                self.tblTextField.text = self.formateDateAccordingToMode(date: fixedDate)
            }else{}
            
            if !rowData.value.trim.isEmpty, let date = FPUtility.getOPDateFrom(rowData.value) {
                datePicker.setDate(date, animated: false)
            }else if let fixedDate = fixDateFormat(rowData.value) {
                datePicker.setDate(fixedDate, animated: false)
            } else {
                datePicker.sendActions(for: .valueChanged)
            }
            datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
            self.tblTextField.inputView = datePicker
        case "YEAR":
            self.tblTextField.isHidden = false
            self.tblTextField.disablePaste()
            self.tblTextField.disableCut()
            self.tblTextField.clearDropdownView()
            self.tblTextField.tintColor = UIColor.blue
            let datePicker = FPMonthYearDatePicker()
            datePicker.mode = .year
            if !rowData.value.trim.isEmpty, let date = FPUtility.getOPDateFrom(rowData.value) {
                self.tblTextField.text = self.formateDateAccordingToMode(date: date)
            }else if let fixedDate = fixDateFormat(rowData.value) {
                self.tblTextField.text = self.formateDateAccordingToMode(date: fixedDate)
            }else{}
            
            if !rowData.value.trim.isEmpty, let date = FPUtility.getOPDateFrom(rowData.value) {
                datePicker.setDate(date, animated: false)
            }else if let fixedDate = fixDateFormat(rowData.value) {
                datePicker.setDate(fixedDate, animated: false)
            } else {
            }
            datePicker.addTarget(self, action: #selector(yearPickerValueChanged), for: .valueChanged)
            self.tblTextField.inputView = datePicker
        default :
            self.tblTextView.isHidden = false
        }
    }
    
    @objc func datePickerValueChanged(sender: UIDatePicker) {
        self.tblTextField.text = self.formateDateAccordingToMode(date: sender.date)
        self.data?.value =  FPUtility.getStringWithTZFormat(sender.date)
    }
    
    @objc func yearPickerValueChanged(sender: FPMonthYearDatePicker) {
        self.tblTextField.text = self.formateDateAccordingToMode(date: sender.date)
        self.data?.value =  FPUtility.getStringWithTZFormat(sender.date)
    }
    
    func formateDateAccordingToMode(date:Date) -> String {
        return date.convertUTCToLocalInString(with: strFPDateFormat)
    }
    
    func fixDateFormat(_ dateString: String, format:String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> Date? {
        let fixedDateString = dateString.replacingOccurrences(of: "__X2E__", with: ".")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if let fixedDate = dateFormatter.date(from: fixedDateString) {
            return fixedDate
        } else {
            return nil
        }
    }
    
    func saveText(text:String){
        if var columnData = data{
            var tblValue = text
            if !text.trim.isEmpty, data?.dataType == "DATE" || data?.dataType == "TIME" || data?.dataType == "DATE_TIME" || data?.dataType == "YEAR"{
                tblValue = columnData.value
            }
            let dbValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: tblValue, isForLocal: true) ?? text
            columnData.value = dbValue
            delegate?.updateData(at: childTableIndex!, with: columnData, filedData: nil)
        }
    }
    
    func pickedValue(index: Int) {
        let value = self.generateDynamically ? 
                    pickerArray[safe:index]?.label.stringValue().handleAndDisplayApostrophe() ?? "" : pickerArray[safe:index]?.value.stringValue().handleAndDisplayApostrophe() ?? ""
        
        let displayvalue = pickerArray[safe:index]?.label.stringValue().handleAndDisplayApostrophe() ?? ""
        
        if value ==  FPLocalizationHelper.localize("SELECT") {
            self.tblTextField.text = ""
            self.tblDropdownField.text = ""
            self.saveText(text: "")
            return
        }
        if(self.childTableIndex!.row != 1 ){
            self.tblTextField.text = value
            self.tblDropdownField.text = value
            if isUITypeDeficiency{
                self.tblDropdownField.text = displayvalue
            }
            self.saveText(text: value)
        }
    }
    
}


extension FPEditRowTableViewCell: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.setTextFieldByType(self.data!)
        if self.data?.dataType == "DATE" || self.data?.dataType == "TIME" || self.data?.dataType == "DATE_TIME" || self.data?.dataType == "YEAR"{
            if let value = textField.text, value.trim.isEmpty{
                self.data?.value =  FPUtility.getStringWithTZFormat(Date())
            }
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.trim.isEmpty ?? false, self.data?.dataType == "DATE" || self.data?.dataType == "TIME" || self.data?.dataType == "DATE_TIME" || self.data?.dataType == "YEAR"{
            self.data?.value = ""
        }
        self.saveText(text: textField.text  ?? "")
    }
}

extension FPEditRowTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.saveText(text: textView.text ?? "")
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.setTextFieldByType(self.data!)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\t" {
            if let indexPath = childTableIndex,
               let collectionView = self.superview as? UICollectionView {
                let nextIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
                if let nextCell = collectionView.cellForItem(at: nextIndexPath) as? TableContentCollectionViewCell {
                    nextCell.tblTextView.becomeFirstResponder()
                    return false
                }
            }
        }
        return true
    }

}
