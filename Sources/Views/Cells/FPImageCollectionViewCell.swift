//
//  FPImageCollectionViewCell.swift
//  ZT-copilot
//
//  Created by Harshit on 03/02/25.
//

import UIKit

class FPImageCollectionViewCell: UICollectionViewCell {

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

    @IBOutlet weak var fpImageView: UIImageView!
    
    var onItemsRemoved: (()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        fpImageView.layer.cornerRadius = 8
    }

    @IBAction func didTapDelete(_ sender: Any) {
        self.onItemsRemoved?()
    }
}
