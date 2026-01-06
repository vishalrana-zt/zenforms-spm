//
//  SegmentControlCellDataSource.swift
//  crm
//
//  Created by Mayur on 02/03/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import Foundation
import UIKit
protocol SegmentControlCellDelegate: AnyObject {
    func updateData(on selectedSegmentIndex: Int, rowIndex: Int)
}

class SegmentControlCellDataSource: NSObject, UITableViewDataSource {

    weak var delegate: SegmentControlCellDelegate?
    
    var selectedSegmentIndex: Int
    var index: Int
    
    init(selectedSegmentIndex: Int, index: Int) {
        self.selectedSegmentIndex = selectedSegmentIndex
        self.index = index
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: FPConstansts.NibName.SegmentControlTableViewCell, for: indexPath) as? SegmentControlTableViewCell {
            cell.setSegmentControlCell(selectedSegmentIndex: self.selectedSegmentIndex, index: self.index)
            return cell
        }
        return UITableViewCell()
    }
}
