//
//  StickyGridCollectionViewLayout.swift
//  crm
//
//  Created by Apple on 07/08/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//
import UIKit

final class FPSpreadsheetCollectionViewLayout: UICollectionViewLayout {
    weak var delegate: SpreadsheetCollectionViewLayoutDelegate!
    
    private var layoutAttributesCache: [UICollectionViewLayoutAttributes]!
    private var layoutAttributesInRectCache = CGRect.zero
    private var contentSizeCache = CGSize.zero
    private var columnCountCache = 0
    private var rowCountCache = 0
    var isNew = false {
        didSet {
            // Clear cache when isNew is set to true to force recalculation
            if isNew {
                contentSizeCache = CGSize.zero
            }
        }
    }
    
    private var originalContentOffset = CGPoint.zero
    
    override var collectionViewContentSize: CGSize {
        if isNew{
            isNew = false
            contentSizeCache = CGSize.zero
            collectionView!.contentOffset = .zero
        }
        guard contentSizeCache.equalTo(CGSize.zero) else {
            return contentSizeCache
        }
//
        // Query the collection view's offset here. This method is executed exactly once.
        originalContentOffset = collectionView!.contentOffset
        columnCountCache = collectionView!.numberOfItems(inSection: 0)
        rowCountCache = collectionView!.numberOfSections

        var contentSize = CGSize(width: originalContentOffset.x, height: originalContentOffset.y)

        // Calculate the content size by querying the delegate. Perform this function only once.
        for column in 0..<columnCountCache {
            contentSize.width += delegate?.width(
                forColumn: column, collectionView: collectionView!
            ) ?? 0
        }

        for row in 0..<rowCountCache {
            contentSize.height += delegate?.height(
                forRow: row, collectionView: collectionView!
            ) ?? 0
        }

        contentSizeCache = contentSize

        return contentSize
    }
    
//    func addRow(){
//        rowCountCache += 1
//        contentSizeCache.height += delegate.height(
//            forRow: rowCountCache-1, collectionView: collectionView!
//        )
//    }
    
    func addRow(nRow:Int = 1){
        rowCountCache += nRow
        contentSizeCache.height = contentSizeCache.height +
        delegate.height(forRow: rowCountCache-1, collectionView: collectionView!) * CGFloat(nRow)
    }
    
//    func removeRow(){
//        rowCountCache -= 1
//        contentSizeCache.height -= delegate.height(
//            forRow: rowCountCache-1, collectionView: collectionView!
//        )
//    }
    
    func removeRow(nRow:Int = 1){
        rowCountCache -= nRow
        contentSizeCache.height = contentSizeCache.height -
        delegate.height(forRow: rowCountCache-1, collectionView: collectionView!) * CGFloat(nRow)
    }
    
    func addColumn(){
        columnCountCache += 1
        contentSizeCache.width += delegate.width(
            forColumn: columnCountCache-1, collectionView: collectionView!
        )
    }
    
    func removeColumn(){
        columnCountCache -= 1
        contentSizeCache.width -= delegate.width(
            forColumn: columnCountCache-1, collectionView: collectionView!
        )
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let itemSize = CGSize(
            width: delegate.width(
                forColumn: indexPath.row, collectionView: collectionView!
            ),
            height: delegate.height(
                forRow: indexPath.section, collectionView: collectionView!
            )
        )
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        // Calculate the rect of the cell making sure to incorporate the off set of the collection
        // view's content.
        var frame = CGRect(
            x: (itemSize.width * CGFloat(indexPath.row))-delegate.widthOffset() + originalContentOffset.x,
            y: (itemSize.height * CGFloat(indexPath.section))-delegate.heightOffset() + originalContentOffset.y,
            width: itemSize.width,
            height: itemSize.height
        )
        
        // Creates a tuple type out of an index path. This is a prime example of pattern matching.
        // see: https://en.wikipedia.org/wiki/Pattern_matching
        switch (indexPath.section, indexPath.row) {
        // Top-left tem
        case (0, 0):
            attributes.zIndex = 2
            frame.origin.y = collectionView!.contentOffset.y
            frame.origin.x = collectionView!.contentOffset.x
        case (0,1):
            attributes.zIndex = 2
            frame.origin.y = collectionView!.contentOffset.y
            frame.origin.x = collectionView!.contentOffset.x+CGFloat(WIDTH_HEADER)
        // Top row
        case (0, _):
            frame = CGRect(
                x:  (itemSize.width * CGFloat(indexPath.row))-(delegate.widthOffset()+CGFloat(WIDTH_HEADER)) + originalContentOffset.x,
                y: (itemSize.height * CGFloat(indexPath.section))-delegate.heightOffset() + originalContentOffset.y,
                width: itemSize.width,
                height: itemSize.height
            )
            attributes.zIndex = 1
            frame.origin.y = collectionView!.contentOffset.y
        // Left column
        case (_, 0):
            attributes.zIndex = 1
            frame.origin.x = collectionView!.contentOffset.x
        case (_, 1):
            attributes.zIndex = 1
            frame.origin.x = collectionView!.contentOffset.x+CGFloat(WIDTH_HEADER)
            
        default:
            frame = CGRect(
                x:(itemSize.width * CGFloat(indexPath.row))-(delegate.widthOffset()+CGFloat(WIDTH_HEADER)) + originalContentOffset.x,
                y: (itemSize.height * CGFloat(indexPath.section))-delegate.heightOffset() + originalContentOffset.y,
                width: itemSize.width,
                height: itemSize.height)
            attributes.zIndex = 0
        }
        
        // For more information on what `CGRectIntegral` does and why we should use it, go here:
        // http://iosdevelopertip.blogspot.in/2014/10/cgrectintegral.html
        attributes.frame = frame.integral
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !rect.equalTo(layoutAttributesInRectCache) else {
            return layoutAttributesCache
        }
        
        layoutAttributesInRectCache = rect
        
        var attributes = Set<UICollectionViewLayoutAttributes>()
        
        for column in 0..<collectionView!.numberOfItems(inSection: 0) {
            for row in 0..<collectionView!.numberOfSections {
                let attribute = layoutAttributesForItem(at: IndexPath(row: column, section: row))!
                attributes.insert(attribute)
            }
        }
        
        layoutAttributesCache = Array(attributes)
        
        return layoutAttributesCache
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        
        layoutAttributesCache = nil
        layoutAttributesInRectCache = CGRect.zero
    }
}
