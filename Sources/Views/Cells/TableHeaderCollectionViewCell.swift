//
//  TableHeaderCollectionViewCell.swift
//  crm
//
//  Created by Apple on 07/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit
class TableHeaderCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var viewBtn: UIView!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var imgMore: UIImageView!
    @IBOutlet weak var btnActions: UIButton!
    
    @IBOutlet weak var title: UILabel!
    var text: String? {
        didSet {
            title.text = text
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        title.adjustsFontSizeToFitWidth = true
    }

}
