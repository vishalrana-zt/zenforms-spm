//
//  MultiuseTableViewCell.swift
//  crm
//
//  Created by Soumya on 20/12/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import UIKit

class MultiuseTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        self.preservesSuperviewLayoutMargins = false
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
    }

    /// Reuse Identifier String
    public class var reuseIdentifier: String {
        return "\(self.self)"
    }

    /// Registers the Nib with the provided table
    static func registerWithTable(_ table: UITableView) {
        let bundle = ZenFormsBundle.bundle
        let nib = UINib(nibName: self.reuseIdentifier, bundle: bundle)
        table.register(nib, forCellReuseIdentifier: self.reuseIdentifier)
        table.alwaysBounceVertical = false
    }

    static func getDequeuedCell(for table: UITableView, indexPath: IndexPath) -> UITableViewCell? {
        return table.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
    }

}
