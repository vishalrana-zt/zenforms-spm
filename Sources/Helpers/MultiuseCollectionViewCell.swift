//
//  MultiuseCollectionViewCell.swift
//  crm
//
//  Created by Soumya on 27/12/19.
//  Copyright © 2019 SmartServ. All rights reserved.
//

import UIKit

class MultiuseCollectionViewCell: UICollectionViewCell {

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

}
