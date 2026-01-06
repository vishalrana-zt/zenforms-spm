//
//  AutoSizeCollectionView.swift

import UIKit
import Foundation

//MARK:- Dynamic height Collection
class AutoSizeCollectionView: UICollectionView {
   
    override func layoutSubviews() {
      super.layoutSubviews()
      if bounds.size != intrinsicContentSize {
           self.invalidateIntrinsicContentSize()
      }
    }

    override var intrinsicContentSize: CGSize {
      return collectionViewLayout.collectionViewContentSize
    }
    
}
