//
//  CustomReasonTextFieldCellDataSource.swift
//  crm
//
//  Created by Mayur on 02/03/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import Foundation
import UIKit

class CustomReasonTextFieldCellDataSource: NSObject, UITableViewDataSource {

    var text: String
    var index: Int
    
    init(string: String, index: Int) {
        self.text = string
        self.index = index
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: FPConstansts.NibName.CustomReasonTextFieldTableViewCell, for: indexPath) as? CustomReasonTextFieldTableViewCell {
            cell.setCustomReasonCell(reasonText: self.text, index: index)
            return cell
        }
        return UITableViewCell()
    }
}


