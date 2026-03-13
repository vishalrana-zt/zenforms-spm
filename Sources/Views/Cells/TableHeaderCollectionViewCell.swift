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
    @IBOutlet weak var viewExpand: UIView!
    @IBOutlet weak var btnExpand: UIButton!

    @IBOutlet weak var title: UILabel!
    var text: String? {
        didSet {
            title.text = text
        }
    }

    var currentIndexPath: IndexPath?
    var onExpandTapped: ((IndexPath) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        title.adjustsFontSizeToFitWidth = true
        viewExpand.isHidden = true
        let expandImage = UIImage(systemName: "chevron.up.chevron.down")
        btnExpand.setImage(expandImage, for: .normal)
        btnExpand.tintColor = UIColor(named: "BT-Primary") ?? .systemBlue
        btnExpand.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
    }

    @objc private func expandButtonTapped() {
        guard let ip = currentIndexPath else { return }
        onExpandTapped?(ip)
    }
}
