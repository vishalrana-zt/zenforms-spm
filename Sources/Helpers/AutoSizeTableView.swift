//
//  AutoSizeTableView.swift
//  MSP
//
//  Created by SOTSYS033 on 02/07/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//
import UIKit
import Foundation
//MARK:- Dynamic height Table View
class AutoSizeTableView: UITableView{
    override public func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        return contentSize
    }
}


