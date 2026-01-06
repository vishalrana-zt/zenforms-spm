//
//  DynamicDataTypeRadioButtonTableViewCell.swift
//  crm
//
//  Created by Mayur on 01/12/21.
//  Copyright © 2021 SmartServ. All rights reserved.
//

import UIKit

protocol RadioButtonDelegate: AnyObject {
    func didSelectRadioButton(for sectionIndex:Int, fieldIndex: Int, value: String)
}

class DynamicDataTypeRadioButtonTableViewCell: MultiuseTableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var radioButton: UIButton!
    weak var delegate:RadioButtonDelegate?
    var optionsArray:[FPFieldOption]?
    var index = -1
    var sectionIndex = -1
    var uiType: FPDynamicUITypes?
    var checkboxValue: [String:Bool]?
    var objTbl:UITableView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        self.setNeedsLayout()
        radioButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
    
    @objc func buttonTapped(_ radioButton: UIButton) {
        let isSelected = !self.radioButton.isSelected
        self.radioButton.isSelected = isSelected
        let tableView = self.superview as! UITableView
        let tappedCellIndexPath = tableView.indexPath(for: self)!
        if uiType == .CHECKBOX, let optionsArray = optionsArray {
            checkboxValue?[optionsArray[tappedCellIndexPath.row].key ?? ""] = isSelected
            delegate?.didSelectRadioButton(for: self.sectionIndex, fieldIndex: self.index, value: checkboxValue?.getJson() ?? "")
        } else if isSelected {
            deselectOtherRadioButtons()
            let value = optionsArray?[tappedCellIndexPath.row].value ?? ""
            delegate?.didSelectRadioButton(for: self.sectionIndex, fieldIndex: self.index, value: value)
        }
        objTbl?.reloadData()
    }
    
    func getCheckboxTicked(item: FPFieldOption) -> Bool {
        return lblName.text == item.label ? radioButton.isSelected : item.isSelected
    }

    func deselectOtherRadioButtons() {
        let tableView = self.superview as! UITableView
        let tappedCellIndexPath = tableView.indexPath(for: self)!
        let indexPaths = tableView.indexPathsForVisibleRows
        for indexPath in indexPaths! {
            if indexPath.row != tappedCellIndexPath.row && indexPath.section == tappedCellIndexPath.section {
                let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as! DynamicDataTypeRadioButtonTableViewCell
                cell.radioButton.isSelected = false
            }
        }
    }
    
    func setTickImages(uiType: FPDynamicUITypes){
        self.uiType = uiType
        if uiType == .CHECKBOX { radioButton.setImage(UIImage.init(named: "selectCheck"), for: UIControl.State.selected)
            radioButton.setImage(UIImage.init(named: "selectUncheck"), for: UIControl.State.normal)
            radioButton.tintColor = UIColor(named: "BT-Primary")
        } else {
            radioButton.setImage(UIImage.init(named: "radio_on"), for: UIControl.State.selected)
            radioButton.setImage(UIImage.init(named: "radio_off"), for: UIControl.State.normal)
            radioButton.tintColor = UIColor(named: "BT-Primary")
        }
    }
}
