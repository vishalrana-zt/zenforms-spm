//
//  FPSelfSizedTableView.swift
//  ZenFormsLib
//
//  Created by apple on 20/05/24.
//

import Foundation
import UIKit

class FPSelfSizedTableView: UITableView {
    
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height
    
    override var contentSize:CGSize {
        didSet {
            resetSize()
        }
    }
    
    func resetSize(){
        invalidateIntrinsicContentSize()
        sizeToFit()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return contentSize
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
