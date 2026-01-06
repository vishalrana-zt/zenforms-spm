//
//  SpreadsheetCollectionViewLayoutDelegate.swift
//  crm
//
//  Created by Apple on 07/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit

protocol SpreadsheetCollectionViewLayoutDelegate: UICollectionViewDelegate {
    func width(forColumn column: Int, collectionView: UICollectionView) -> CGFloat
    func height(forRow row: Int, collectionView: UICollectionView) -> CGFloat
    func widthOffset() -> CGFloat // This is to pass width differenc e.g. content cell width = 100 and serial number and action are 60 so offset would be 40+40 =80
    func heightOffset() -> CGFloat
}
