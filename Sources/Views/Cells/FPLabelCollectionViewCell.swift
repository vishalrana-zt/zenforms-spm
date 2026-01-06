//
//  FPLabelCollectionViewCell.swift
//  crm
//
//  Created by Harshit on 21/02/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import UIKit
internal import UIView_Shimmer

class FPLabelCollectionViewCell: UICollectionViewCell,ShimmeringViewProtocol{

    /// Reuse Identifier String
    public class var reuseIdentifier: String {
        return "\(self.self)"
    }

    /// Registers the Nib with the provided CollectionView
    static func registerWithCollectionView(_ collection: UICollectionView) {
        let bundle = ZenFormsBundle.bundle
        let nib = UINib(nibName: self.reuseIdentifier, bundle: bundle)
        collection.register(nib, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    static func getDequeuedCell(for collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        return collection.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
    }
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var viewBack: UIView!
    var shimmeringAnimatedItems: [UIView] {
        [
            viewBack
        ]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
