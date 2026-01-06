//
//  FPListSelectionCell.swift
//  crm
//
//  Created by Soumya on 25/09/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import UIKit

class FPListSelectionCell: MultiuseTableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkIcon: UIButton!
    var selectionModel:FPSelectionModel?
    @IBOutlet weak var lblDescription: UILabel!
    
    var checkboxTapped: ((Int) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setCheckBoxButton()
    }
    
    private func setCheckBoxButton() {
        self.checkIcon.setImage(#imageLiteral(resourceName: "selectUncheck"), for: .normal)
        self.checkIcon.setImage(#imageLiteral(resourceName: "selectCheck"), for: .selected)
    }
    
    func setListSelectionCell(model: FPSelectionModel, index: Int) {
        self.titleLabel.text = model.titleString
        self.checkIcon.isSelected = model.isChecked
        self.checkIcon.tag = index
        self.lblDescription.text = model.description ?? ""
    }
    
    @IBAction func checkIconAction(_ sender: Any) {
        self.checkboxTapped?(self.checkIcon.tag)
    }
    
}


class FPSelectionModel {
    var titleString: String
    var isChecked: Bool
    var description: String?

    init(titleString: String, isChecked: Bool, description: String?) {
        self.titleString = titleString
        self.isChecked = isChecked
        self.description = description ?? ""
    }
}
