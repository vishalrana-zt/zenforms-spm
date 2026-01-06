//
//  TableTitleView.swift
//  crm
//
//  Created by Apple on 05/01/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit

class TableTitleView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLable: UILabel!
    
    @IBOutlet weak var labelWidth: NSLayoutConstraint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    
    private func commonInit(){
        let bundle = ZenFormsBundle.bundle
        bundle.loadNibNamed("TableTitleView", owner: self, options:nil)
        addSubview(contentView)
        self.contentView.frame = self.bounds
        self.contentView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
    }
}
