//
//  TableSummaryRowView.swift
//  crm
//
//  Created by Apple on 10/01/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit

class TableSummaryRowView: UIView {
    @IBOutlet weak var matrixStackView: UIStackView!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableName: UILabel!

    
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
        bundle.loadNibNamed("TableSummaryRowView", owner: self, options:nil)
        addSubview(contentView)
        self.contentView.frame = self.bounds
        self.contentView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        self.contentView.layer.borderColor = UIColor.lightGray.cgColor
        self.contentView.layer.borderWidth = 1
    }

    func setupViewWith(data:[String:Any]){
        matrixStackView.removeAllArrangedSubviews()
        if let name = data["table_name"] as? String{
            tableName.text = name
        }
        if(data.keys.count>3 ||  UIDevice.current.userInterfaceIdiom == .phone ){
            matrixStackView.axis = .vertical
            matrixStackView.distribution = .fillEqually
        }else{
            matrixStackView.axis = .horizontal
            matrixStackView.distribution = .fillEqually
        }
        data.keys.sorted().forEach { key in
            if(key !=  "table_name"){
                let lable = UILabel()
                lable.text = "\(key) : \((data[key] as? String ?? ""))"
                matrixStackView.addArrangedSubview(lable)
            }
        }

    }
    
}

extension UIStackView {

    func removeAllArrangedSubviews() {
        let removedSubviews = arrangedSubviews.reduce([]) { (sum, next) -> [UIView] in
            self.removeArrangedSubview(next)
            return sum + [next]
        }
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
    
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
