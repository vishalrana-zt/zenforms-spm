//
//  FPDropDownTableViewCell.swift
//  crm
//
//

import UIKit
internal import IQKeyboardManagerSwift

class FPDropDownTableViewCell: UITableViewCell {

    @IBOutlet weak var valueDropdownField: ZTDropDown!
    @IBOutlet weak var title: UILabel!
    
    var cellItem = FPFieldDetails()
    var arrayToShow:[FPFieldOption]?
    var index = -1
    var sectionIndex = -1
    var isNew: Bool = true
    var selectedPickerIndex = -1
    
    var isSectionDuplicationField: Bool {
        return cellItem.isSectionDuplicationField
    }
    
    weak var delegate:FPDynamicDataTypeCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    
    func configureCell(item: FPFieldDetails, sectionIndex: Int, tag: Int) {
        self.title.adjustsFontSizeToFitWidth = true
        let displayName = item.displayName?.handleAndDisplayApostrophe() ?? ""
        self.cellItem = item
        self.selectedPickerIndex = -1
        self.valueDropdownField.text = ""
        self.valueDropdownField.placeholder = item.getUIType() == .AUTO_POPULATE ? item.value :displayName        
        if item.mandatory{
            let fontAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold), .foregroundColor: UIColor.black]
            let baseString =  NSAttributedString(string: " \(displayName)", attributes: fontAttributes)
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.red]
            let starString =  NSAttributedString(string: "*", attributes: attributes)
            let mutableString = NSMutableAttributedString(attributedString: starString)
            mutableString.append(baseString)
            self.title.attributedText = mutableString
        }else{
            self.title.text =  displayName
            self.title.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            self.title.textColor = .black
        }
        self.setItemValue(item.value)
        self.index = tag
        self.sectionIndex = sectionIndex
        self.valueDropdownField.isEnabled = !item.readOnly
        self.arrayToShow = self.cellItem.getDropdownOptions()
        self.setDropDownField()
    }

    private func setItemValue(_ value: String?) {
        if let value = value, !value.trim.isEmpty{
            self.valueDropdownField.text = FPUtility().fetchCompataibleSpecialCharsStringFromDB(strInput: value)
        }
    }
    

    private func setDropDownField() {
        if self.selectedPickerIndex > -1 {
            if let label = self.arrayToShow?[safe: self.selectedPickerIndex]?.label{
                self.valueDropdownField.text = label == "Select" ? "" : label
            }
        }else{
            if let value = self.valueDropdownField.text, !value.isEmpty{
                if let selectd = self.arrayToShow?.firstIndex(where: { $0.label?.lowercased() == value.lowercased() }){
                    self.selectedPickerIndex = selectd
                }
            }
        }
        self.valueDropdownField.selectedIndex =  self.selectedPickerIndex > -1 ? self.selectedPickerIndex : 0
        self.valueDropdownField.optionArray = self.arrayToShow?.map({$0.label ?? ""}) ?? []
        self.valueDropdownField.checkMarkEnabled = false
        self.valueDropdownField.isSearchEnable = !self.isSectionDuplicationField
        self.valueDropdownField.itemsColor = .black
        self.valueDropdownField.rowHeight = 40
        self.valueDropdownField.selectedRowColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9647058824, alpha: 1)
        self.valueDropdownField.arrowSize = 16
        self.valueDropdownField.corner_Radius = 4
        self.valueDropdownField.layer.borderColor = UIColor.systemGray4.cgColor
        self.valueDropdownField.layer.borderWidth = 1
        self.valueDropdownField.didSelect{(selectedText , index ,id) in
            self.valueDropdownField.hideList()
            self.pickedValue(index: index)
        }
        self.valueDropdownField.didEndSelect{(selectedText) in
            DispatchQueue.main.async {
                self.valueDropdownField.hideList()
            }
            self.delegate?.selectedValue(for: self.sectionIndex, fieldIndex: self.index, pickerIndex: nil, value: selectedText.handleAndDisplayApostrophe(), date: nil, isSectionDuplicationField: self.isSectionDuplicationField)
        }
    }
    
    func pickedValue(index: Int) {
        guard let array = self.arrayToShow, array.count > 0 else {
            return
        }
        selectedPickerIndex = index
        var value = array[index].value ?? ""
        if value ==  FPLocalizationHelper.localize("SELECT") {
            value = ""
        }
        self.valueDropdownField.text = value
        self.delegate?.selectedValue(for: self.sectionIndex, fieldIndex: self.index, pickerIndex: index, value: value, date: nil, isSectionDuplicationField: self.isSectionDuplicationField)
    }
}
